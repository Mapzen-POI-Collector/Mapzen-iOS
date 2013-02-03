//
//  CMTypesValidator.m
//  Mapzen
//
//  Created by CloudMade Inc. on 2/15/10.
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

#import "CMTypesValidator.h"

#import "CMTypeItemOr.h"
#import "CMTypeItemAnd.h"
#import "CMTypeItemTag.h"
#import "CMTypeItemNo.h"

@interface CMTypesValidator(private)
- (void) startNewTypes;
- (void) stopNewTypes;
- (void) startTypeNamed: (NSString*) typeName;
- (void) stopTypeNamed;
- (void) startDefaults;
- (void) startItemOr;
- (void) startItemAnd;
- (void) startItemNo;
- (void) startTagWithKey: (NSString*) k andValue: (NSString*) v;
- (void) stopItem;
@end



@implementation CMTypesValidator

-(id) initWithTypes: (NSString*) types_xml
{
	[super init];
	//                                         0        1          2        3       4       5       6
	xmlLayout = [NSArray arrayWithObjects: @"types", @"type", @"default", @"or", @"and", @"tag", @"not", nil];
	
	NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], types_xml]];
	
	//TODO: NSXMLParser supports url scheme, maybe file:///location/name.xml will work faster?
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
	
	[xmlParser setDelegate: self];
	
	BOOL success = [xmlParser parse];
	
	if( !success ) {
		ZenLog(@"parsing of osm %@ is FAILED, total %d types read", types_xml, [_types count] );
	}
	
	
	if (ZEN_DEBUG) {
		ZenLog(@"parsing of osm categories is %@, total %d categories.", (success ? @"successful" : @"failed"), [_types count] );
		
		if([_types count] > 0 && success) {
			ZenLog(@"Parsed values count: %d", [_types count]);
			for(CMTypeItem* item in _types) {
				ZenLog(@"%@ has %d %@", item.name, [item.items count], (item.defaults ? (@"with some defaults") : (@"without defaults")) );
				for(CMTypeAbstractItem* sub_item in item.items) {
					ZenLog(@"-- %@", sub_item.items);
				}
			}
		}
	}
	
	[xmlParser release];
	
	return self;
}

- (void) dealloc
{
	[_types release];
	[xmlLayout release];
	[super dealloc];
}

#pragma mark - CMTypeAbstractItem protocol

- (NSString*) getOSMNodeType: (NSDictionary*) items
{
	for(CMTypeItem* type in _types) {
		if( [type validateOSMNodeTags: items] ) {
			return type.name;
		}
	}
	
	return nil;
}

- (NSMutableDictionary*) getDefaultsForType: (NSString*) typeName
{
	NSMutableDictionary* defaults = [NSMutableDictionary dictionaryWithCapacity: 2];
	for(CMTypeItem* type in _types) {
		if( [type.name compare: typeName] == NSOrderedSame) {
			for(CMTypeItemTag* item in type.defaults.items) {
				if( [item isKindOfClass: [CMTypeItemTag class]] ) {
					[defaults setObject: item.v forKey: item.k];
				}
			}
			
			break;
		}
	}
	
	return defaults;
}

#pragma mark XML Deletage methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {
	
	NSInteger index = [xmlLayout indexOfObject: elementName];
	
	//ZenLog(@"parse< : %@ @ %@", elementName, namespaceURI);
	
	switch (index) {
		case 0:
			[self startNewTypes];
			break;
		case 1:
			[self startTypeNamed: [attributeDict objectForKey:@"name"]];
			break;
		case 2:
			[self startDefaults];
			break;
		case 3:
			[self startItemOr];
			break;
		case 4:
			[self startItemAnd];
			break;
		case 5:
			{
				NSString* k = [attributeDict objectForKey:@"key"];
				NSString* v = [attributeDict objectForKey:@"value"];
				[self startTagWithKey: k andValue: v];
			}
			break;
		case 6:
			[self startItemNo];
			break;
		default:
			ZenLog(@"Unrecognized XML element found: %@", elementName);
			break;
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	NSInteger index = [xmlLayout indexOfObject: elementName];
	
	//ZenLog(@"parse />: %@ @ %@", elementName, namespaceURI);
	
	switch (index) {
		case 0:
			[self stopNewTypes];
			break;
		case 1:
			[self stopTypeNamed];
			break;
		case 2:
		case 3:
		case 4:
			[self stopItem];
			break;
		case 5:
			break;
		case 6:
			[self stopItem];
			break;
		default:
			ZenLog(@"Unrecognized XML element stop: %@", elementName);
			break;
	}
	
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

- (void) startNewTypes
{
	[_types release];
	_types = [[NSMutableArray alloc] init];
	parentItems = [[NSMutableArray alloc] init];
}

- (void) stopNewTypes
{
	[parentItems release];
	parentItems = nil;
	ZenLog(@"validator contains %d types", [_types count]);
}

- (void) startTypeNamed: (NSString*) typeName
{
	currentTypeItem = [[CMTypeItem alloc] init];	
	currentTypeItem.name = typeName;
	[parentItems addObject: currentTypeItem];
}

- (void) stopTypeNamed
{
	if( !currentTypeItem.defaults ) { // take care on defaults for any type item ;)
		[self startDefaults];
		for(CMTypeAbstractItem* item in currentTypeItem.items) {
			if([item isKindOfClass: [CMTypeItemTag class]]) {
				[currentTypeItem.defaults addItem: item];
			}
		}
		[self stopItem];
	}
	
	[_types addObject: currentTypeItem];
	[currentTypeItem release];
	currentTypeItem = nil;
	[parentItems removeLastObject];
}

- (void) startDefaults
{
	CMTypeItemDefault* defs = [[CMTypeItemDefault alloc] init];
	currentTypeItem.defaults = defs;
	[parentItems addObject: defs];
	[defs release];
}

- (void) stopItem
{
	[parentItems removeLastObject];
}

- (void)  startItemOr
{
	CMTypeItemOr* or = [[CMTypeItemOr alloc] init];
	
	CMTypeAbstractItem* owner = [parentItems lastObject];
	[owner addItem: or];
	
	[parentItems addObject: or];
	
	[or release];
}

- (void) startItemAnd
{
	CMTypeItemAnd* and = [[CMTypeItemAnd alloc] init];
	
	CMTypeAbstractItem* owner = [parentItems lastObject];
	[owner addItem: and];
	
	[parentItems addObject: and];
	
	[and release];
}

- (void) startItemNo
{
	CMTypeItemNo* no = [[CMTypeItemNo alloc] init];
	
	CMTypeAbstractItem* owner = [parentItems lastObject];
	[owner addItem: no];
	
	[parentItems addObject: no];
	
	[no release];
}

- (void) startTagWithKey: (NSString*) k andValue: (NSString*) v
{
	CMTypeItemTag* tag = [[CMTypeItemTag alloc] initWithKey: k andValue: v ];
	
	CMTypeAbstractItem* owner = [parentItems lastObject];
	[owner addItem: tag];
	
	[tag release];
}

@end
