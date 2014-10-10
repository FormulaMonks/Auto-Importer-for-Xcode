//
//  NSColor+MyColor.h
//  AutoImporterTestProject1
//
//  Created by Luis Floreani on 9/11/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (MyColor)

- (NSColor *) laf_redColor;

- (NSColor *)laf_greenColor ;

// a line comment
- (NSColor *)laf_filterColor:(NSColor *)color;

/*
 * multiline comment
 */
- (NSColor *)laf_filterColor :(NSColor *)color offset:(CGFloat)offset;

- (NSColor *)laf_filterColor2: (NSColor *)color offset:(CGFloat)offset;

- (NSColor *)laf_filterColor3:(NSColor *) color offset:(CGFloat)offset;

@end
