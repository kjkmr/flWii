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

#import "WiiRemoteController.h"
#import "endian.h"

//static float _irPositions[8];
static char _connected[4];

@implementation WiiRemoteController

/*--------------------------------------------------
 * init
 --------------------------------------------------*/
-(id)init{
	self= [super init];
	if (self) {
		_wii = nil;
		_discovery = nil;
		_expansionPortType = -1;
	}
	
	_discovery = [[WiiRemoteDiscovery alloc] init];
	[_discovery setDelegate:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(expansionPortChanged:)
												 name:@"WiiRemoteExpansionPortChangedNotification"
											   object:nil];
	
	
	return self;
}

/*--------------------------------------------------
 * setDelegate
 --------------------------------------------------*/
- (void) setDelegate:(id) i_delegate {
	delegate = i_delegate;
}

/*--------------------------------------------------
 * setIdentifier
 --------------------------------------------------*/
- (void) setIdentifier:(int)i_identifier {
	identifier = i_identifier;
	_state[pIdentifier] = (char)identifier;
	if ( [connectButton image] == nil ) {
		NSString *nameOfImage = [NSString stringWithFormat:@"Number%d",(identifier+1)];
		[connectButton setImage:[NSImage imageNamed:nameOfImage]];
	}
	
}

/*--------------------------------------------------
 * dealloc
 --------------------------------------------------*/
- (void) dealloc {
	[self disconnect:self];
	[_discovery release];
	[_timer release];
	[super dealloc];
}

/*--------------------------------------------------
 * discover
 --------------------------------------------------*/
- (IBAction) discover:(id)sender {
	if ( _wii == nil ) {
		[indicator setHidden:NO];
		[indicator startAnimation:self];
		[_discovery start];
	} else {
		[self vibrate];
	}
}

- (void) WiiRemoteDiscoveryError:(int)code {
	NSLog(@"-- WiiRemote Discovery Error. --");
	[indicator setHidden:YES];
}

- (void) willStartWiimoteConnections {
}


- (void) WiiRemoteDiscovered:(WiiRemote*)wiiremote {

	[indicator setHidden:YES];
	
	if ( _wii != wiiremote) {
		[_wii release];
		_wii = [wiiremote retain];		
	}
	
	[_wii setDelegate:self];
	[_wii setMotionSensorEnabled:YES];
	[_wii setExpansionPortEnabled:YES];
	//[_wii setIRSensorEnabled:YES];
	//[_wii setLEDEnabled1:(identifier == 1) enabled2:(identifier == 2) enabled3:(identifier == 3) enabled4:(identifier == 4)];
	//[_wii setLEDEnabled1:YES enabled2:NO enabled3:YES enabled4:NO];
	
	_connected[identifier] = (char)1;
	
	[self vibrate];
	if ( _timer == nil ) {
		_timer = [NSTimer scheduledTimerWithTimeInterval:1 / 30.0f
												 target:self
											   selector:@selector(sendData)
											   userInfo:nil
												repeats:YES];
	}
}

/*--------------------------------------------------
 * expansionPortChanged
 --------------------------------------------------*/
-(void)expansionPortChanged:(NSNotification *)nc {
	WiiRemote* tmpWii = (WiiRemote*)[nc object];
	if (![[tmpWii address] isEqualToString:[_wii address]]) return;
	[_wii setExpansionPortEnabled:[tmpWii isExpansionPortAttached]];
	//extensionType
	char expansion = [_wii expansionPortType] - 1;
	if ( expansion < 0 ) expansion = 0;
	memcpy( &_state[pExpansion], &expansion, sizeof(expansion) );
}


/*--------------------------------------------------
 * vibrate
 --------------------------------------------------*/
- (void)vibrate {
	if ( _wii == nil ) return;
	[self startVibrate];
	[self performSelector:@selector(stopVibrate) withObject:nil afterDelay:0.2];
}

- (void)startVibrate {
	if ( _wii == nil ) return;
	[_wii setForceFeedbackEnabled:YES];
}


- (void)stopVibrate {
	if ( _wii == nil ) return;
	[_wii setForceFeedbackEnabled:NO];
}

/*--------------------------------------------------
 * disconnect
 --------------------------------------------------*/
- (IBAction) disconnect:(id)sender
{
	[self stopVibrate];
	[_wii closeConnection];
	[_wii release];
}

- (void) wiiRemoteDisconnected:(IOBluetoothDevice*) device
{
	[_wii release];
	_wii = nil;
	_connected[identifier] = (char)0;
	[batteryIndicator setDoubleValue:0];
	NSString *nameOfImage = [NSString stringWithFormat:@"Number%d",(identifier+1)];
	[connectButton setImage:[NSImage imageNamed:nameOfImage]];
}


/*--------------------------------------------------
 * setReceivedData
 --------------------------------------------------*/
- (void) setReceivedData:(NSData*)data {
	char mode,value;
	void *p = (void*)[data bytes];
	memcpy(&mode, p+1, sizeof(mode));
	memcpy(&value, p+2, sizeof(value));
	
	if ( mode == 0x72 ) {
		//vibration
		if ( value == 0x31 ) [self startVibrate];
		else if ( value == 0x30 ) [self stopVibrate];
	} else if ( mode == 0x6c ) {
		//LED
		[_wii setLEDEnabled1:value & 0x01 == 0x01
					enabled2:value >> 1 & 0x01 == 0x01
					enabled3:value >> 2 & 0x01 == 0x01
					enabled4:value >> 3 & 0x01 == 0x01];
	}
}

/*--------------------------------------------------
 * sendData
 --------------------------------------------------*/
- (void) sendData {
	if ( _wii == nil ) return;
	//buttons
	unsigned short buttons = _buttons[WiiRemoteOneButton] << 7 | 
	_buttons[WiiRemoteTwoButton] << 6 | 
	_buttons[WiiRemoteAButton] << 5 | 
	_buttons[WiiRemoteBButton] << 4 | 
	_buttons[WiiRemotePlusButton] << 3 | 
	_buttons[WiiRemoteMinusButton] << 2 | 
	_buttons[WiiRemoteHomeButton] << 1 | 
	_buttons[WiiRemoteUpButton] << 0 |
	_buttons[WiiRemoteDownButton] << 15 | 
	_buttons[WiiRemoteLeftButton] << 13 | 
	_buttons[WiiRemoteRightButton] << 14;
	memcpy( &_state[pButtons], &buttons, sizeof(buttons) );
	
	//expansion
	if ( _expansionPortType == WiiNunchuk ) {
		unsigned char nunchukButtons = _buttons[WiiNunchukCButton] << 1 | _buttons[WiiNunchukZButton] << 0;
		memcpy( &_state[pWiiNunchukButtons], &nunchukButtons, sizeof(nunchukButtons) );
	}
	else if ( _expansionPortType == WiiClassicController ) {
		//buttons
		buttons = _buttons[WiiClassicControllerXButton] << 7 | 
		_buttons[WiiClassicControllerYButton] << 6 | 
		_buttons[WiiClassicControllerAButton] << 5 | 
		_buttons[WiiClassicControllerBButton] << 4 | 
		_buttons[WiiClassicControllerPlusButton] << 3 | 
		_buttons[WiiClassicControllerMinusButton] << 2 | 
		_buttons[WiiClassicControllerHomeButton] << 1 | 
		_buttons[WiiClassicControllerUpButton] << 0 |
		_buttons[WiiClassicControllerDownButton] << 15 | 
		_buttons[WiiClassicControllerLeftButton] << 13 | 
		_buttons[WiiClassicControllerRightButton] << 14 |
		_buttons[WiiClassicControllerLButton] << 12 | 
		_buttons[WiiClassicControllerRButton] << 11 |
		_buttons[WiiClassicControllerZLButton] << 10 | 
		_buttons[WiiClassicControllerZRButton] << 9;
		memcpy( &_state[pClassicControllerButtons], &buttons, sizeof(buttons) );
		
	}
	else if ( _expansionPortType == WiiBalanceBoard ) {
		
	}
	
	//IR Sensor
	/*
	int i;
	for ( i=0; i<4; i++ ) {
		memcpy( &_state[pWiiIR1Connected], &_connected[i], sizeof(_connected[i]) );
		memcpy( &_state[pWiiIR1X], &_irPositions[i*2], sizeof(_irPositions[i*2]) );
		memcpy( &_state[pWiiIR1Y], &_irPositions[i*2+1], sizeof(_irPositions[i*2+1]) );
	}
	*/
	
	// 通知
	NSData* data = [NSData dataWithBytes:_state length:sizeof(_state)];
	if ( [delegate respondsToSelector:@selector(wiiRemoteStateChanged:from:)] ) {
		[delegate wiiRemoteStateChanged:data from:self];
	}
}


/*--------------------------------------------------
 * delegate for WiiRemote
 --------------------------------------------------*/

- (void) wiimoteWillSendData {
}

- (void) wiimoteDidSendData {
	if ( _expansionPortType != [_wii expansionPortType] ) {
		_expansionPortType = [_wii expansionPortType];
		if ( _expansionPortType == WiiExpUknown || _expansionPortType == WiiExpNotAttached ) {
			[connectButton setImage:[NSImage imageNamed:@"StateWii"]];
		} else if ( _expansionPortType == WiiNunchuk ) {
			[connectButton setImage:[NSImage imageNamed:@"StateNunchuk"]];
		} else if ( _expansionPortType == WiiClassicController ) {
			[connectButton setImage:[NSImage imageNamed:@"StateClassic"]];
		} else if ( _expansionPortType == WiiBalanceBoard ) {
			[connectButton setImage:[NSImage imageNamed:@"StateBalanceBoard"]];
		}
	}
	//[self sendData];
}

//Battery
- (void) batteryLevelChanged:(double) level {
	[batteryIndicator setDoubleValue:(level * [batteryIndicator maxValue])];
	_batteryLevel = (unsigned char)(level * 0xC8);
	memcpy( &_state[pBatteryLevel], &_batteryLevel, sizeof(_batteryLevel) );
}

//IR Sensor
/*
- (void) irPointMovedX:(float) px Y:(float) py {
	_irPositions[identifier*2] = px;
	_irPositions[identifier*2+1] = py;
}
- (void) rawIRData: (IRData[4]) irData {
	NSLog(@"rawIRData");
	NSLog([NSString stringWithFormat:@"%f, %f",irData[0].x,irData[0].y]);
}
*/

//Button
- (void) buttonChanged:(WiiButtonType) type isPressed:(BOOL) isPressed {
	_buttons[type] = isPressed;
}

//Acceleration
- (void) accelerationChanged:(WiiAccelerationSensorType) type accX:(unsigned short) accX accY:(unsigned short) accY accZ:(unsigned short) accZ {
	//NSLog(@"accelerationChanged");
	WiiAccCalibData data;
	if ( type == WiiRemoteAccelerationSensor ) data = [_wii accCalibData:WiiRemoteAccelerationSensor];
	else if ( type == WiiNunchukAccelerationSensor ) data = [_wii accCalibData:WiiNunchukAccelerationSensor];
	else return;
	
	unsigned short x0 = data.accX_zero;
	unsigned short x1 = data.accX_1g - x0;
	
	unsigned short y0 = data.accY_zero;
	unsigned short y1 = data.accY_1g - y0;
	
	unsigned short z0 = data.accZ_zero;
	unsigned short z1 = data.accZ_1g - z0;
	
	
	float nx = convertFloat( (float)(accX - z0 - x1 ) / (float)x1 + 0.5 );
	float ny = convertFloat( (float)(accY - y0 - y1 ) / (float)y1 + 0.5 );
	float nz = convertFloat( (float)(accZ - z0 - z1 ) / (float)z1 * (-1.0) + 0.5 );
	
	if ( type == WiiRemoteAccelerationSensor ) {
		memcpy( &_state[pWiiRemoteAccX], &nx, sizeof(nx) );
		memcpy( &_state[pWiiRemoteAccY], &ny, sizeof(ny) );
		memcpy( &_state[pWiiRemoteAccZ], &nz, sizeof(nz) );
	} else if ( type == WiiNunchukAccelerationSensor ) {
		memcpy( &_state[pWiiNunchukAccX], &nx, sizeof(nx) );
		memcpy( &_state[pWiiNunchukAccY], &ny, sizeof(ny) );
		memcpy( &_state[pWiiNunchukAccZ], &nz, sizeof(nz) );
	}
}

//JoyStick
- (void) joyStickChanged:(WiiJoyStickType) type tiltX:(unsigned short) tiltX tiltY:(unsigned short) tiltY {
	
	
	unsigned short max;
	unsigned short center;
	if ( type == WiiNunchukJoyStick ) {
		max = 0xE0;
		center = 0x80;
	} else if ( type == WiiClassicControllerLeftJoyStick ) {
		max = 0x40;
		center = 0x20;
	} else if ( type == WiiClassicControllerRightJoyStick ) {
		max = 0x20;
		center = 0x10;
	}
	
	float shiftedX = (tiltX * 1.0) - (center * 1.0);
	float shiftedY = (tiltY * 1.0) - (center * 1.0);
	float scaledX = (shiftedX * 1.0) / ((max - center) * 1.0);
	float scaledY = (shiftedY * 1.0) / ((max - center) * 1.0);
	
	float nx = convertFloat( scaledX );
	float ny = convertFloat( scaledY );
	
	if ( type == WiiNunchukJoyStick ) {
		memcpy( &_state[pWiiNunchukStickX], &nx, sizeof(nx) );
		memcpy( &_state[pWiiNunchukStickY], &ny, sizeof(ny) );
	} else if ( type == WiiClassicControllerLeftJoyStick ) {
		memcpy( &_state[pClassicControllerStickLX], &nx, sizeof(nx) );
		memcpy( &_state[pClassicControllerStickLY], &ny, sizeof(ny) );
	} else if ( type == WiiClassicControllerRightJoyStick ) {
		memcpy( &_state[pClassicControllerStickRX], &nx, sizeof(nx) );
		memcpy( &_state[pClassicControllerStickRY], &ny, sizeof(ny) );
	}
	
}
//AnalogButton
/*
- (void) analogButtonChanged:(WiiButtonType) type amount:(unsigned short) press {
}
*/

//Balance Board
- (void) pressureChanged:(WiiPressureSensorType) type pressureTR:(float) bPressureTR pressureBR:(float) bPressureBR 
			  pressureTL:(float) bPressureTL pressureBL:(float) bPressureBL
{
	
	float bl = convertFloat(bPressureBL);
	float br = convertFloat(bPressureBR);
	float tl = convertFloat(bPressureTL);
	float tr = convertFloat(bPressureTR);
	float total = convertFloat( bPressureBL + bPressureBR + bPressureTL + bPressureTR );
	
	memcpy( &_state[pBallanceBoardBottomLeft], &bl, sizeof(bl) );
	memcpy( &_state[pBallanceBoardBottomRight], &br, sizeof(br) );
	memcpy( &_state[pBallanceBoardTopLeft], &tl, sizeof(tl) );
	memcpy( &_state[pBallanceBoardTopRight], &tr, sizeof(tr) );
	memcpy( &_state[pBallanceBoardTotal], &total, sizeof(total) );
	
}

- (void) rawPressureChanged:(WiiBalanceBoardGrid) bbData
{
}

- (void) allPressureChanged:(WiiPressureSensorType) type bbData:(WiiBalanceBoardGrid) bbData bbDataInKg:(WiiBalanceBoardGrid) bbDataInKg
{
}

//Mii
/*
- (void) gotMiiData: (Mii*) mii_data_buf at: (int) slot
{
}
 */



@end
