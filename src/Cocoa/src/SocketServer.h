//
//  SocketServer.h
//  flWii
//
//  Created by Kimura Koji on 10/11/07.
//  Copyright 2010 STARRYWORKS inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <netinet/in.h>
#import <net/if.h>

@interface SocketServer : NSObject {
	int port;
}

- (id)initWithPort:(int)i_port;
- (void)sendMessage:(NSData*)message;
- (void)start;
- (void)close;
@end
