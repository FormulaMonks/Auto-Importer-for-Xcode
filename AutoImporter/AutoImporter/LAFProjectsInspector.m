//
//  LAFProjectsInspector.m
//  AutoImporter
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFProjectsInspector.h"
#import "XCFXcodePrivate.h"
#import "MHXcodeDocumentNavigator.h"
#import "DVTSourceTextStorage+Operations.h"
#import "NSString+Extensions.h"
#import "LAFProjectHeaderCache.h"

NSString * const LAFAddImportOperationImportRegexPattern = @"^#.*(import|include).*[\",<].*[\",>]";

@interface LAFProjectsInspector ()
@property (nonatomic, strong) NSMutableArray *projectHeaders;
@property BOOL loading;
@end

@implementation LAFProjectsInspector

+ (instancetype)sharedInspector {
    static LAFProjectsInspector *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _projectHeaders = [NSMutableArray new];

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver:self selector:@selector(importAction:)
                                                     name:@"LAFShowHeaders"
                                                   object:nil];

        [notificationCenter addObserver:self
                               selector:@selector(projectDidChange:)
                                   name:@"PBXProjectDidOpenNotification"
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(projectDidChange:)
                                   name:@"PBXProjectDidChangeNotification"
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(projectDidClose:)
                                   name:@"PBXProjectDidCloseNotification"
                                 object:nil];

        [notificationCenter addObserver:self
                               selector:@selector(fileDidSave:)
                                   name:@"IDEEditorDocumentDidSaveNotification"
                                 object:nil];

//        [notificationCenter addObserver:self
//                               selector:@selector(fileDidChange:)
//                                   name:@"IDEEditorDocumentWillCloseNotification"
//                                 object:nil];
//
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationListener:) name:nil object:nil];

    }
    return self;
}

-(void)notificationListener:(NSNotification *)notification {
//    NSLog(@"  Notification: %@", [notification name]);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)fileDidSave:(NSNotification *)notification {
    NSLog(@"saved file on workspace %@", [self currentWorkspace]);
    NSString *changedFileAbsoluteString = [[[notification object] fileURL] absoluteString];
    if ([changedFileAbsoluteString hasSuffix:@".h"]) {
        NSLog(@"%@", changedFileAbsoluteString);
    }
}


- (void)projectDidClose:(NSNotification *)notification {
    NSString *path = [self filePathForProjectFromNotification:notification];
    LAFProjectHeaderCache *toRemove = nil;
    for (LAFProjectHeaderCache *headers in _projectHeaders) {
        if ([headers.filePath isEqualToString:path]) {
            toRemove = headers;
            break;
        }
    }
    
    if (toRemove) {
        [_projectHeaders removeObject:toRemove];
    }
}

- (void)projectDidChange:(NSNotification *)notification {
    NSString *filePath = [self filePathForProjectFromNotification:notification];

    if (filePath) {
        //TODO: This is a temporary solution which works. When opening .xcodeproj
        //files, it seems that the notification order is differrent and we can't find
        //the current workspace. Find out which notification gets fired after opening
        //.xcodeproj and act after that perhaps...
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSLog(@"project %@ changed on workspace %@", filePath, [self currentWorkspace]);

            [self updateProjectWithPath:filePath];
        });
    }
}

- (NSString *)currentWorkspace {
    NSString *workspacePath = [MHXcodeDocumentNavigator currentWorkspacePath];
    return workspacePath;
}

- (void)updateProjectWithPath:(NSString *)path {
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"project path not found %@", path);
        return;
    }
    
    _loading = YES;
    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:path];
    [headers refresh:^{
        [_projectHeaders addObject:headers];
        _loading = NO;
    }];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

- (NSString *)filePathForProjectFromNotification:(NSNotification *)notification {
    if ([notification.object respondsToSelector:@selector(projectFilePath)]) {
        NSString *pbxProjPath = [notification.object performSelector:@selector(projectFilePath)];
        return [pbxProjPath stringByDeletingLastPathComponent];
    }
    return nil;
}

#pragma clang diagnostic pop

- (void)importAction:(NSNotification *)notif {
    NSTextView *currentTextView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    NSRange range = currentTextView.selectedRange;
    NSString *text = nil;
    NSColor *color = nil;
    if (_loading) {
        text = [NSString stringWithFormat:@"Indexing headers, please try later..."];
        color = [NSColor colorWithRed:0.7 green:0.8 blue:1.0 alpha:1.0];
    } else if (range.length > 0) {
        NSString *selection = [[currentTextView string] substringWithRange:range];
        for (LAFProjectHeaderCache *headers in _projectHeaders) {
            NSString *header = [headers headerForSymbol:selection];
            if (header) {
                BOOL already = [self addImport:[NSString stringWithFormat:@"#import \"%@\"", header]];
                if (already) {
                    text = [NSString stringWithFormat:@"Header '%@' already added", header];
                    color = [NSColor colorWithRed:1.0 green:1.0 blue:0.8 alpha:1.0];
                } else {
                    text = [NSString stringWithFormat:@"Header '%@' added!", header];
                    color = [NSColor colorWithRed:0.8 green:1.0 blue:0.8 alpha:1.0];
                }
                break;
            } else {
                text = [NSString stringWithFormat:@"Symbol '%@' not found", selection];
                color = [NSColor colorWithRed:1.0 green:0.8 blue:0.8 alpha:1.0];
            }
        }
    } else {
        text = [NSString stringWithFormat:@"No text selection"];
        color = [NSColor colorWithCalibratedWhite:0.95 alpha:1.0];
    }
    
    if (text) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self displayAboveCaretText:text color:color];
        });
    }
}

- (void)displayAboveCaretText:(NSString *)text color:(NSColor *)color {
    NSTextView *currentTextView = [MHXcodeDocumentNavigator currentSourceCodeTextView];

    NSRange selectedRange = [[currentTextView.selectedRanges objectAtIndex:0] rangeValue];
    NSRect keyRectOnScreen = [currentTextView firstRectForCharacterRange:selectedRange];
    NSRect keyRectOnWindow = [currentTextView.window convertRectFromScreen:keyRectOnScreen];
    NSRect keyRectOnTextView = [currentTextView convertRect:keyRectOnWindow fromView:nil];
    keyRectOnTextView.size.width = 1;
    
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

- (BOOL)addImport:(NSString *)statement {
    DVTSourceTextStorage *textStorage = [self currentTextStorage];
    BOOL duplicate = NO;
    NSInteger lastLine = [self appropriateLine:textStorage statement:statement duplicate:&duplicate];
    
    if (lastLine != NSNotFound) {
        NSString *importString = [NSString stringWithFormat:@"%@\n", statement];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [textStorage mhInsertString:importString
                                 atLine:lastLine+1];
        });
    }
    
    return duplicate;
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
    NSInteger numberOfMatches = [regex numberOfMatchesInString:string
                                                       options:0
                                                         range:NSMakeRange(0, string.length)];
    return numberOfMatches > 0;
}

@end
