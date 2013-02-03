//
//  CategoryDriver.m
//  Mapzen
//
//  Created by CloudMade Inc. on 8/19/09.
//  Copyright 2009 CloudMade. All rights reserved.
//

#import "CategoryDriver.h"
#import "Utils.h"
#import "CMTypesValidator.h"

#define kCustomCategoryKey @"customCategories"

@implementation OSMSubcategoryItem
@synthesize name, tag, description;
@end

@implementation OSMCategoryItem
@synthesize name, tag, subcategories;
@end


//@interface CategoryDriver (private)

//- (void) readCustomCategories;
//- (void) insertCustomValue: (NSString*) value toCategory: (NSString*) category;

//@end


@implementation CategoryDriver

@synthesize node_validator, way_validator, area_validator;

static CategoryDriver* sharedSingleton;

+(CategoryDriver*) shareSingleton
{
	@synchronized(self)
	{
		if(!sharedSingleton)
			sharedSingleton = [[CategoryDriver alloc] initWithCathegoryFileName:@"categories"];
		
		return sharedSingleton;
	}
	
	return sharedSingleton;
}


- (id) initWithCathegoryFileName: (NSString*) filename
{
	self = [super init];
	
	_data = [[NSMutableDictionary alloc] initWithCapacity: 16];
	
	categories = [[NSMutableDictionary alloc] initWithCapacity: 16];
	
	osmTypes = [[NSMutableDictionary alloc] initWithCapacity: 16];
	
	//customCategories = [[NSMutableDictionary alloc] init]; //TODO: custom tags
	
	NSArray* cathegories = [Utils getCategories: filename];
	
	for(NSString* cathegory in cathegories)
	{
		NSArray* cathegory_pair = [cathegory componentsSeparatedByString: @">>>"];
		
		if( [cathegory_pair count] == 2 ) 
		{
			NSString* name = [cathegory_pair objectAtIndex: 0];
			NSString* file = [cathegory_pair objectAtIndex: 1];
			
			[categories setObject: name forKey: file];
			
			NSArray* subCathegories = [Utils getCategories: file];
			
			NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
			
			for( NSString* subCathegory in subCathegories) 
			{
				// Format is "BLA BLA">>>tag=val
				NSArray* subCathegory_pair = [subCathegory componentsSeparatedByString: @">>>"];
				
				if([subCathegory_pair count] == 2) {
					NSString* name = [subCathegory_pair objectAtIndex: 0];
					NSString* key = [subCathegory_pair objectAtIndex: 1];
					
					[dic setObject: name forKey: key];
					//ZenLog(@"  %@ add item: [%@] as [%@]", name, key, value);
				}
			}
			//ZenLog(@"CathegoryDriver: save cathegory: %@ with %d items", name, [dic count]);
			[_data setObject: dic forKey: file];
		}
	}
	
	// Parsing osm tag=value  description xml file...
	
	NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], @"osm_categories.xml"]];
	
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
	
	[xmlParser setDelegate: self];

	BOOL success = [xmlParser parse];
	
	ZenLog(@"parsing of osm categories is %@, total %d categories.", (success ? @"successful" : @"failed"), [osmTypes count] );
	
	if([osmTypes count] > 0 && success){
		ZenLog(@"Parsed values: %@", osmTypes);
		
		
	}
	
	[xmlParser release];
	
	// node validator:
	self.node_validator = [[CMTypesValidator alloc] initWithTypes: @"node_types.xml"];
	//self.way_validator  = [[CMTypesValidator alloc] initWithTypes: @"way_types.xml"];
	self.area_validator = [[CMTypesValidator alloc] initWithTypes: @"area_types.xml"];
	
	// and finally read custom categories, entered by user...
	
	// [self readCustomCategories]; //TODO: custom tags
	
//	NSArray* shopNames = [self getOsmSubcategoryNames: @"shop"];
//	
//	NSArray *sortedShops = [shopNames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
//	
//	if(shopNames) {
//		for(NSString* name in sortedShops) {
//			ZenLog(@"%@>>>shop=%@", [name capitalizedString], [self getOsmSubcategoryTag:@"shop" forName: name]);
//		}
//	}
	
	return self;
}

- (void) dealloc
{
	[_data release];
	[categories release];
	[osmTypes release];
	//[customCategories release]; //TODO: custom tags
	[super dealloc];
}

#pragma mark Custom (User-added tags)
/*
- (void) readCustomCategories
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	
	NSString* cc = [ud stringForKey: kCustomCategoryKey];
	
	if(cc) {
		NSArray* pairs = [cc componentsSeparatedByString: @"&"];
		
		if([pairs count]) {
			for(NSString* pair in pairs) {
				NSArray* keyVal = [pair componentsSeparatedByString:@"="];
				
				if([keyVal count] == 2) {
					NSLog(@"Custom values add: %@", keyVal);
					[self insertCustomValue: [keyVal objectAtIndex:1] toCategory: [keyVal objectAtIndex:0 ]];
				}
			}
		}
		
	}
}
- (void) insertCustomValue: (NSString*) value toCategory: (NSString*) category 
{
	NSMutableDictionary* dic = [customCategories objectForKey: category];
	
	if(dic == nil) {
		dic = [[NSMutableDictionary alloc] init];
		[customCategories setObject: dic forKey: category];
	}
	
	NSString* valueName = [value stringByReplacingOccurrencesOfString:@"_" withString: @" "];
	
	[dic setObject:[valueName capitalizedString] forKey: value];	
}
- (void) addCustomValue: (NSString*) value toCategory: (NSString*) category
{
	[self insertCustomValue: value toCategory: category];
	
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	
	
	NSString* cCat = [NSString string];
	
	for(NSString* key in [customCategories allKeys]) {
		NSMutableDictionary* item = [customCategories objectForKey: key];
		for(NSString* val in [item allKeys]) {
			cCat = [cCat stringByAppendingFormat:@"%@=%@&", key, val];
		}
	}
	
	[ud setObject:cCat forKey: kCustomCategoryKey];
	[ud synchronize];
}

- (NSArray*) getCustomValuesForCategory: (NSString*) category
{
	NSMutableDictionary* dic = [customCategories objectForKey: category];
	
	if([dic count]) {
		return [dic allKeys];
	}
	
	return nil;
}

- (NSString*) getCustomValueName: (NSString*) value ForCategory: (NSString*) category
{
	NSMutableDictionary* dic = [customCategories objectForKey: category];
	
	if([dic count]) {
		NSString* res = [dic objectForKey: value];
		NSLog(@"Lookup for %@ among: {%@}", value, [dic allKeys]);
		return res;
	}
	
	return nil;
}
*/

#pragma mark Zen Cateories

- (NSArray*) getCategories
{
	return [_data allKeys];
}

- (NSString*) getCategoryNameForCategoryFile: (NSString*) fileName
{
	return [categories objectForKey: fileName ];
}


- (NSDictionary*) getSubCategory: (NSString*) categoryName
{
	return [_data objectForKey: categoryName];
}

#pragma mark OSM Categorization (amenity,shop, etc.)


- (NSString*) getCategoryNameForOsmTag: (NSString*) tag
{
	return [categories objectForKey: [self getCathegoryFileForOsmTag:tag] ];
}
- (NSString*) getSubCathegoryNameForOsmTag: (NSString*) tag
{
	if([_data count] > 0)
	{
		NSArray* dictionaries = [_data allValues];
		
		for(NSMutableDictionary* dic in dictionaries) 
		{
			NSString* subCathegoryName = [dic objectForKey: tag];
			if(  subCathegoryName != nil)
			{
				return subCathegoryName;
			}
		}
	}
	
	return nil;
}

- (NSString*) getCathegoryFileForOsmTag: (NSString*) tag
{
	if([_data count] > 0)
	{
		NSArray* keys = [_data allKeys];
		
		for(NSString* key in keys) 
		{
			NSMutableDictionary* dic = [_data objectForKey: key];

			if( [dic objectForKey: tag] != nil)
			{
				//ZenLog(@"getCathegoryFileForOsmTag: %@ = %@", tag, key);
				return key;
			}
		}
	}
	//ZenLog(@"getCathegoryFileForOsmTag: %@ = nil", tag);
	return nil;
}

- (NSArray*) getOsmCategories
{
	return [osmTypes allKeys];
}

- (NSArray*) getOsmSubcategoryNames: (NSString*) category
{
	OSMCategoryItem* categoryItem = [osmTypes objectForKey: category];	
	if(categoryItem) {
		return [categoryItem.subcategories allKeys];
	}
	return nil;
}

- (NSString*) getOsmSubcategoryTag: (NSString*) category forName: (NSString*) name
{
	OSMCategoryItem* categoryItem = [osmTypes objectForKey: category];	
	if(categoryItem) {
		OSMSubcategoryItem* subItem = [categoryItem.subcategories objectForKey: name];
		if(subItem) {
			return subItem.tag;
		}
	}
	return nil;
}

- (bool) validateOsmKey: (NSString*) key andValue: (NSString*) value checkCustom: (bool) checkCustom
{
	OSMCategoryItem* category = [osmTypes objectForKey: key];
	
	if(category != nil) {
		OSMSubcategoryItem* subcategory = [category.subcategories objectForKey: value];
		if(subcategory != nil) {
			return TRUE;
		}
		//TODO: custom
		/*
		if(checkCustom) {
				return ([self getCustomValueName: value ForCategory: key] != nil);
		}*/
	}
	
	return FALSE;
}

- (bool) validateOsmTag: (NSString*) tag checkCustom: (bool) checkCustom
{
	NSArray* keyAndValue = [tag componentsSeparatedByString:@"="];
	bool res = FALSE;
	if([keyAndValue count] == 2) {
		NSString* key   = [keyAndValue objectAtIndex:0];
		NSString* value = [keyAndValue objectAtIndex:1];
		res = [self validateOsmKey: key andValue: value checkCustom: checkCustom];
	}
	return res;
}

#pragma mark Node2 logic

- (NSString*) nodeValidator: (NSDictionary*) nodeTags
{
	return [node_validator getOSMNodeType: nodeTags];
}

- (NSMutableDictionary*) nodeDefaults: (NSString*) nodeType
{
	return [node_validator getDefaultsForType: nodeType];
}

#pragma mark Icons

-(NSString*) getTagIconName: (NSString*) tag smallSize: (BOOL) smallSize
{
	NSString* normalizedTag = [tag stringByReplacingOccurrencesOfString: @"=" withString: @"_"];
	NSString* prefix = (smallSize ? @"s_" : @"");
	return [NSString stringWithFormat:@"%@%@.png",prefix, normalizedTag];	
}

- (UIImage*) iconNamed:(NSString*) name alternativeIcon: (NSString*) altName
{
	UIImage* img = [UIImage imageNamed: name];
	
	if(!img && altName) {
		img = [UIImage imageNamed: altName];
	}
	
	return img;	
}
/*
- (UIImage*) iconBigForTag:(NSString*) tag alternativeIcon: (NSString*) altName
{
	return [self iconNamed: [self getTagIconName: tag smallSize: NO] alternativeIcon: altName];
}
- (UIImage*) iconBigForNode: (OSMNode*) node alternativeIcon: (NSString*) altName
{
	return [self iconNamed: [self getNodeIconName: node smallSize: NO] alternativeIcon: altName];
}
- (UIImage*) iconCategoryBigForTag: (NSString*) tag alternativeIcon: (NSString*) altName
{
	return [self iconNamed: [self getCategoryIconNameForTag: tag smallSize: NO] alternativeIcon: altName];
}
- (UIImage*) iconCategoryBigForType: (NSString*) tag alternativeIcon: (NSString*) altName
{
	return [self iconNamed: [Utils getIconNameForType: tag] alternativeIcon: altName];
}
- (UIImage*) iconSmallForNode: (OSMNode*) node alternativeIcon: (NSString*) altName
{
	return [self iconNamed: [self getNodeIconName: node smallSize: YES] alternativeIcon: altName];
}
- (UIImage*) iconSmallForTag:(NSString*) tag alternativeIcon: (NSString*) altName
{
	return [self iconNamed: [self getTagIconName: tag smallSize: YES] alternativeIcon: altName];
}
- (UIImage*) iconCategorySmallForTag: (NSString*) tag alternativeIcon: (NSString*) altName
{
	return [self iconNamed: [self getCategoryIconNameForTag: tag smallSize: YES] alternativeIcon: altName];
}

- (NSString*) proposeAltIconNameForTag: (NSString*) tag smallSize: (bool) smallSize
{
	bool isShop = [tag hasPrefix:@"shop="];
	
	if(isShop) return [Utils getIconNameForType: (smallSize ? @"small_Shopping" : @"Shopping")];
	
	NSString* categoryIcon = [self getCategoryIconNameForTag: tag smallSize: smallSize];
	
	if(categoryIcon) return categoryIcon;
	
	return (smallSize ? @"poi_tmp.png" : @"unknowntype.png");
	
}
*/
#pragma mark XML Deletage methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {
	
	if([elementName isEqualToString:@"category"]) {
		//Initialize the array.
		if(xmlCurrentCategory == nil) {
			xmlCurrentCategory= [[OSMCategoryItem alloc] init];
		} else {
			xmlCurrentCategory.name = nil;
			xmlCurrentCategory.tag = nil;
			[xmlCurrentCategory.subcategories removeAllObjects];
		}
		xmlCurrentCategory.name = [attributeDict objectForKey:@"name"];
		xmlCurrentCategory.tag = [attributeDict objectForKey:@"tag"];
		xmlCurrentCategory.subcategories = [[NSMutableDictionary alloc] init];
		
		ZenLog(@"Start Category: %@", xmlCurrentCategory.name);
	}
	else if([elementName isEqualToString:@"subcategory"]) {
		
		//Initialize the node.
		if(xmlCurrentSubcategory == nil)
		{
			xmlCurrentSubcategory = [[OSMSubcategoryItem alloc] init];
		}
		
		//Extract the attribute here.
		
		xmlCurrentSubcategory.name = [attributeDict objectForKey:@"v"];
		xmlCurrentSubcategory.tag  = [attributeDict objectForKey:@"k"];
		xmlCurrentSubcategory.description = [attributeDict objectForKey:@"description"];
		
		if([xmlCurrentSubcategory.name length] == 0) { //generate name from tag
			
			NSString* noUnderscores = [xmlCurrentSubcategory.tag stringByReplacingOccurrencesOfString: @"_" withString: @" "];
			xmlCurrentSubcategory.name = [noUnderscores capitalizedString];
		}
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	if([elementName isEqualToString:@"category"]){
		
		if(osmTypes == nil) {
			osmTypes = [[NSMutableDictionary alloc] init];
		}
		NSAssert(xmlCurrentCategory.tag != nil,@"Nil in xmlCurrentCategory.tag");
		
		//ZenLog(@"***add category: %@", xmlCurrentCategory.name);
		
		[osmTypes setObject: xmlCurrentCategory forKey: xmlCurrentCategory.tag];
		
		[xmlCurrentCategory release];
		
		xmlCurrentCategory = nil;
		
		return;
	}
	
	if([elementName isEqualToString:@"subcategory"]) {
		NSAssert(xmlCurrentSubcategory.tag != nil,@"Nil in xmlCurrentSubcategory.tag");
		//ZenLog(@"add subcategory: %@ desc=%@", xmlCurrentSubcategory.name, xmlCurrentSubcategory.description);
		[xmlCurrentCategory.subcategories setObject: xmlCurrentSubcategory forKey: xmlCurrentSubcategory.tag];
		
		[xmlCurrentSubcategory release];
		xmlCurrentSubcategory = nil;
			
		return;
	}
	
	if([elementName isEqualToString:@"osm_categories"]) {
		[xmlCurrentSubcategory release];
		xmlCurrentSubcategory = nil;
		
		[xmlCurrentCategory release];
		xmlCurrentCategory = nil;
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

@end
