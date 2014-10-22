//
//  LAFIDESourceCodeEditor.m
//  AutoImporter
//
//  Created by Luis Floreani on 10/2/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFIDESourceCodeEditor.h"
#import "MHXcodeDocumentNavigator.h"
#import "DVTSourceTextStorage+Operations.h"
#import "NSTextView+Operations.h"
#import "NSString+Extensions.h"

NSString * const LAFAddImportOperationImportRegexPattern = @"^#.*(import|include).*[\",<].*[\",>]";

@interface LAFIDESourceCodeEditor()

@property (nonatomic, strong) NSMutableSet *importedCache;

@end

@implementation LAFIDESourceCodeEditor

- (NSString *)importStatementFor:(NSString *)header {
    return [NSString stringWithFormat:@"#import \"%@\"", header];
}

- (void)cacheImports {
    [self invalidateImportsCache];
    
    if (!_importedCache) {
        _importedCache = [NSMutableSet set];
    }
    
    DVTSourceTextStorage *textStorage = [self currentTextStorage];
    [textStorage.string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        if ([self isImportString:line]) {
            [_importedCache addObject:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
    }];
}

- (void)invalidateImportsCache {
    [_importedCache removeAllObjects];
}

- (LAFImportResult)importHeader:(NSString *)header {
    return [self addImport:[self importStatementFor:header]];
}

- (BOOL)hasImportedHeader:(NSString *)header {
    return [_importedCache containsObject:[self importStatementFor:header]];
}

- (NSView *)view {
    return [MHXcodeDocumentNavigator currentSourceCodeTextView];
}

- (NSString *)selectedText {
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    NSRange range = textView.selectedRange;
    return [[textView string] substringWithRange:range];
}

- (void)insertOnCaret:(NSString *)text {
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    NSRange range = textView.selectedRange;
    [textView insertText:text replacementRange:range];
}

- (void)showAboveCaret:(NSString *)text color:(NSColor *)color {
    NSTextView *currentTextView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    
    NSRect keyRectOnTextView = [currentTextView mhFrameForCaret];
    
    NSTextField *field = [[NSTextField alloc] initWithFrame:CGRectMake(keyRectOnTextView.origin.x, keyRectOnTextView.origin.y, 0, 0)];
    [field setBackgroundColor:color];
    [field setFont:currentTextView.font];
    [field setTextColor:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]];
    [field setStringValue:text];
    [field sizeToFit];
    [field setBordered:NO];
    [field setEditable:NO];
    field.frame = CGRectOffset(field.frame, 0, - field.bounds.size.height - 3);
    
    [currentTextView addSubview:field];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setCompletionHandler:^{
            [field removeFromSuperview];
        }];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[field animator] setAlphaValue:0.0];
        [NSAnimationContext endGrouping];
    });
}

- (DVTSourceTextStorage *)currentTextStorage {
    if (![[MHXcodeDocumentNavigator currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return nil;
    }
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    return (DVTSourceTextStorage*)textView.textStorage;
}

- (LAFImportResult)addImport:(NSString *)statement {
    BOOL duplicate = NO;
    DVTSourceTextStorage *textStorage = [self currentTextStorage];
    NSInteger lastLine = [self appropriateLine:textStorage statement:statement duplicate:&duplicate];
    
    if (lastLine != NSNotFound) {
        NSString *importString = [NSString stringWithFormat:@"%@\n", statement];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [textStorage mhInsertString:importString
                                 atLine:lastLine+1];
        });
    }
    
    if (duplicate) {
        return LAFImportResultAlready;
    } else {
        return LAFImportResultDone;
    }
}

- (NSUInteger)appropriateLine:(DVTSourceTextStorage *)source statement:(NSString *)statement duplicate:(BOOL *)duplicate {
    __block NSUInteger lineNumber = NSNotFound;
    __block NSUInteger currentLineNumber = 0;
    __block BOOL foundDuplicate = NO;
    [source.string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        if ([self isImportString:line]) {
            if ([line isEqual:statement]) {
                foundDuplicate = YES;
                *stop = YES;
                return;
            }
            lineNumber = currentLineNumber;
        }
        currentLineNumber++;
    }];
    
    if (foundDuplicate) {
        *duplicate = YES;
        return NSNotFound;
    }
    
    //if no imports are present find the first new line.
    if (lineNumber == NSNotFound) {
        currentLineNumber = 0;
        [source.string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            if (![line mh_isWhitespaceOrNewline]) {
                currentLineNumber++;
            }
            else {
                lineNumber = currentLineNumber;
                *stop = YES;
            }
        }];
    }
    
    return lineNumber;
}

- (NSRegularExpression *)importRegex {
    static NSRegularExpression *_regex = nil;
    if (!_regex) {
        NSError *error = nil;
        _regex = [[NSRegularExpression alloc] initWithPattern:LAFAddImportOperationImportRegexPattern
                                                      options:0
                                                        error:&error];
    }
    return _regex;
}

- (BOOL)isImportString:(NSString *)string {
    NSRegularExpression *regex = [self importRegex];
    NSInteger numberOfMatches = [regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)];
    return numberOfMatches > 0;
}

@end
