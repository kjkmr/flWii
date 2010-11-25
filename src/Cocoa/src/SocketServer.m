//
//  SocketServer.m
//  flWii
//
//  Created by Kimura Koji on 10/11/07.
//  Copyright 2010 STARRYWORKS inc. All rights reserved.
//

#import "SocketServer.h"

NSFileHandle *__fileHandle;
int __connection;
int __socket;
bool __connected;
bool __connecting;


@implementation SocketServer

/**
 * init
 */

-(id)init{
	self= [super init];
	__connected = false;
	__connecting = false;
	return [self initWithPort:8000];
}

- (id)initWithPort:(int)i_port {
	port = i_port;
	return self;
}

/**
 * dealloc
 */
- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"SockAccepted"];
	[self close];
	[super dealloc];
}

/**
 * データ送信
 */
- (IBAction)sendMessage:(NSData*)message {
	if ( !__connected ) return;
	@try {
		[__fileHandle writeData: message];
	}
	@catch (NSException* exception) {
		[self close];
		[self start];
	}
}

/**
 * データを受信した時のイベント
 *
 * (NSNotification*)	notification	:通知オブジェクト
 */
- (void)__receivedMessage: (NSNotification*)notification {
	if ( !__connected ) return;
  	// check error
  	NSNumber *pUNIXError = [ NSNumber numberWithInt:0 ];
  	pUNIXError = [[notification userInfo] objectForKey:@"NSFileHandleError"];
  	
  	if( ![ pUNIXError intValue ] ){
  		NSData *data = [__fileHandle availableData];
  		//NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
		if ( [data length] < 1 ) {
			[self close];
			[self start];
			return;
		}
		NSNotification* n = [NSNotification notificationWithName: @"SockReceivedMessage"
														  object: self
														userInfo:[NSDictionary dictionaryWithObject:data forKey:@"data"]];
		[[NSNotificationCenter defaultCenter] postNotification:n];
		[__fileHandle waitForDataInBackgroundAndNotify];
		
  	} else {
		[self close];
		[self start];
	}
}

/**
 * ソケット接続開始（threadで実行される）
 */

- (void) __start {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int result=0;
	struct sockaddr_in addr;
	
	//sockaddr_in 構造体に値をセット
	memset( &addr, 0, sizeof( addr ) );
	addr.sin_family = AF_INET;
	addr.sin_addr.s_addr = htonl(INADDR_ANY);
	addr.sin_port = htons(port);
	
	//ソケット作成
	__socket = socket(AF_INET, SOCK_STREAM, 0);
	
	char on = 1;
	setsockopt( __socket, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on) );
	//バインド
	result = bind(__socket, (struct sockaddr *)&addr, sizeof(addr));
	if ( result < 0) {
		[NSException raise: @"SockBindingException" format: @"Can't bind socket: %s", strerror(errno)];
		exit(0);
	}
	
	//受信待機
	result = listen(__socket, 1);
	if ( result < 0) {
		[NSException raise: @"SockListeningException" format: @"Can't listen socket: %s", strerror(errno)];
		exit(0);
	}
	
	//接続を確率
	int connection = accept(__socket, (struct sockaddr *)NULL, NULL);
	if ( connection < 0) {
		[NSException raise: @"SockAcceptException" format: @"Can't accept socket: %s", strerror(errno)];
		exit(0);
	}
	
	//通知
	__connection = connection;
	__connecting = false;
	
	//おわり
	[pool release];
}

/**
 * 接続の監視
 */
- (void) __checkConnection {
	if ( __connecting ) {
		[self performSelector:@selector(__checkConnection) withObject:nil afterDelay:0.2];
		return;
	}
	
	__fileHandle = [[NSFileHandle alloc] initWithFileDescriptor: __connection];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(__receivedMessage:)
												 name: NSFileHandleDataAvailableNotification
											   object: __fileHandle];
	[__fileHandle waitForDataInBackgroundAndNotify];
	__connected = true;
	
}


/**
 * ソケット接続開始
 */
- (void)start {
	if ( __connecting ) return;
	if ( __connected ) [self close];
	__connecting = true;
	
	//監視タイマー（カレントスレッドで__fileHandleにaddObserverしないとデータの受信ができないため）
	//（もっといいやり方があると思うけど、わからん）
	[self performSelector:@selector(__checkConnection) withObject:nil afterDelay:0.2];
	
	//スレッド
	[NSThread detachNewThreadSelector:@selector(__start) toTarget:self withObject:self];
}

/**
 * ソケットを閉じる
 */
- (void)close {
	if ( !__connected ) return;
	__connected = false;
	close(__connection);
	close(__socket);
	[__fileHandle closeFile];
	[__fileHandle release];
}

@end
