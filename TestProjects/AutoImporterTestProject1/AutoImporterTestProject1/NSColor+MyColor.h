//
//  NSColor+MyColor.h
//  AutoImporterTestProject1
//
//  Created by Luis Floreani on 9/11/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (MyColor)

- (NSColor *)laf_redColor;
- (NSColor *)laf_greenColor;
- (NSColor *)laf_filterColor:(NSColor *)color;
- (NSColor *)laf_filterColor:(NSColor *)color offset:(CGFloat)offset;

@end
