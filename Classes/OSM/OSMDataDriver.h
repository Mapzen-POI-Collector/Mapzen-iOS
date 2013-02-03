//
//  OSMDataDriver.h
//  MapTool
//
//  Created by CloudMade Inc. on 7/28/09.
//  Copyright 2009 CloudMade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSMMapDataDriver.h"

@class OSMNode2, OSMDataDriver, OAToken, OAConsumer;

@protocol OSMDataDriverProtocol <NSObject>
@optional
- (void) OSMChangesetCreated: (OSMDataDriver*) driver;
- (void) OSMChangesetFailed: (OSMDataDriver*) driver;

- (void) OSMNodeCreated: (OSMNode2*) node withDriver: (OSMDataDriver*) driver;
- (void) OSMNodeCreateFailed: (OSMNode2*) node withDriver: (OSMDataDriver*) driver;

- (void) OSMNodeUpdated: (OSMNode2*) node withDriver: (OSMDataDriver*) driver;
- (void) OSMNodeUpdateFailed: (OSMNode2*) node withDriver: (OSMDataDriver*) driver;
@end

@interface OSMDataDriver : NSObject {
	NSString* apiServer;
	NSString* user;
//	NSString* pass;            // outdated - no plain auth anymore
//	NSString* userpassEncoded; // outdated - no plain auth anymore
	NSString* changeset;
	NSDate*   changesetExpireDate;
	
	id<OSMDataDriverProtocol> delegate;
	
	//BOOL	  useOAuth;
	
	OAConsumer	*consumer;
	OAToken		*accessToken;
	
//	NSMutableDictionary *OsmNodes;
	
	NSInteger	counterPoiAdded;
	NSInteger	counterPoiDeleted;
	NSInteger	counterPoiEdited;
	
	NSMutableDictionary* connectionPool;
	
	OSMMapDataDriver* mapData;
}

@property (nonatomic, retain) NSString* apiServer;
@property (nonatomic, retain) NSString* user;
//@property (nonatomic, retain) NSString* pass;
@property (nonatomic, retain) NSString* changeset;
//@property (nonatomic, retain) NSString* userpassEncoded;

@property (nonatomic, readonly) NSDate* changesetExpireDate;

//@property (nonatomic, readonly)    BOOL        useOAuth;
@property (nonatomic, readonly)    OAConsumer *consumer;
@property (nonatomic, readonly)    OAToken    *accessToken;

//@property (nonatomic, readwrite, assign)   NSMutableDictionary *OsmNodes;

@property (nonatomic, readwrite, assign)   id<OSMDataDriverProtocol> delegate;

@property (nonatomic, readonly)	   NSInteger counterPoiAdded, counterPoiDeleted, counterPoiEdited;

@property (nonatomic, retain) OSMMapDataDriver* mapData;

//+ (NSArray*) getNodesWithBBox:(NSString*) bbox forCathegories: (NSArray*) cathegories withServer: (NSString*) server;
//+ (OSMNode2*) getNodeWithID:(NSString*) node_id withServer: (NSString*) server;

- (id) init;
- (id) initWithServer: (NSString*) serverURL andUser: (NSString*) username;
- (void) setUser: (NSString*) username; // andPassword: (NSString*) password; // outdated

- (void) setOAuthToken: (OAToken*) token withConsumer: (OAConsumer*) aConsumer;

- (bool) createChangeset;
- (bool) createNode: (OSMNode2*) node;
- (bool) updateNode: (OSMNode2*) node;
- (bool) deleteNode: (OSMNode2*) node;

- (void) createNode: (OSMNode2*) node onSuccess: (SEL) onSuccess onFail: (SEL) onFail target: (id) target;
- (void) updateNode: (OSMNode2*) node onSuccess: (SEL) onSuccess onFail: (SEL) onFail target: (id) target;
- (void) deleteNode: (OSMNode2*) node onSuccess: (SEL) onSuccess onFail: (SEL) onFail target: (id) target;


- (bool) closeChangeset; 

//- (id) getNodesWithBBox: (NSString*) bbox  forCathegories: (NSArray*) cathegories onSuccess: (SEL) success onFail: (SEL) fail target: (id) target;

- (void) setMapToBBox: (NSString*) bbox onSuccess: (SEL) success onFail: (SEL) fail target: (id) target;
//- (void) cancelBBoxRequest: (id) requestId;


//#pragma mark encoder stuff
//+(NSString*) encodeBase64: (NSString*) dataStr;


@end
