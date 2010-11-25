/*
 *  endian.c
 *  flWii
 *
 *  Created by Kimura Koji on 10/11/14.
 *  Copyright 2010 STARRYWORKS inc. All rights reserved.
 *
 */

#include "endian.h"

float convertFloat(float valf) {
	int val;
	memcpy(&val,&valf,sizeof(val));
	val = (val<<24) | ((val<<8) & 0x00ff0000) | ((val>>8) & 0x0000ff00) | ((val>>24) & 0x000000ff) ;
	memcpy(&valf,&val,sizeof(valf));
	return valf;
}