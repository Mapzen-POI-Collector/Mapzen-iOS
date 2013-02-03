//
//  Copyright CloudMade 2010. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "ZenSettings.h"
#import "OSMDataDriver.h"

@class MapzenViewController;

@interface MapzenAppDelegate : NSObject <UIApplicationDelegate, OSMDataDriverProtocol> {
    UIWindow*             window;
	UINavigationController* navigationController;
	ZenSettings*          settings;
	OSMDataDriver*		  osmDriver;

}

@property (nonatomic, retain) IBOutlet UIWindow *              window;
@property (nonatomic, retain) IBOutlet UINavigationController* navigationController;
@property (retain, readonly)           ZenSettings*          settings;
@property (readonly)				   OSMDataDriver*		 osmDriver;

+ (ZenSettings*) zenSettings;
+ (MapzenAppDelegate*) instance;

@end

