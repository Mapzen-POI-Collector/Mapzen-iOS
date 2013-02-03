//
//  Copyright CloudMade 2010. All rights reserved.
//

#import "MapzenAppDelegate.h"
#import "MapzenViewController.h"

@implementation MapzenAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize settings;
@synthesize osmDriver;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	
	settings = [[[ZenSettings alloc] init] retain];
	
	osmDriver = [[OSMDataDriver alloc] initWithServer:OSM_DATASERVER andUser: @"j8 "];
	osmDriver.delegate = self;
    
    // Override point for customization after app launch
	
	navigationController.navigationBarHidden = YES;
	[navigationController.topViewController.view sizeToFit];
	[navigationController.view sizeToFit];
	
    [window addSubview:navigationController.view];
    [window makeKeyAndVisible];
}

+ (ZenSettings*) zenSettings
{	
	return [MapzenAppDelegate instance].settings;
}

+ (MapzenAppDelegate*) instance
{
	return (MapzenAppDelegate*) [UIApplication sharedApplication].delegate;
}


- (void)dealloc {
    [navigationController release];
    [window release];
	[osmDriver release];
	[settings release];
    [super dealloc];
}


@end
