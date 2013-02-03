//
//  OSMGenericItem.m
//  Mapzen
//
//  Created by CloudMade Inc. on 2/16/10.
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

#import "OSMGenericItem.h"


@implementation OSMGenericItem

@synthesize	osmId = _id;
@synthesize	user = _user;
@synthesize	uid = _uid;
@synthesize	visible = _visible; 
@synthesize	version = _version;
@synthesize	changeset = _changeset;
@synthesize	timestamp = _timestamp;
@synthesize	tags = _allTags;

- (id) init
{
	[super init];
	self.tags = [[NSMutableDictionary alloc] init];
	return self;
}

- (NSString*) toOsmXmlWithChangeset:(NSString *)changeset asNewNode:(BOOL)asNew
{
	// This metod should be implemented in the derived classes like OSMNode and OSMWay
	// in order to return all object features correctly
	return nil;
}

- (NSString*) xmlGenericItemProperties
{
	NSMutableString* preformat = [[NSMutableString alloc] initWithCapacity: 90]; // most records will be less than 90 chars...
	if(_id)		[preformat appendFormat:@" id='%@' ", _id];
	if(_user)        [preformat appendFormat:@" user='%@' ", _user];
	if(_timestamp)   [preformat appendFormat:@" timestamp='%@' ", _timestamp];
	if(_version)     [preformat appendFormat:@" version='%@' ", _version];
	//if(xapiusers) 	[preformat appendFormat:@" xapi:users='%@' ",  xapiusers]; //TODO: set correct initail capacity for preformat
	
	return preformat;
}

- (NSString*) xmlEscapedString: (NSString*) inStr
{
	// predefined entities: 
	// &lt; represents "<", 
	// &gt; represents ">", 
	// &amp; represents "&", 
	// &apos; represents ', 
	// &quot; represents "
	//
	
	NSString* stage_1 = [inStr stringByReplacingOccurrencesOfString:@"&" withString: @"&amp;"];
	
	NSString* stage_2 = [stage_1 stringByReplacingOccurrencesOfString:@"<"  withString: @"&lt;"];
	NSString* stage_3 = [stage_2 stringByReplacingOccurrencesOfString:@">"  withString: @"&gt;"];
	
	NSString* stage_4 = [stage_3 stringByReplacingOccurrencesOfString:@"'"  withString: @"&apos;"];
	NSString* stage_5 = [stage_4 stringByReplacingOccurrencesOfString:@"\"" withString: @"&quot;"];
	
	return stage_5;	
}

- (NSString*) xmlSerializeDictionary: (NSDictionary*) dict xmlContainer: (NSString*) container
{
	NSUInteger projectedSize = [dict count] * 32; // average, 32 chars per tag
	NSMutableString* preformat = [[NSMutableString alloc] initWithCapacity: projectedSize];
	
	for (NSString* key in [dict allKeys] ) {
		if([[dict objectForKey:key] length] > 0) {
			NSString* valEscaped = [self xmlEscapedString: [dict valueForKey: key]];
		    [preformat appendFormat:@"<%@ k='%@' v='%@' />", container , key, valEscaped ];
		}
	}
	return preformat;	
}

@end
