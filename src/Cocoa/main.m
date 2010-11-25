//
//  main.m
//  flWii
//
//  Created by Kimura Koji on 10/11/04.
//  Copyright STARRYWORKS inc. 2010. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <signal.h>

void sigHandler(int signal) {
	//do nothing
	//NSLog(@"SIGPIPE");
}

int main(int argc, char *argv[]) {
	
	//ignore signal
	signal(SIGPIPE,sigHandler);
	
    return NSApplicationMain(argc,  (const char **) argv);
}
