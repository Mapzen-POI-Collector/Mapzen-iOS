//
//  OSMMapDataDriver.m
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

#import "OSMMapDataDriver.h"
#import "OSMWay.h"
#import "OSMNode2.h"
#import "OSMRelation.h"
#import "OSMGenericItem.h"

@interface OSMMapDataDriver(private)

- (void) startOsm;
- (void) startNode: (NSDictionary*) attr;
- (void) startWay: (NSDictionary*) attr;
- (void) startRelation: (NSDictionary*) attr;
- (void) startTag: (NSDictionary*) attr;
- (void) startND: (NSDictionary*) attr;
- (void) startMember: (NSDictionary*) attr;
- (void) extractGenericAttributes: (NSDictionary*) attr forItem: (OSMGenericItem*) item;

@end


@implementation OSMMapDataDriver

@synthesize nodes = _nodes, ways = _ways, relations = _relations, bbox;

- (id) init
{
	[super init];
	self.nodes = [NSMutableArray arrayWithCapacity: 0];
	self.ways = [NSMutableArray arrayWithCapacity: 0];
	self.relations = [NSMutableArray arrayWithCapacity: 0];
	// helper                                 0       1       2          3          4      5      6
 	xmlLayout = [[NSArray arrayWithObjects: @"osm", @"node", @"way", @"relation", @"tag", @"nd", @"member", nil] retain];
	
	return self;
}

+ (id) OSMMapDataDriverWithBBox: (NSString*) bBox
{
	OSMMapDataDriver* shadow = [[OSMMapDataDriver alloc] init];
		
	NSString* urlstr = [NSString stringWithFormat:@"%@/api/0.6/map?bbox=%@", OSM_DATASERVER, bBox];
	ZenLog(@"OSMMapDD BBOX: %@", urlstr);
	NSURL *url = [NSURL URLWithString: urlstr];
	
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL: url];
	
	[xmlParser setDelegate: shadow];
			
	if ([xmlParser parse]) {
		shadow.bbox = bBox;
		return [shadow autorelease];
	}
	
	return nil;
}

- (OSMGenericItem*) itemByOsmID: (NSString*) osmId fromArray: (NSArray*) items
{
	for(OSMGenericItem* i in items) {
		if( [i.osmId compare: osmId] == NSOrderedSame ) return i;
	}
	return nil;
}

- (OSMNode2*) nodeById: (NSString*) osmId
{
	return (OSMNode2*) [self itemByOsmID: osmId fromArray: _nodes];
}
- (OSMWay*) wayById: (NSString*) osmId
{
	return (OSMWay*) [self itemByOsmID: osmId fromArray: _ways];
}
- (OSMRelation*) relationById: (NSString*) osmId
{
	return (OSMRelation*) [self itemByOsmID: osmId fromArray: _relations];
}

#pragma mark XML Deletage methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {
	
	NSInteger index = [xmlLayout indexOfObject: elementName];
	
	//ZenLog(@"parse< : %@ @ %@", elementName, namespaceURI);
	
	switch (index) {
		case 0:
			[self startOsm]; break;
		case 1:
			[self startNode: attributeDict]; break;
		case 2:
			[self startWay: attributeDict]; break;
		case 3:
			[self startRelation: attributeDict]; break;
		case 4:
			[self startTag: attributeDict]; break;
		case 5:
			[self startND: attributeDict]; break;
		case 6:
			[self startMember: attributeDict]; break;
		default:
			ZenLog(@"Unrecognized XML element found: %@", elementName);
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	NSInteger index = [xmlLayout indexOfObject: elementName];
	
	if (index > 6) ZenLog(@"Unrecognized XML element stop: %@", elementName);
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	ZenLog(@"Parser error occured: %@", [parseError localizedDescription]);
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError
{
	ZenLog(@"Parser validation error occured: %@", [validError localizedDescription]);
}

#pragma mark helpers

- (void) startOsm
{
	[_nodes removeAllObjects];
	[_ways removeAllObjects];
	[_relations removeAllObjects];
	targetArray = nil;
}

- (void) proceedItem: (OSMGenericItem*) item withAttributes: (NSDictionary*) attr toArray: (NSMutableArray*) array
{
	[self extractGenericAttributes: attr forItem: item];
	[array addObject: item];
	targetArray = array;
	[item release];
}

- (void) startNode: (NSDictionary*) attr
{
	OSMNode2* node = [[OSMNode2 alloc] init];
	node.lat = [attr valueForKey:@"lat"];
	node.lon = [attr valueForKey:@"lon"];
	[self proceedItem: node withAttributes: attr toArray: _nodes];
}

- (void) startWay: (NSDictionary*) attr
{
	OSMWay* way = [[OSMWay alloc] init];
	[self proceedItem: way withAttributes: attr toArray: _ways];
}

- (void) startRelation: (NSDictionary*) attr
{
	OSMRelation* rel = [[OSMRelation alloc] init];
	[self proceedItem: rel withAttributes: attr toArray: _relations];
}

- (void) startTag: (NSDictionary*) attr
{
	OSMGenericItem* item = [targetArray lastObject];
	NSString* k = [attr valueForKey: @"k"];
	NSString* v = [attr valueForKey: @"v"];
	[item.tags setObject: v forKey: k];
}

- (void) startND: (NSDictionary*) attr
{
	OSMWay* way = [targetArray lastObject];
	NSString* ref = [attr valueForKey: @"ref"];
	[way.references addObject: ref];
}

- (void) startMember: (NSDictionary*) attr
{
	OSMRelation* rel = [targetArray lastObject];
	NSString* type = [attr valueForKey: @"type"];
	NSString* ref  = [attr valueForKey: @"ref"];
	NSString* role = [attr valueForKey: @"role"];
	
	NSString* record = [NSString stringWithFormat:@"%@|%@|%@", type, ref, role];
	
	[rel.members addObject: record];
}

- (void) extractGenericAttributes: (NSDictionary*) attr forItem: (OSMGenericItem*) item
{
	item.osmId = [attr valueForKey:@"id"];
	item.user = [attr valueForKey:@"user"];
	item.uid = [attr valueForKey: @"uid"];
	item.visible = [attr valueForKey:@"visible"];
	item.version = [attr valueForKey: @"version"];
	item.changeset = [attr valueForKey: @"changeset"];
	item.timestamp = [attr valueForKey: @"timestamp"];
}

@end
