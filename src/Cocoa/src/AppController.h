//
//  AppController.h
//  flWii
//
//  Created by Kimura Koji on 10/11/04.
//  Copyright 2010 STARRYWORKS inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WiiRemoteController.h"
#import "SocketServer.h"


@interface AppController : NSObject {
	
	IBOutlet WiiRemoteController*	wii01;
	IBOutlet WiiRemoteController*	wii02;
	IBOutlet WiiRemoteController*	wii03;
	IBOutlet WiiRemoteController*	wii04;
	SocketServer*					socketServer;
}

- (IBAction)test:(id)sender;
- (IBAction)resetServer:(id)sender;
- (void)wiiRemoteStateChanged:(NSData*)state from:(WiiRemoteController*)sender;
// アプリケーションが終了する前のイベント
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
// 最後のウィンドウが閉じた時のイベント
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;
// アプリケーションの終了時、NSApplicationから送られる通知
- (void)applicationWillTerminate:(NSNotification *)notification;

@end
