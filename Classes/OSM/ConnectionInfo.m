//
//  ConnectionInfo.m
//  Mapzen
//
//  Created by CloudMade Inc. on 9/30/09.
//  Copyright 2009 CloudMade. All rights reserved.
//

#import "ConnectionInfo.h"


@implementation ConnectionInfo
@synthesize onSuccess, onFail, target, userData, receivedData;

- (id) initWithTarget: (id) theTarget onSuccess: (SEL) success onFail: (SEL) fail withUserData: (id) data
{
	[super init];
	self.onSuccess = success;
	self.onFail = fail;
	self.target = theTarget;
	self.userData = data;
	self.receivedData = [[NSMutableData alloc] init];
	return self;
}

@end
