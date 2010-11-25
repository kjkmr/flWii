//
//  AppController.m
//  flWii
//
//  Created by Kimura Koji on 10/11/04.
//  Copyright 2010 STARRYWORKS inc. All rights reserved.
//

#import "AppController.h"

WiiRemoteController* __wiis[4];

@implementation AppController

/**
 * init
 */

-(id)init{
	self= [super init];
	return self;
}

/**
 * dealloc
 */

- (void) dealloc{
	//	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[wii01 release];
	[wii02 release];
	[wii03 release];
	[wii04 release];
	[super dealloc];
}

/**
 * awakeFromNib
 */

-(void)awakeFromNib{
	//	[[NSNotificationCenter defaultCenter] addObserver:self
	//											 selector:@selector(expansionPortChanged:)
	//												 name:@"WiiRemoteExpansionPortChangedNotification"
	//											   object:nil];
	
	
	[wii01 setIdentifier:0];
	[wii02 setIdentifier:1];
	[wii03 setIdentifier:2];
	[wii04 setIdentifier:3];
	[wii01 setDelegate:self];
	[wii02 setDelegate:self];
	[wii03 setDelegate:self];
	[wii04 setDelegate:self];
	__wiis[0] = wii01;
	__wiis[1] = wii02;
	__wiis[2] = wii03;
	__wiis[3] = wii04;
	socketServer = [[SocketServer alloc] initWithPort:19028];
	[socketServer start];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(__receivedMessage:)
												 name:@"SockReceivedMessage"
											   object:socketServer];
	
}

/**
 * Wiiリモコンの状態が変化したとき（WiiRemoteControllerのデリゲート）
 * 
 * (NSData*)				state
 * (WiiRemoteController*)	sender
 *
 */

- (void)wiiRemoteStateChanged:(NSData*)state from:(WiiRemoteController*)sender {
	//NSLog(@"wiiRemoteStateChanged");
	[socketServer sendMessage:state];
}

/**
 * データを受信したとき
 * 
 * (NSNotification*)		notification
 *
 */
- (void)__receivedMessage:(NSNotification*)notification {
	//NSLog(@"__receivedMessage");
	NSData* data = [[notification userInfo] objectForKey:@"data"];
	char identifier;
	if ( [data bytes] == nil ) return;
	void *p = (void*)[data bytes];
	memcpy(&identifier, p, sizeof(identifier));
	[__wiis[identifier] setReceivedData:data];
}

- (IBAction)resetServer:(id)sender {
	[socketServer close];
	[socketServer start];
}

- (IBAction)test:(id)sender; {
	char str[10] = "abcdefg";
	[socketServer sendMessage:[NSData dataWithBytes:&str length:sizeof(str)]];
}

/**
 * アプリケーションが終了する前のイベント
 *
 * @param	sender		(I)sender
 * @return	終了するかどうか(NSTerminateNow,NSTerminateCancel,NSTerminateLater)
 */
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	[wii01 disconnect:self];
	[wii02 disconnect:self];
	[wii03 disconnect:self];
	[wii04 disconnect:self];
	return NSTerminateNow;
}


/**
 * 最後のウィンドウが閉じた時のイベント
 *
 * @param	sender		(I)sender
 * @return	NO(最後のウィンドウが閉じられて時に終了しない)
 */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

/**
 * アプリケーションの終了時、NSApplicationから送られる通知
 *
 * @param	notification	(I)Notification
 */
- (void)applicationWillTerminate:(NSNotification *)notification {
	
}


@end
