//
//  Copyright CloudMade 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMMapView.h"
#import "RMMapViewDelegate.h" 

#import <CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioToolbox.h>


@class OSMDataDriver;

@interface MapzenViewController : UIViewController<CLLocationManagerDelegate, RMMapViewDelegate> {
	IBOutlet RMMapView* mapView;
	IBOutlet UIBarButtonItem* locationButton;
	
	CLLocationManager* locationManager;
		
	SEL   afterMapTouchAction;
	id    afterMapTouchObject1;
	id    afterMapTouchObject2;
}

- (IBAction) locationButtonClicked: (id) sender;

@end

