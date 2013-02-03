//
//  ConnectionInfo.h
//  Mapzen
//
//  Created by CloudMade Inc. on 9/30/09.
//  Copyright 2009 CloudMade. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ConnectionInfo : NSObject {
	SEL onSuccess;
	SEL onFail;
	id  target;
	id  userData;
	NSMutableData* receivedData;
}

@property (nonatomic, readwrite) SEL onSuccess;
@property (nonatomic, readwrite) SEL onFail;
@property (nonatomic, retain) id target;
@property (nonatomic, retain) id userData;
@property (nonatomic, retain) NSMutableData* receivedData;

- (id) initWithTarget: (id) theTarget onSuccess: (SEL) success onFail: (SEL) fail withUserData: (id) data;

@end
