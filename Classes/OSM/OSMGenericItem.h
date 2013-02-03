//
//  OSMGenericItem.h
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

#import <Foundation/Foundation.h>


@interface OSMGenericItem : NSObject {
	NSMutableDictionary* _allTags;
	NSString*            _id;
	NSString*            _user;
	NSString*            _uid;
	NSString*            _visible;
	NSString*            _version;
	NSString*            _timestamp; // like "2009-04-25T19:53:20Z"	
	
	NSString*            _changeset;
}

@property(nonatomic,retain) NSString* osmId;
@property(nonatomic,retain) NSString* user;
@property(nonatomic,retain) NSString* uid;
@property(nonatomic,retain) NSString* visible;
@property(nonatomic,retain) NSString* version;
@property(nonatomic,retain) NSString* changeset;
@property(nonatomic,retain) NSString* timestamp;

@property(nonatomic,retain) NSMutableDictionary* tags;

- (NSString*) toOsmXmlWithChangeset: (NSString*) changeset asNewNode: (BOOL) asNew;


- (NSString*) xmlGenericItemProperties;// NODE: changeset is NOT included!
- (NSString*) xmlEscapedString: (NSString*) inStr;
- (NSString*) xmlSerializeDictionary: (NSDictionary*) dict xmlContainer: (NSString*) container;

@end
