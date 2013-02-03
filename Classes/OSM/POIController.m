//
//  POIController.m
//  Mapzen
//
//  Created by CloudMade Inc. on 2/19/10.
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

#import "POIController.h"
#import "OSMNode2.h"
#import "CategoryDriver.h"
#import "MapzenAppDelegate.h"


@implementation POIController

@synthesize iconBig = _iconBig, iconSmall = _iconSmall;

- (id) initWithNode2: (OSMNode2*) node
{
	[super init];
	self.osmId = node.osmId;
	self.name = [node.tags objectForKey:@"name"];
	
	self.type = [[CategoryDriver shareSingleton] nodeValidator: node.tags];
	
	//TODO: image lookup
	/*
	if(_type) {
		NSMutableDictionary* defs  = [[CategoryDriver shareSingleton] nodeDefaults: _type];
		
		for(NSString* k in [defs allKeys] ) {
			NSString* tag = [NSString stringWithFormat:@"%@=%@", k, [defs objectForKey: k]];
			
			UIImage* img = [[CategoryDriver shareSingleton] iconSmallForTag: tag alternativeIcon: nil];
			
			if(img) {
				self.iconSmall = img;
				self.iconBig = [[CategoryDriver shareSingleton] iconBigForTag: tag alternativeIcon: nil];
				
				break;
			}
		}
	}
	 */
	return self;
}

- (CLLocationCoordinate2D) location
{
	CLLocationCoordinate2D coord;
	OSMDataDriver* osmDriver = [MapzenAppDelegate instance].osmDriver;
	OSMNode2* node = [osmDriver.mapData nodeById: self.osmId];
	
	if (node) {
		coord.latitude = [node.lat doubleValue];
		coord.longitude = [node.lon doubleValue];
	}
	
	return coord;
}

- (OSMGenericItem*) osmGenericItem
{
	OSMDataDriver* osmDriver = [MapzenAppDelegate instance].osmDriver;
	return [osmDriver.mapData nodeById: self.osmId];
}

@end
