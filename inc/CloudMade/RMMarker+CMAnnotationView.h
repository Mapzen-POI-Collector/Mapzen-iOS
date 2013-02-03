//
//  RMMarker+CMAnnotationView.h
//  CloudMadeApi
//
//  Created by Dmytro Golub on 3/10/10.
//  Copyright 2010 CloudMade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMMarker.h"


//! The RMMarker extension for an annotation view  
@interface RMMarker (AnnotationExtensions)
/**
 *  Adds annotation view to a marker. 	
 *  @param title for an annotation view
 * \note
 * An annotation view will appear at coordinate (0.5,1) relatively the marker anchor point.
 */
-(void) addAnnotationViewWithTitle:(NSString*) title;
/**
 *  Adds annotation view to a marker in given anchor point. 	
 *  @param title for an annotation view
 *  @param point anchor point for an annotation view
 */
-(void) addAnnotationViewWithTitle:(NSString*) title atPoint:(CGPoint) point; 
@end
