//
//  CategoryDriver.h
//  Mapzen
//
//  Created by CloudMade Inc. on 8/19/09.
//  Copyright 2009 CloudMade. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSMSubcategoryItem : NSObject
{
	NSString* name;
	NSString* tag;
	NSString* description;	
}

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* tag;
@property (nonatomic, retain) NSString* description;

@end


@interface OSMCategoryItem : NSObject
{
	NSString* name;
	NSString* tag;
	NSMutableDictionary* subcategories;
}

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* tag;
@property (nonatomic, retain) NSMutableDictionary* subcategories;

@end

@class OSMNode, CMTypesValidator;


@interface CategoryDriver : NSObject<NSXMLParserDelegate> {

	NSMutableDictionary* _data;
	NSMutableDictionary* categories;
	NSMutableDictionary* osmTypes;
	//NSMutableDictionary* customCategories;
	
	OSMCategoryItem* xmlCurrentCategory;
	OSMSubcategoryItem* xmlCurrentSubcategory;
	
	CMTypesValidator* node_validator;
	CMTypesValidator* way_validator;
	CMTypesValidator* area_validator;
}

@property (nonatomic, retain) CMTypesValidator* node_validator;
@property (nonatomic, retain) CMTypesValidator* way_validator;
@property (nonatomic, retain) CMTypesValidator* area_validator;

+(CategoryDriver*) shareSingleton;

- (id) initWithCathegoryFileName: (NSString*) filename;

- (NSString*) getCategoryNameForOsmTag: (NSString*) tag;
- (NSString*) getSubCathegoryNameForOsmTag: (NSString*) tag;
- (NSString*) getCathegoryFileForOsmTag: (NSString*) tag;

- (NSArray*) getCategories;
- (NSString*) getCategoryNameForCategoryFile: (NSString*) fileName;
- (NSDictionary*) getSubCategory: (NSString*) categoryName;

- (NSArray*) getOsmCategories;
- (NSArray*) getOsmSubcategoryNames: (NSString*) category;
- (NSString*) getOsmSubcategoryTag: (NSString*) category forName: (NSString*) name;

- (bool) validateOsmKey: (NSString*) key andValue: (NSString*) value  checkCustom: (bool) checkCustom;
- (bool) validateOsmTag: (NSString*) tag checkCustom: (bool) checkCustom;
/*
- (void) addCustomValue: (NSString*) value toCategory: (NSString*) category;
- (NSArray*) getCustomValuesForCategory: (NSString*) category;
- (NSString*) getCustomValueName: (NSString*) value ForCategory: (NSString*) category;
*/

/*
- (UIImage*) iconBigForTag:(NSString*) tag alternativeIcon: (NSString*) altName;
- (UIImage*) iconBigForNode: (OSMNode*) node alternativeIcon: (NSString*) altName;
- (UIImage*) iconCategoryBigForTag: (NSString*) categoryName alternativeIcon: (NSString*) altName;
- (UIImage*) iconCategoryBigForType: (NSString*) tag alternativeIcon: (NSString*) altName;
- (UIImage*) iconSmallForNode: (OSMNode*) node alternativeIcon: (NSString*) altName;
- (UIImage*) iconSmallForTag:(NSString*) tag alternativeIcon: (NSString*) altName;
- (UIImage*) iconCategorySmallForTag: (NSString*) categoryName alternativeIcon: (NSString*) altName;
*/
//- (NSString*) proposeAltIconNameForTag: (NSString*) tag smallSize: (bool) smallSize;

- (NSString*) nodeValidator: (NSDictionary*) nodeTags;
- (NSMutableDictionary*) nodeDefaults: (NSString*) nodeType;

@end
