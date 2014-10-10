//
//  NSColor+MyColor.m
//  AutoImporterTestProject1
//
//  Created by Luis Floreani on 9/11/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "NSColor+MyColor.h"

@implementation NSColor (MyColor)

- (NSColor *)laf_redColor {
    return [NSColor redColor];
}

- (NSColor *)laf_greenColor {
    return [NSColor greenColor];
}

- (NSColor *)laf_filterColor:(NSColor *)color {
    return color;
}

- (NSColor *)laf_filterColor:(NSColor *)color offset:(CGFloat)offset {
    return color;
}

@end
