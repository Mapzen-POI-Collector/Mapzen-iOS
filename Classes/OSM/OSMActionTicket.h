//
//  OSMActionTicket.h
//  Mapzen
//
//  Created by CloudMade Inc. on 9/29/09.
//  Copyright 2009 CloudMade. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OSMNode;

enum OSMAction {
	OACreateChangest,
	OACloseChangest,
	OACreateNode,
	OAUpdateNode,
	OADeleteNode,
	OAGenericAction
};

@interface OSMActionTicket : NSObject {
	NSObject* userObject;
	NSInteger action;
	SEL		  onSuccess;
	SEL		  onFail;
	id		  target;
}

@property (nonatomic, retain)      NSObject* userObject;
@property (nonatomic, assign)   NSInteger action;
@property (nonatomic, readwrite)   SEL onSuccess;
@property (nonatomic, readwrite)   SEL onFail;
@property (nonatomic, assign)   id  target;

- (id) initWithAction: (enum OSMAction) osmAction 
		   withObject: (NSObject*) object 
			onSuccess: (SEL) success 
			   onFail: (SEL) fail 
			forTarget: (id) theTarget;

- (id) initWithAction: (enum OSMAction) osmAction 
			andObject: (NSObject*) object;

- (void) performSuccessSelector;
- (void) performFailSelector;


@end
