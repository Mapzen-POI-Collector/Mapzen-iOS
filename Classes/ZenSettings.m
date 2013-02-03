//
//  ZenSettings.m
//  Mapzen
//
//  Created by CloudMade Inc. on 5/5/10.
//	Copyright (c) 2011, CloudMade Inc.
//	All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//		*	Redistributions of source code must retain the above copyright
//			notice, this list of conditions and the following disclaimer.
//		*	Redistributions in binary form must reproduce the above copyright
//			notice, this list of conditions and the following disclaimer in the
//			documentation and/or other materials provided with the distribution.
//		*	Neither the name of the CloudMade Inc. nor the
//			names of its contributors may be used to endorse or promote products
//			derived from this software without specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL CLOUDMADE INC BE LIABLE FOR ANY
//	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "ZenSettings.h"

#define kZenSettingLocationLon  @"zen.location.lon"
#define kZenSettingLocationLat  @"zen.location.lat"
#define kZenSettingLocationZoom @"zen.location.zoom"

@implementation ZenSettings

@synthesize location, zoom;

- (id) init
{
	[super init];
	
	NSUserDefaults* user = [NSUserDefaults standardUserDefaults];
	
	zoom = [user floatForKey: kZenSettingLocationZoom];
	
	if (zoom != 0) {
		location.latitude  = [user doubleForKey: kZenSettingLocationLat];
		location.longitude = [user doubleForKey: kZenSettingLocationLon];
	} else {
		location.latitude = kZenDefaultLocationLat;
		location.latitude = kZenDefaultLocationLon;
		zoom              = kZenDefaultLocationZoom;
	}

	return self;
}

- (void) updateLocation: (CLLocationCoordinate2D) newLocation withZoom: (CGFloat) newZoom
{
	location = newLocation;
	zoom = newZoom;
	
	NSUserDefaults* user = [NSUserDefaults standardUserDefaults];
	
	[user setDouble: location.latitude  forKey: kZenSettingLocationLat];
	[user setDouble: location.longitude forKey: kZenSettingLocationLon];
	[user setFloat:zoom forKey: kZenSettingLocationZoom];
	[user synchronize];
}

@end
