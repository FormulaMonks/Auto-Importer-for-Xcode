//
//  NSTextView+Operations.m
//  MHImportBuster
//
//  Created by Marko Hlebar on 05/05/2014.
//  Copyright (c) 2014 Marko Hlebar. All rights reserved.
//

#import "NSTextView+Operations.h"

@implementation NSTextView (Operations)
- (NSRect) mhFrameForCaret {
    NSArray *selectedRanges = self.selectedRanges;
    if (selectedRanges.count > 0) {
        NSRange selectedRange = [[self.selectedRanges objectAtIndex:0] rangeValue];
        NSRect keyRectOnScreen = [self firstRectForCharacterRange:selectedRange];
        NSRect keyRectOnWindow = [self.window convertRectFromScreen:keyRectOnScreen];
        NSRect keyRectOnTextView = [self convertRect:keyRectOnWindow fromView:nil];
        keyRectOnTextView.size.width = 1;
        return keyRectOnTextView;
    }
    return NSZeroRect;
}

@end
