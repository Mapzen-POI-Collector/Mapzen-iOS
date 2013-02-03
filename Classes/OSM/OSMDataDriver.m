//
//  OSMDataDriver.m
//  MapTool
//
//  Created by CloudMade Inc. on 7/28/09.
//  Copyright 2009 CloudMade. All rights reserved.
//

#import "OSMDataDriver.h"

#import "OAConsumer.h"
#import "OAToken.h"
#import "OAPlaintextSignatureProvider.h"
#import "OAMutableURLRequest.h"
#import "OSMActionTicket.h"
#import "ConnectionInfo.h"
#import "CategoryDriver.h"
#import "OSMNode2.h"

@interface OSMDataDriver (private)

- (void) performOsmRequest: (NSString*) requestUrl 
				  withBody: (NSString*) body 
				 andMethod: (NSString*) method 
				 onSuccess: (SEL) success 
					onFail: (SEL) fail 
			    withTicket: (id) object;

- (void) performOsmRequestWithBasicAuthentication: (NSString*) requestUrl 
										 withBody: (NSString*) body 
										andMethod: (NSString*) method 
										onSuccess: (SEL) success 
										   onFail: (SEL) fail 
									   withTicket: (id) object;

- (void) performOsmRequestWithOAuth: (NSString*) requestUrl 
						   withBody: (NSString*) body 
						  andMethod: (NSString*) method 
						  onSuccess: (SEL) success 
						     onFail: (SEL) fail 
						 withTicket: (id) object;


- (void) loadPoiCounter;
- (void) savePoiCounter;

@end


@implementation OSMDataDriver

@synthesize apiServer, user, changeset;
@synthesize consumer, accessToken;
//@synthesize OsmNodes;
@synthesize delegate;
@synthesize counterPoiAdded, counterPoiDeleted, counterPoiEdited;
@synthesize changesetExpireDate;

@synthesize mapData;

#pragma mark init Routine

- (id) init
{
	self = [super init];
	self.apiServer = OSM_DATASERVER;
	
	//OsmNodes = [[NSMutableDictionary alloc] init];
	
	connectionPool = [[NSMutableDictionary alloc] init];
	
	changesetExpireDate = nil;
		
	return self;
}
- (id) initWithServer: (NSString*) serverURL andUser: (NSString*) username
{
	self = [self init];
	self.apiServer = serverURL;
	self.user = username;
	[self loadPoiCounter];
	return self;
}

- (void) dealloc
{
	[self savePoiCounter];

	NSArray* connections = [connectionPool allKeys];
	for(NSURLConnection* connection in connections)  {
		[connection cancel];
	}
	[connectionPool release];
	
	[changesetExpireDate release];
	
	[super dealloc];
}

#pragma mark poiCounter

- (void) loadPoiCounter
{	
	NSString* poiCounter = [NSString stringWithFormat:@"%@_poiCounter", self.user];
	NSString* poiDeleted = [NSString stringWithFormat:@"%@_poiDeleted", self.user];
	NSString* poiEdited  = [NSString stringWithFormat:@"%@_poiEdited" , self.user];
	
	NSNumber* added   = [[NSUserDefaults standardUserDefaults] objectForKey: poiCounter];
	NSNumber* deleted = [[NSUserDefaults standardUserDefaults] objectForKey: poiDeleted];
	NSNumber* edited  = [[NSUserDefaults standardUserDefaults] objectForKey: poiEdited ];
	
	counterPoiAdded = added.intValue;
	counterPoiDeleted = deleted.intValue;
	counterPoiEdited = edited.intValue;

	ZenLog(@"poiCounter(%@): %d deleted: %d edited: %d",user, counterPoiAdded, counterPoiDeleted, counterPoiEdited);
}

- (void) savePoiCounter
{
	NSUserDefaults			*defaults = [NSUserDefaults standardUserDefaults];
	
	NSString* poiCounter = [NSString stringWithFormat:@"%@_poiCounter", self.user];
	NSString* poiDeleted = [NSString stringWithFormat:@"%@_poiDeleted", self.user];
	NSString* poiEdited  = [NSString stringWithFormat:@"%@_poiEdited" , self.user];
	
	[defaults setObject: [NSNumber numberWithInt: counterPoiAdded]   forKey: poiCounter ];
	[defaults setObject: [NSNumber numberWithInt: counterPoiDeleted] forKey: poiDeleted ];
	[defaults setObject: [NSNumber numberWithInt: counterPoiEdited]  forKey: poiEdited  ];
	[defaults synchronize];
	ZenLog(@"poiCounter(%@): %d deleted: %d edited: %d",user, counterPoiAdded, counterPoiDeleted, counterPoiEdited);
}

#pragma mark credentials setup

- (void) setUser: (NSString*) username
{
	[user release];
	user = username;
	[user retain];
	
	[self loadPoiCounter];
}

- (void) setOAuthToken: (OAToken*) token withConsumer: (OAConsumer*) aConsumer
{
	[accessToken release];
	[consumer release];
	
	accessToken = [[OAToken alloc] initWithKey:token.key secret:token.secret];
	consumer = [[OAConsumer alloc] initWithKey: aConsumer.key secret: aConsumer.secret];
}



#pragma mark non-static data fetchers
/*
- (id) getNodesWithBBox: (NSString*) bbox  forCathegories: (NSArray*) cathegories onSuccess: (SEL) success onFail: (SEL) fail target: (id) target
{
	NSString* urlstr = [[NSString alloc] initWithFormat:@"%@/api/0.6/map?bbox=%@", OSM_DATASERVER, bbox];
	ZenLog(@"Get BBOX: %@", urlstr);
	NSURL *url = [[NSURL alloc] initWithString:urlstr];
	NSURLRequest* req = [NSURLRequest requestWithURL: url];
	
	
	OSMActionTicket* aTicket = [[OSMActionTicket alloc] initWithAction: OAGenericAction 
															withObject: cathegories 
															 onSuccess: success 
																onFail: fail 
															 forTarget: target];
	
	ConnectionInfo* ci = [[ConnectionInfo alloc] initWithTarget: self 
													  onSuccess: @selector(onNodesBBoxSucessed:withData:) 
														 onFail: @selector(onNodesBBoxFailed:withError:)  
												   withUserData: aTicket];
	
	NSURLConnection* conn = [NSURLConnection connectionWithRequest: req delegate: self];
	
	[connectionPool setObject: ci forKey:[NSNumber numberWithUnsignedInteger: (NSUInteger) conn] ];
	
	ZenLog(@"Request Created: %d", conn );
	
	return conn;
}*/

- (void) proceedBBoxRequest: (OSMActionTicket*) ticket
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	OSMMapDataDriver* newMapData = [OSMMapDataDriver OSMMapDataDriverWithBBox: (NSString*) ticket.userObject];
	
	if(newMapData)
	{
		self.mapData = newMapData;
		
		ZenLog(@"Found %d nodes, %d ways, %d relations", [mapData.nodes count], [mapData.ways count], [mapData.relations count]);
		
		if(ticket.target && ticket.onSuccess) [ticket.target performSelector: ticket.onSuccess withObject: nil];
	}
	else
	{
		ZenLog(@"XML Parser error...");
		if(ticket.target && ticket.onFail) {
			[ticket.target performSelector: ticket.onFail 
								withObject: [NSError errorWithDomain:@"Request for bbox was failed" code: 204 userInfo: nil]];
		}		
	}
	
	[pool release];
}


- (void) setMapToBBox: (NSString*) bbox onSuccess: (SEL) success onFail: (SEL) fail target: (id) target
{		
	OSMActionTicket* aTicket = [[OSMActionTicket alloc] initWithAction: OAGenericAction 
															withObject: bbox 
															 onSuccess: success 
																onFail: fail 
															 forTarget: target];
	
	[self performSelectorInBackground:@selector(proceedBBoxRequest:) withObject: aTicket];
	
	[aTicket release];
}

/*
- (void) cancelBBoxRequest: (id) requestId
{
	NSNumber* key = [NSNumber numberWithUnsignedInteger: (NSUInteger) requestId];
	
	ConnectionInfo* ci = [connectionPool objectForKey: key];
	
	if( ci ) {
		NSURLConnection* conn = (NSURLConnection*) requestId;
		
		ZenLog(@"Request Cancelled: %d", requestId );
		
		if ([conn isMemberOfClass:[NSURLConnection class]]) {
			[conn cancel];
		}
		
		if(ci.target && ci.onFail) {
			// HTTP Code 204 - No Content
			//NSError* err = ;
			
			[ci.target performSelector: ci.onFail 
							withObject: ci.userData 
							withObject: [NSError errorWithDomain:@"Request for bbox was cancelled" code: 204 userInfo: nil]];
		}
		
		[connectionPool removeObjectForKey: key];
	}
}
*/

- (void) onNodesBBoxFailed: (OSMActionTicket*) ticket withError:(NSError*) error
{
	ZenLog(@"BBOX Load failed with error: %@", [error localizedDescription]);
	
	if(ticket.target && ticket.onFail) {
		[ticket.target performSelector: ticket.onFail withObject: error];
	}	
	
	[ticket release];
	
}


#pragma mark OSM request management

- (void) performOsmRequest: (NSString*) requestUrl 
				  withBody: (NSString*) body 
				 andMethod: (NSString*) method 
				 onSuccess: (SEL) success 
					onFail: (SEL) fail 
			    withTicket: (id) object
{
	[self performOsmRequestWithOAuth: requestUrl
							withBody: body 
						   andMethod: method 
						   onSuccess: success 
							  onFail: fail 
						  withTicket: object];
}
/*
- (void) performOsmRequestWithBasicAuthentication: (NSString*) requestUrl 
										 withBody: (NSString*) body 
										andMethod: (NSString*) method 
										onSuccess: (SEL) success 
										   onFail: (SEL) fail 
									   withTicket: (id) object
{
	NSString* strUrl = [[[NSString alloc] initWithFormat:@"%@%@", apiServer, requestUrl] autorelease];
	
	NSURL* url = [NSURL URLWithString:strUrl]; 
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
	
	[request setTimeoutInterval: ZEN_TIMEOUT_INTERVAL];
	
	[request setHTTPMethod: method];
	
	if(body != nil) {
		NSData* dataRequestBody = [body dataUsingEncoding:NSUTF8StringEncoding];
		[request setHTTPBody:dataRequestBody];
	}
	
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
	[request setValue:[NSString stringWithFormat:@"Basic %@", userpassEncoded] forHTTPHeaderField:@"AUTHORIZATION"];
	
	if( [method compare:@"PUT"] ==  NSOrderedSame ) {
		[request setValue:@"PUT" forHTTPHeaderField:@"X_HTTP_METHOD_OVERRIDE"];
	}
	
	NSHTTPURLResponse* theResponce = nil; 
	NSError* theError = nil;
	
	ZenLog(@"AUTHORIZATION: %@:%@  -> HASH64:%@", user, pass, userpassEncoded);
	
	NSData* serverData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponce error: &theError];
	
	ZenLog(@"HTTP Responce: %d", [theResponce statusCode] );
	
	BOOL requestSuccess = (serverData != nil && [theResponce statusCode] == 200); 
	
	SEL selector = requestSuccess ? success : fail;
	
	NSObject* param = requestSuccess ? (NSObject*) serverData : (NSObject*) theError; 
	
	if(selector) [self performSelector: selector withObject: object  withObject: param ];
}
*/
- (void) performOsmRequestWithOAuth: (NSString*) requestUrl 
						   withBody: (NSString*) body 
						  andMethod: (NSString*) method 
						  onSuccess: (SEL) success 
						     onFail: (SEL) fail 
						 withTicket: (id) object
{
	NSString* strUrl = [[[NSString alloc] initWithFormat:@"%@%@", apiServer, requestUrl] autorelease];
	
	NSURL* url = [NSURL URLWithString:strUrl]; 
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL: url
                                                                   consumer: consumer
                                                                      token: accessToken
                                                                      realm: nil
                                                          signatureProvider: nil];
	
	[request setTimeoutInterval: ZEN_TIMEOUT_INTERVAL];
	[request setHTTPMethod: method];
	
	[request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
	
	[request prepare];
	
	if(body != nil) {
		NSData* dataRequestBody = [[body dataUsingEncoding:NSUTF8StringEncoding] autorelease];
		[request setHTTPBody:dataRequestBody];
	}
	    
	ZenLog(@"OAuth request begin...");
		
	NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate: self];

	ConnectionInfo* ci = [[ConnectionInfo alloc] initWithTarget: self onSuccess: success onFail: fail withUserData: object];
	
	[connectionPool setObject: ci forKey:[NSNumber numberWithUnsignedInteger: (NSUInteger) connection] ];
}

#pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	ZenLog(@"OSMDataDriver:connection:didReceiveData");
	
	ConnectionInfo* ci = [connectionPool objectForKey: [NSNumber numberWithUnsignedInteger: (NSUInteger) connection]];
	
	if(ci != nil) [ci.receivedData appendData: data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	ZenLog(@"OSMDataDriver:connectionDidFinishLoading");
	
	NSNumber* connectionId = [NSNumber numberWithUnsignedInteger: (NSUInteger) connection];
	
	ConnectionInfo* ci = [connectionPool objectForKey: connectionId];
	
	if(ci != nil) {
		ZenLog(@"OSMDataDriver:connectionDidFinishLoading: call success selector");
		[ci.target performSelector: ci.onSuccess withObject: ci.userData withObject: ci.receivedData];
	}
	
	[connectionPool removeObjectForKey: connectionId];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	ZenLog(@"OSMDataDriver:connection:didFailWithError: %@", [error localizedDescription]);
	
	NSNumber* connectionId = [NSNumber numberWithUnsignedInteger: (NSUInteger) connection];
	
	ConnectionInfo* ci = [connectionPool objectForKey: connectionId];
	
	if(ci != nil) {
		[ci.target performSelector: ci.onFail withObject: ci.userData withObject: error];
	}
	
	[connectionPool removeObjectForKey: connectionId];	
}

#pragma mark WRITE Operations with OSM

#pragma mark changesets

- (bool) createChangeset
{
	if( [changeset length] > 0) {
		return TRUE;
	}
		
	NSString* strRequestBody = [[NSString alloc] initWithFormat:
		@"<osm><changeset>"
		"<tag k=\"created_by\" v=\"%@ %@\"/>"
		//"<tag k=\"comment\" v=\"Just for testing\"/>"
		"</changeset>"
		"</osm>", CREATED_BY_TAG, ZEN_VERSION];
	
	[changesetExpireDate release];
	// server claims 1 hour changeset is valid, we are using here 30 min intervals to be
	// ensured
	changesetExpireDate = [[NSDate dateWithTimeIntervalSinceNow: 1800] retain];
	
	[self performOsmRequest: @"/api/0.6/changeset/create" 
				   withBody: strRequestBody 
				  andMethod: @"PUT" 
				  onSuccess: @selector(onChangesetCreateSuccess:withData:) 
					 onFail: @selector(onChangesetCreateFail:withData:)
				 withTicket: nil];
	
	[strRequestBody release];
	
	return TRUE;
}

- (bool) createChangesetWithTicket: (OSMActionTicket*) action
{
	NSString* strRequestBody = [[NSString alloc] initWithFormat:
								@"<osm><changeset>"
								"<tag k=\"created_by\" v=\"%@ %@\"/>"
								//"<tag k=\"comment\" v=\"Just for testing\"/>"
								"</changeset>"
								"</osm>", CREATED_BY_TAG, ZEN_VERSION];
	
	[changesetExpireDate release];
	changesetExpireDate = [[NSDate dateWithTimeIntervalSinceNow: 3600] retain];
	
	ZenLog(@"createChangesetWithTicket: %d", action.action);
	
	[self performOsmRequest: @"/api/0.6/changeset/create" 
				   withBody: strRequestBody 
				  andMethod: @"PUT" 
				  onSuccess: @selector(onChangesetCreateSuccess:withData:) 
					 onFail: @selector(onChangesetCreateFail:withData:)
				 withTicket: (id) action];
	
	[strRequestBody release];
	
	return TRUE;
}


- (void) onChangesetCreateSuccess: (OSMActionTicket*) ticket withData: (NSData*) nodeData
{
	NSString* res = [[NSString alloc] initWithData:nodeData encoding: NSUTF8StringEncoding];
	
	ZenLog(@"onChangesetCreateSuccess: %@", res);
	if(res != nil) 
	{
		ZenLog(@"** Changeset ID: %@", res);
		if( [res integerValue] != 0 || res == @"0" ) {
			self.changeset = res;
						
			if( [delegate respondsToSelector: @selector(OSMChangesetCreated:)]) [delegate OSMChangesetCreated: self];
			
			if(ticket != nil) {
				switch (ticket.action) {
					case OACreateNode:
						[self createNode: (OSMNode2*)ticket.userObject onSuccess: ticket.onSuccess onFail: ticket.onFail target: ticket.target];
						break;
					case OAUpdateNode:
						[self updateNode: (OSMNode2*)ticket.userObject onSuccess: ticket.onSuccess onFail: ticket.onFail target: ticket.target];
						break;
					case OADeleteNode:
						[self deleteNode: (OSMNode2*)ticket.userObject onSuccess: ticket.onSuccess onFail: ticket.onFail target: ticket.target];
						break;
				}
			}
		}
		
		[res release];
	}
}

- (void) onChangesetCreateFail: (OSMActionTicket*) ticket withData:(NSData*) nodeData
{
	@try {
		NSString* res = [[[NSString alloc] initWithData:nodeData encoding: NSUTF8StringEncoding] autorelease];
		ZenLog(@"createChangeset failed: %@", res);
		
		[res release];
		res = 0;
	}
	@catch (NSException * e) {
		ZenLog(@"createChangeset Exception on nodeData: %@", [e reason]);
	}
	@finally {
		[changesetExpireDate release];
		changesetExpireDate = nil;

		ZenLog(@"createChangeset finally try to call delegate");
		if( [delegate respondsToSelector: @selector(OSMChangesetFailed:)]) [delegate OSMChangesetFailed: self];
		
		[ticket performFailSelector];
	}
}

- (bool) closeChangeset
{
	[changesetExpireDate release];
	changesetExpireDate = nil;
	
	if( !changeset || [changeset length] < 1)
	{
		return TRUE;
	}
	
	// PUT /api/0.6/changeset/#id/close
	NSString* request = [[[NSString alloc] initWithFormat:@"/api/0.6/changeset/%@/close", changeset]autorelease];
	[self performOsmRequest: request 
				   withBody: @"<osm></osm>" 
				  andMethod: @"PUT" 
				  onSuccess: nil onFail: nil withTicket: nil];

	changeset = @"";
	
	return TRUE;
}

- (bool) changesetIsValid
{
	return ( [changeset length] > 0 && [changesetExpireDate timeIntervalSinceNow] > 0);
}

#pragma mark nodes

- (bool) createNode: (OSMNode2*) node
{
	[self createNode: node onSuccess: nil onFail:nil target: nil];

	return TRUE;
}

- (void) onOSMNodeCreated: (OSMActionTicket*) ticket withData:(NSData*) nodeData
{
	NSString* res = [[[NSString alloc] initWithData:nodeData encoding: NSUTF8StringEncoding] autorelease];
	ZenLog(@"createNode: node_id=%@", res);
	
	if([res integerValue] != 0 || res == @"0") {
		
		OSMNode2* node = (OSMNode2*) ticket.userObject;
		
		node.osmId = res;
		
		OSMNode2* updatedNode = nil; //TODO: [OSMDataDriver getNodeWithID:res withServer:OSM_DATASERVER];
				
		if(updatedNode != nil) {
			node.osmId = updatedNode.osmId;
			node.timestamp = updatedNode.timestamp;
			node.user = updatedNode.user;
			node.version = updatedNode.version;
						
			if( [delegate respondsToSelector: @selector(OSMNodeCreated:withDriver:)]) [delegate OSMNodeCreated: node withDriver:self];
			
			[ticket performSuccessSelector];
		}
		
		//[updatedNode release];
		
		counterPoiAdded++;
		[self savePoiCounter];
	}
	
	[ticket release];	
}

-(void) onOSMNodeCreateFailed: (OSMActionTicket*) ticket withError: (NSError*) theError
{
	ZenLog(@"OSMNode Create Failed with: %@", [theError localizedDescription]);
	OSMNode2* node = (OSMNode2*) ticket.userObject;
	if( [delegate respondsToSelector: @selector(OSMNodeCreateFailed:withDriver:)]) [delegate OSMNodeCreateFailed: node withDriver: self ];
	
	[ticket performFailSelector];
	[ticket release];
}

- (bool) updateNode: (OSMNode2*) node
{		
	[self updateNode: node onSuccess: nil onFail:nil target: nil];	
	return TRUE;
}


- (void) onNodeUpdateFailed: (OSMActionTicket*) ticket withError: (NSError*) theError
{
	ZenLog(@"OSMNode Update Failed with: %@", [theError localizedDescription]);
	
	OSMNode2* node = (OSMNode2*) ticket.userObject;
	
	if([delegate respondsToSelector: @selector(OSMNodeUpdateFailed:withDriver:)]) [delegate OSMNodeUpdateFailed: node withDriver: self ];
	
	[ticket performFailSelector];
	//[ticket release];
	
}

- (void) onNodeUpdadeSucess: (OSMActionTicket*) ticket withData: (NSData*) result
{
	NSString* res = [[[NSString alloc] initWithData: result encoding:NSUTF8StringEncoding] autorelease];
	
	ZenLog(@"updateNode: %@", res);
	
	if( [res integerValue] != 0 || res == @"0" ) {
		
		OSMNode2* node = (OSMNode2*) ticket.userObject;
		
		node.version = res;
		
		//[OsmNodes setObject:node forKey: node.node_id];
		
		if([delegate respondsToSelector: @selector(OSMNodeUpdated:withDriver:)]) [delegate OSMNodeUpdated: node withDriver: self ];
		
		[ticket performSuccessSelector];
		
		counterPoiEdited++;
		[self savePoiCounter];
	} else {
		[self onNodeUpdateFailed: ticket withError: [NSError errorWithDomain: res code: 0 userInfo:nil]];
	}
	
	//[ticket release];
}

- (bool) deleteNode: (OSMNode2*) node
{
	[self deleteNode:node onSuccess: nil onFail: nil target: nil];
	return TRUE;
}

- (void) onOSMNodeDeleteSuccess: (OSMActionTicket*) tiket withData: (NSData*) nodeData
{	
	counterPoiDeleted++;
	[self savePoiCounter];
	ZenLog(@"deleteNode: OK");
	
	[tiket performSuccessSelector];
}

#pragma mark generic failure delegate [for managing changesets]

- (void) genericFailureProcessor: (OSMActionTicket*) ticket withError: (NSError*) theError
{
	ZenLog(@"OSMDataDriver request failed: %@", [theError localizedDescription]);

	if(theError.code == 419) { //changeset is closed as outdated - we can retry!
		[self closeChangeset];
		[self createChangesetWithTicket: ticket];
	}
	else switch (ticket.action) {
		case OACreateNode:
			[self onOSMNodeCreateFailed: ticket withError: theError];
			break;
		case OAUpdateNode:
			[self onNodeUpdateFailed: ticket withError: theError];
			break;
		case OADeleteNode:
			[ticket performFailSelector];
			break;
			
		default:
			ZenLog(@"Unrecognized Network error: %@", [theError localizedDescription]);
			[ticket performFailSelector];
			break;
	}
}

#pragma mark XTended requests:

- (void) createNode: (OSMNode2*) node onSuccess: (SEL) onSuccess onFail: (SEL) onFail target: (id) target
{
	OSMActionTicket* ticket = [[OSMActionTicket alloc] initWithAction: OACreateNode 
														   withObject: node 
															onSuccess: onSuccess 
															   onFail: onFail 
															forTarget: target];	
	
	if( [self changesetIsValid] ) {
		
		NSString* request = [[[NSString alloc] initWithFormat:@"/api/0.6/node/create"] autorelease];
		
		NSString* nodeXml = [node toOsmXmlWithChangeset: changeset asNewNode: YES];
		
		ZenLog(@"CreateNodeXML: %@", nodeXml);
		
		[self performOsmRequest: request 
					   withBody: nodeXml 
					  andMethod: @"PUT" 
					  onSuccess: @selector(onOSMNodeCreated:withData:) 
						 onFail: @selector(genericFailureProcessor:withError:)
					 withTicket: (id) ticket];
	} else {
		[self createChangesetWithTicket: ticket];
	}
}

- (void) updateNode: (OSMNode2*) node onSuccess: (SEL) onSuccess onFail: (SEL) onFail target: (id) target
{
	OSMActionTicket* ticket = [[OSMActionTicket alloc] initWithAction: OAUpdateNode 
														   withObject: node 
															onSuccess: onSuccess 
															   onFail: onFail 
															forTarget: target];	
		
	if( [self changesetIsValid] ) {
		
		NSString* request = [[[NSString alloc] initWithFormat:@"/api/0.6/node/%@", node.osmId] autorelease];
		
		NSString* nodeXml = [node toOsmXmlWithChangeset: changeset asNewNode: NO];
				
		[self performOsmRequest: request 
					   withBody: nodeXml 
					  andMethod: @"PUT" 
					  onSuccess: @selector(onNodeUpdadeSucess:withData:) 
						 onFail: @selector(genericFailureProcessor:withError:) 
					 withTicket: (id) ticket];
	} else {
		[self createChangesetWithTicket: ticket];
	}
}
- (void) deleteNode: (OSMNode2*) node onSuccess: (SEL) onSuccess onFail: (SEL) onFail target: (id) target
{
	OSMActionTicket* ticket = [[OSMActionTicket alloc] initWithAction: OADeleteNode 
														   withObject: node 
															onSuccess: onSuccess 
															   onFail: onFail 
															forTarget: target];	
	
	if( [self changesetIsValid] ) {
		
		NSString* request = [[[NSString alloc] initWithFormat:@"/api/0.6/node/%@", node.osmId] autorelease];
		
		NSString* nodeXml = [node toOsmXmlWithChangeset: changeset asNewNode: NO];
		
		ZenLog(@"deleteNode: %@", request);
		
		[self performOsmRequest: request 
					   withBody: nodeXml 
					  andMethod: @"DELETE" 
					  onSuccess: @selector(onOSMNodeDeleteSuccess:withData:) 
						 onFail: @selector(genericFailureProcessor:withData:)
					 withTicket: (id) ticket];
	} else {
		[self createChangesetWithTicket: ticket];
	}
	
}
//*/	

/*
#pragma mark Fucking Base64 encoder. Hello apple sdk!
+(NSString*) encodeBase64: (NSString*) dataStr
{
	const static char base64[] =	"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
									"abcdefghijklmnopqrstuvwxyz"
									"0123456789"
									"+/";
	
	NSString* result = nil;
	
	NSData* dataToEncode = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
	
	// "embedded" C code
	//int encode(unsigned s_len, char *src, unsigned d_len, char *dst)
	{
		unsigned s_len =         [dataToEncode length];
		char*    src   = (char*) [dataToEncode bytes];
		
		unsigned d_len = s_len * 2;
		
		if( d_len < 4) d_len = 4; // result output is at least 4 bytes long
								  // due to algorythm specific
		
		char*    dst   = (char*) malloc(d_len);
		
		char*    free_dst_ptr = dst; // we'll use this pointer to free dst memory
		
		memset(dst, 0, d_len);
		
		unsigned triad;
		
		for (triad = 0; triad < s_len; triad += 3)
		{
			unsigned long int sr;
			unsigned byte;
			
			for (byte = 0; (byte<3)&&(triad+byte<s_len); ++byte)
			{
				sr <<= 8;
				sr |= (*(src+triad+byte) & 0xff);
			}
			
			sr <<= (6-((8*byte)%6))%6; // shift left to next 6bit alignment
			
			// if (d_len < 4) // return 1; // error - dest too short
			
			*(dst+0) = *(dst+1) = *(dst+2) = *(dst+3) = '=';
			switch(byte)
			{
				case 3:
					*(dst+3) = base64[sr&0x3f];
					sr >>= 6;
				case 2:
					*(dst+2) = base64[sr&0x3f];
					sr >>= 6;
				case 1:
					*(dst+1) = base64[sr&0x3f];
					sr >>= 6;
					*(dst+0) = base64[sr&0x3f];
			}
			dst += 4; d_len -= 4;
		}
		
		// here should be "return 0"
		// but we pack result into NSString ;)
		
		result = [NSString stringWithCString: free_dst_ptr length:strlen(free_dst_ptr)];
		
		free(free_dst_ptr);
	}// end of "embedded method"
	
	return result;
}

*/
@end

