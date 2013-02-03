//
//  OSMActionTicket.m
//  Mapzen
//
//  Created by CloudMade Inc. on 9/29/09.
//  Copyright 2009 CloudMade. All rights reserved.
//

#import "OSMActionTicket.h"


@implementation OSMActionTicket
@synthesize userObject, action, onSuccess, onFail, target;

- (id) initWithAction: (enum OSMAction) osmAction 
		   withObject: (NSObject*) object 
			onSuccess: (SEL) success 
			   onFail: (SEL) fail 
			forTarget: (id) theTarget 
{
	[super init];
	
	self.userObject = object;
	self.action = osmAction;
	self.onSuccess = success;
	self.onFail = fail;
	self.target = theTarget;
	
	return self;
}

- (id) initWithAction: (enum OSMAction) osmAction 
			andObject: (NSObject*) object
{
	[super init];
	
	self.userObject = object;
	self.action = osmAction;
	
	return self;
}



- (void) performFailSelector
{
	if(target && onFail) {
		ZenLog(@"OSMActionTicket: Performing Fail Selector...");
		[target performSelector: onFail withObject: userObject];
	}
}
- (void) performSuccessSelector
{
	if(target && onSuccess) {
		ZenLog(@"OSMActionTicket: Performing Success Selector...");
		[target performSelector: onSuccess withObject: userObject];
	}
}


@end
