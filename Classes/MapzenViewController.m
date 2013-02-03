////
//  Copyright CloudMade 2010. All rights reserved.
//

#import "MapzenViewController.h"
#import "RMCloudMadeMapSource.h"
#import "MapzenAppDelegate.h"
#import "OSMDataDriver.h"
#import "RMMarkerManager.h"
#import "POIController.h"
#import "WayController.h"
#import "POIDetailsController.h"

#import "RMMarker+CMAnnotationView.h"


@interface RMMarker (Utilities)
- (BOOL) isNode;
- (BOOL) isWay;
- (OSMGenericItemController*) osmGenericItem;
@end

@implementation RMMarker (Utilities)

- (BOOL) isNode
{
	return [self.data isKindOfClass:[POIController class]];
}

- (BOOL) isWay
{
	return [self.data isKindOfClass:[WayController class]];
}

- (OSMGenericItemController*) osmGenericItem
{
	if ([self.data isKindOfClass:[OSMGenericItemController class]]) {
		return (OSMGenericItemController*) self.data;
	}
	return nil;
}

@end

@interface RMMarkerManager (Utilities)
- (void) resetMarkers;
@end


@implementation RMMarkerManager (Utilities)

- (void) resetMarkers
{
	NSArray* markers = [self markers];
	for (RMMarker* m in markers) {
		OSMGenericItemController* item = [m osmGenericItem];
		if ([item active]) {
			item.active = NO;
			m.bounds = CGRectMake( m.bounds.origin.x, m.bounds.origin.y, item.size.width,  item.size.height);
			[m hideLabel];
		}
	}
}

@end





@interface MapzenViewController(private)
- (void) loadMapView;
- (void) saveMapLocation;
- (void) setAfterMapTouchAction: (SEL) action withObject: (id) object1 withObject: object2;
- (void) performAfterMapTouchAction;
- (void) updateMap;
- (NSString*) strBBox;
@end

@implementation MapzenViewController



/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self loadMapView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear: animated];
	
	self.navigationController.navigationBarHidden = YES;
	
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
}

- (void) loadMapView
{
	mapView.delegate = self;
	
	// init CloudMade tilesourse
	id cmTilesource = [[[RMCloudMadeMapSource alloc] initWithAccessKey: ZEN_API_KEY styleNumber: ZEN_MAP_STYLE_ID] autorelease];
	
	// have to initialize the RMMapContents object explicitly if we want it to use a particular tilesource
	[[[RMMapContents alloc] initWithView:mapView tilesource: cmTilesource] autorelease];
	
	//Set Map For Some initial location (by Default center of World Map, or use previous location)
	[mapView moveToLatLong: [MapzenAppDelegate zenSettings].location ];
	[mapView.contents setZoom: [MapzenAppDelegate zenSettings].zoom ];
	
	[self updateMap];
	
}

#pragma mark visible bbox data management

- (void) updateMap
{
	if (mapView.contents.zoom > 16.6) {
		[[MapzenAppDelegate instance].osmDriver setMapToBBox: [self strBBox] 
												   onSuccess: @selector(bboxUpdated) 
													  onFail: @selector(bboxUpdateFailed:) 
													  target: self];	

	}
}

- (NSString*) strBBox
{
	CGRect screenBounds = mapView.contents.screenBounds;
	CGPoint left = screenBounds.origin;
	
	left.y += screenBounds.size.height;
	
	CGPoint right;
	
	right.x = left.x + screenBounds.size.width;
	right.y = left.y - screenBounds.size.height;
	
	CLLocationCoordinate2D leftLatLng = [mapView.contents pixelToLatLong:left];
	CLLocationCoordinate2D rightLatLng = [mapView.contents pixelToLatLong:right];
	
	NSString* bboxx = [NSString stringWithFormat:@"%f,%f,%f,%f", leftLatLng.longitude, leftLatLng.latitude, rightLatLng.longitude, rightLatLng.latitude ];
	
	return bboxx;
}

- (void) bboxUpdated
{
	[mapView.markerManager removeMarkers];
	
	OSMMapDataDriver* mapData = [MapzenAppDelegate instance].osmDriver.mapData;
	
	NSMutableArray* markers = [NSMutableArray arrayWithCapacity: [mapData.ways count] + [mapData.nodes count]];
	
	RMMarker* newMarker = nil;
	
	for(OSMWay* w in mapData.ways) 
	{
		WayController* wc = [WayController wayControllerForOSMWay: w];
		
		if(wc) {
			ZenLog(@"Check way type: %@", wc.type);
			UIImage* img = [UIImage imageNamed:@"poi_tmp.png"];
			
			newMarker = [[RMMarker alloc] initWithUIImage: img anchorPoint:CGPointMake(0.5, 0.5)];
			
			newMarker.data = wc;
			
			[mapView.contents.markerManager addMarker:newMarker AtLatLong: [wc location]];
			
			[newMarker release];
		}
	}
	
	for(OSMNode2* n in mapData.nodes) {
		
		POIController* pcontroller = [[POIController alloc] initWithNode2: n];
		
		if(pcontroller.type) {
			UIImage* img = (pcontroller.iconSmall) ? pcontroller.iconSmall : [UIImage imageNamed:@"location_center.png"];
			
			RMMarker* newMarker = [[RMMarker alloc] initWithUIImage: img anchorPoint:CGPointMake(0.5, 0.5)];
			
			newMarker.data = pcontroller;
			
			[markers addObject: newMarker];
			
			[newMarker release];
		}
		
		[pcontroller release];
		
		
	}
	
	for(RMMarker* m in markers) {
		POIController* pcontroller = (POIController*) m.data;
		[mapView.contents.markerManager addMarker: m AtLatLong: [pcontroller location]];
	}
	
}

- (void) bboxUpdateFailed: (NSError*) err
{
	ZenLog(@"MVC: bbox fail: %@", [err localizedDescription]);
}

#pragma mark Location Button

- (IBAction) locationButtonClicked: (id) sender
{
	NSLog(@"Location button click %@", sender);
	
	if(locationManager == nil)
	{
		locationManager = [[[CLLocationManager alloc] init] retain];
		locationManager.delegate = self;
	}
    
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
	
	if(locationManager.locationServicesEnabled == YES) {
		[locationManager startUpdatingLocation]; // set up location manager
	} else {
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Location Service is Disabled" 
														message: @"Locations service is disabled. You can enable them from the Settings by toggling the switch in Settings > General > Location Services." 
													   delegate: nil 
											  cancelButtonTitle: @"Dismiss" 
											  otherButtonTitles: nil];
		[alert show];
	}	
}


- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	[mapView moveToLatLong: newLocation.coordinate];

	NSLog(@"Location =(lat,lon) %f , %f, accuracy: h = %f, v = %f, denominator: %f ", 
		   newLocation.coordinate.latitude, newLocation.coordinate.longitude, 
		   newLocation.horizontalAccuracy, newLocation.verticalAccuracy,
		   mapView.contents.metersPerPixel );
	
	float locationAccuracy = newLocation.horizontalAccuracy;
	
	float metersPerPixel = mapView.contents.metersPerPixel;
	
	float zoomFactor = 1.0f/(((locationAccuracy*2.5f) / metersPerPixel) / mapView.frame.size.width);
	
	NSLog(@"zoomFactor = %f [ mpp = %f, la = %f ]", zoomFactor, metersPerPixel, locationAccuracy);
	
	[mapView zoomByFactor: zoomFactor near: CGPointMake( mapView.frame.size.width/2 , mapView.frame.size.height/2 ) ];
	
	[self saveMapLocation];

	if( mapView.contents.zoom > 18) {
		[mapView.contents setZoom: 18.0];
	}
	
	if (locationAccuracy < 50.0f) {
		[locationManager stopUpdatingLocation];
		NSLog(@"Location Shut Down");
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	}
}

#pragma mark RMMapViewDelegate

- (void) beforeMapMove: (RMMapView*) map
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
}
- (void) afterMapMove: (RMMapView*) map
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	[self setAfterMapTouchAction: @selector(saveMapLocation) 
					  withObject: nil 
					  withObject: nil];
}

- (void) beforeMapZoom: (RMMapView*) map byFactor: (float) zoomFactor near:(CGPoint) center
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
}
- (void) afterMapZoom: (RMMapView*) map byFactor: (float) zoomFactor near:(CGPoint) center
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	[self setAfterMapTouchAction: @selector(saveMapLocation) 
					  withObject: nil 
					  withObject: nil];	
}

//- (void) doubleTapOnMap: (RMMapView*) map At: (CGPoint) point
//{
//	NSLog(@"%s", __PRETTY_FUNCTION__);
//}

- (void) singleTapOnMap: (RMMapView*) map At: (CGPoint) point
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	CGFloat minDx = 16;
	CGFloat minDy = 16;
	CGFloat distance = minDy + minDx;
	
	RMMarker* closestMarker = nil;
	
	NSArray* markers = [map.markerManager markersWithinScreenBounds];
	
	for (RMMarker* m in markers) {
		OSMGenericItemController* item = [m osmGenericItem];
		if (item) {
			CGFloat dx = fabsf(m.position.x - point.x);
			CGFloat dy = fabsf(m.position.y - point.y);			
			
			if( (dx < minDx || dy < minDy) && (dx + dy < distance) ) {
				minDx = dx;
				minDy = dy;
				distance = dx+dy;
				closestMarker = m;
			}
		}
	}

	if(closestMarker != nil) {
		[self tapOnMarker: closestMarker onMap: map];
	} else {
		[map.markerManager resetMarkers];
	}

	
}

- (void) tapOnMarker: (RMMarker*) marker onMap: (RMMapView*) map
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
		
	OSMGenericItemController* item = [marker osmGenericItem];
	
	if (item) {
		if (item.active) {
			[map.markerManager resetMarkers];
		} else {
			[map.markerManager resetMarkers];
			
			item.size = marker.bounds.size;
			
			marker.bounds = CGRectMake(marker.bounds.origin.x, 
									   marker.bounds.origin.y, 
									   marker.bounds.size.width * 1.5, 
									   marker.bounds.size.height * 1.5);
			
			[marker addAnnotationViewWithTitle: item.name];
			
			item.active = YES;
		}
	}
	
	[self setAfterMapTouchAction: nil withObject: nil withObject: nil];
}
- (void) tapOnLabelForMarker: (RMMarker*) marker onMap: (RMMapView*) map
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	OSMGenericItemController* item = [marker osmGenericItem];
	if ( item ) {
		[marker hideLabel];
		POIDetailsController* pdc = [[POIDetailsController alloc] initWithPOIController: item];
		[self.navigationController pushViewController: pdc animated: YES];
		[pdc release];
	}
	
	
}
- (BOOL) mapView:(RMMapView *)map shouldDragMarker:(RMMarker *)marker withEvent:(UIEvent *)event
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	return NO;
}
- (void) mapView:(RMMapView *)map didDragMarker:(RMMarker *)marker withEvent:(UIEvent *)event
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
}
- (void) afterMapTouch: (RMMapView*) map
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	[self performAfterMapTouchAction];
}

#pragma mark Map Move/Zoom Actions

- (void) saveMapLocation
{
	[[MapzenAppDelegate zenSettings] updateLocation: [mapView.contents pixelToLatLong: mapView.center] 
										   withZoom:  mapView.contents.zoom ];	
	
	[self updateMap];
}

- (void) updateMapContents
{
	[mapView.markerManager removeMarkers];
	
	OSMDataDriver* osmDriver = ((MapzenAppDelegate*) [UIApplication sharedApplication]).osmDriver;
	//CategoryDriver* cDriver = [CategoryDriver shareSingleton];
	
	NSMutableArray* markers = [NSMutableArray arrayWithCapacity: 100];
	
	for(OSMWay* w in osmDriver.mapData.ways) 
	{
		WayController* wc = [WayController wayControllerForOSMWay: w];
		
		if(wc) {
			ZenLog(@"Check way type: %@", wc.type);
			UIImage* img = [UIImage imageNamed:@"poi_tmp.png"];
			
			RMMarker* newMarker = [[RMMarker alloc] initWithUIImage: img anchorPoint:CGPointMake(0.5, 0.5)];
			
			newMarker.data = wc;
			
			[mapView.contents.markerManager addMarker:newMarker AtLatLong: [wc location]];
			
			[newMarker release];
		}
	}
	
	for(OSMNode2* n in osmDriver.mapData.nodes) {
		
		POIController* pcontroller = [[POIController alloc] initWithNode2: n];
		
		if(pcontroller.type) {
			UIImage* img = (pcontroller.iconSmall) ? pcontroller.iconSmall : [UIImage imageNamed:@"location_center.png"];
			
			RMMarker* newMarker = [[RMMarker alloc] initWithUIImage: img anchorPoint:CGPointMake(0.5, 0.5)];
			
			newMarker.data = pcontroller;
			
			[markers addObject: newMarker];
			
			[newMarker release];
		}
		
		[pcontroller release];
		
		
	}
	
	for(RMMarker* m in markers) {
		POIController* pcontroller = (POIController*) m.data;
		[mapView.contents.markerManager addMarker: m AtLatLong: [pcontroller location]];
	}
	
	//[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark Map Touch Actions

- (void) setAfterMapTouchAction: (SEL) action withObject: (id) object1 withObject: object2
{
	afterMapTouchAction = action;
	afterMapTouchObject1 = object1;
	afterMapTouchObject2 = object2;	
}

- (void) performAfterMapTouchAction
{
	if (afterMapTouchAction) {
		[self performSelector: afterMapTouchAction 
				   withObject: afterMapTouchObject1 
				   withObject: afterMapTouchObject2];
	}
}


#pragma mark UIViewController delegates

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES; //(interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	
	[locationManager release];
	locationManager = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
