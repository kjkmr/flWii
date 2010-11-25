/*
 * This file is part of the flWii Project. http://flwii.kimulabo.jp/
 *
 * Copyright (c) 2010 KIMULABO.
 *
 * This code is licensed to you under the terms of the Apache License, version
 * 2.0, or, at your option, the terms of the GNU General Public License,
 * version 2.0. See the APACHE20 and GPL2 files for the text of the licenses,
 * or the following URLs:
 * http://www.apache.org/licenses/LICENSE-2.0
 * http://www.gnu.org/licenses/gpl-2.0.txt
 *
 * If you redistribute this file in source form, modified or unmodified, you
 * may:
 *   1) Leave this header intact and distribute it under the same terms,
 *      accompanying it with the APACHE20 and GPL20 files, or
 *   2) Delete the Apache 2.0 clause and accompany it with the GPL2 file, or
 *   3) Delete the GPL v2 clause and accompany it with the APACHE20 file
 * In all cases you must keep the copyright notice intact and include a copy
 * of the CONTRIB file.
 *
 * Binary distributions must follow the binary distribution requirements of
 * either License.
 */

#import <Cocoa/Cocoa.h>
#import <WiiRemote/WiiRemote.h>
#import <WiiRemote/WiiRemoteDiscovery.h>

typedef enum {
	X,
	Y,
	Z
} WiiAccelerationDirection;

enum {
	pIdentifier					= 0,
	pBatteryLevel				= 1,
	pButtons					= 2,
	pWiiRemoteAccX				= 4,
	pWiiRemoteAccY				= 8,
	pWiiRemoteAccZ				= 12,
	pExpansion					= 16,
	
	//Nunchuk
	pWiiNunchukButtons			= 17,
	pWiiNunchukStickX			= 18,
	pWiiNunchukStickY			= 22,
	pWiiNunchukAccX				= 26,
	pWiiNunchukAccY				= 30,
	pWiiNunchukAccZ				= 34,
	
	//Classic Controller
	pClassicControllerButtons	= 17,
	pClassicControllerStickLX	= 19,
	pClassicControllerStickLY	= 23,
	pClassicControllerStickRX	= 27,
	pClassicControllerStickRY	= 31,
	
	//Balance Board
	pBallanceBoardBottomLeft	= 17,
	pBallanceBoardBottomRight	= 21,
	pBallanceBoardTopLeft		= 25,
	pBallanceBoardTopRight		= 29,
	pBallanceBoardTotal			= 33,
	
	//IR Sensor
	pWiiIR1Connected			= 38,
	pWiiIR1X					= 39,
	pWiiIR1Y					= 43,
	
	pWiiIR2Connected			= 47,
	pWiiIR2X					= 48,
	pWiiIR2Y					= 52,
	
	pWiiIR3Connected			= 56,
	pWiiIR3X					= 57,
	pWiiIR3Y					= 61,
	
	pWiiIR4Connected			= 65,
	pWiiIR4X					= 66,
	pWiiIR4Y					= 70
	
};



@interface WiiRemoteController : NSObject {
	
	
	IBOutlet NSButton*				connectButton;
	IBOutlet NSLevelIndicator*		batteryIndicator;
	IBOutlet NSProgressIndicator*	indicator;
	
	id								delegate;
	
	int								identifier;
	
	WiiRemote*						_wii;
	WiiRemoteDiscovery*				_discovery;
	int								_expansionPortType;
	
	BOOL							_buttons[28];
	unsigned char					_batteryLevel;
	float							_wiiRemoteAccelerations[3];
	float							_wiiNunchukAccelerations[3];
	float							_wiiNunchukStick[2];
	char							_state[80];
	int								_stay;
	
	NSTimer*						_timer;
	
}

- (IBAction)discover:(id)sender;
- (IBAction)disconnect:(id)sender;

- (void) setDelegate:(id) i_delegate;
- (void) setIdentifier:(int)i_identifier;
- (void) vibrate;
- (void) vibrate;
- (void) startVibrate;
- (void) stopVibrate;
- (void) sendData;
- (void) setReceivedData:(NSData*)data;

@end

@interface NSObject (WiiRemoteControllerDelegate)
- (void) wiiRemoteStateChanged:(NSData*)state from:(id)sender;
@end
