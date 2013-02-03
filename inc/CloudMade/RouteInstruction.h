//
//  RouteInstruction.h
//  NavigationView
//
//  Created by Dmytro Golub on 4/11/09.
//  Copyright 2009 Cloudmade. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Class presents route instructions  
@interface RouteInstruction : NSObject
{
	NSString* instruction; /**< Instruction */
	NSString* distance;    /**< Distance */
}

@property (nonatomic,retain) 	NSString* instruction;
@property (nonatomic,retain) 	NSString* distance;

@end
