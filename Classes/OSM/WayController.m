//
//  WayController.m
//  Mapzen
//
//  Created by CloudMade Inc. on 2/22/10.
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

#import "WayController.h"
#import "CategoryDriver.h"
#import "CMTypesValidator.h"
#import "OSMMapDataDriver.h"
#import "MapzenAppDelegate.h"
#import "OSMNode2.h"


@implementation WayController

+ (id) wayControllerForOSMWay: (OSMWay*) way
{
	// Try area first
	NSString* type = [[CategoryDriver shareSingleton].area_validator getOSMNodeType: way.tags];
	
	//if(!type) { //TODO: check if it is line
	//}
	
	if (type) {
		WayController* wc = [[WayController alloc] init];
		wc.type = type;
		wc.osmId = way.osmId;
		wc.name = [way.tags valueForKey:@"name"];
		
		return wc;
	} else {
		ZenLog(@"Way unrecognized: %@", way.tags);
	}
	
	return nil;
}

- (CLLocationCoordinate2D) location
{
	CLLocationCoordinate2D coord;
	
	
	OSMMapDataDriver* mapData = [MapzenAppDelegate instance].osmDriver.mapData;
	
	OSMWay* way = [mapData wayById: self.osmId];
	
	if (way) {
		CLLocationDegrees count;
		for(NSString* ref in way.references) {
			OSMNode2* node = [mapData nodeById: ref];
			if(node) {
				coord.latitude  +=  [node.lat doubleValue];
				coord.longitude +=  [node.lon doubleValue];
				count++;
			}
		}
		coord.latitude  /= count;
		coord.longitude /= count;
	}
	
	return coord;
}

- (OSMGenericItem*) osmGenericItem
{
	OSMDataDriver* osmDriver = [MapzenAppDelegate instance].osmDriver;
	return [osmDriver.mapData wayById: self.osmId];
}

@end
