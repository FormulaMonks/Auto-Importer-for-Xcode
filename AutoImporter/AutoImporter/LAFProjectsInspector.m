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
#import "NSTextView+Operations.h"
#import "NSString+Extensions.h"
#import "LAFProjectHeaderCache.h"
#import "LAFImportListViewController.h"

typedef enum {
    LAFImportResultAlready,
    LAFImportResultNotFound,
    LAFImportResultDone,
} LAFImportResult;

NSString * const LAFAddImportOperationImportRegexPattern = @"^#.*(import|include).*[\",<].*[\",>]";

@interface LAFProjectsInspector () <LAFImportListViewControllerDelegate>
@property (nonatomic, strong) NSMapTable *projectsByWorkspace;
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
        _projectsByWorkspace = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                valueOptions:NSPointerFunctionsStrongMemory];

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
    NSString *path = [[[notification object] fileURL] path];
    if ([path hasSuffix:@".h"]) {
        for (LAFProjectHeaderCache *headers in [self projectsInCurrentWorkspace]) {
            if ([headers containsHeader:path]) {
                [headers refreshHeader:path];                
            }
        }
    }
}

- (void)projectDidClose:(NSNotification *)notification {
    NSString *path = [self filePathForProjectFromNotification:notification];
    LAFProjectHeaderCache *toRemove = nil;
    NSMutableArray *projects = [self projectsInCurrentWorkspace];
    for (LAFProjectHeaderCache *headers in projects) {
        if ([headers.filePath isEqualToString:path]) {
            toRemove = headers;
            break;
        }
    }
    
    if (toRemove) {
        [projects removeObject:toRemove];
    }
}

- (NSMutableArray *)projectsInCurrentWorkspace {
    NSMutableArray *projects = [_projectsByWorkspace objectForKey:[self currentWorkspace]];
    if (!projects) {
        projects = [NSMutableArray array];
        [_projectsByWorkspace setObject:projects forKey:[self currentWorkspace]];
    }
    
    return projects;
}

- (void)projectDidChange:(NSNotification *)notification {
    NSString *filePath = [self filePathForProjectFromNotification:notification];

    if (filePath) {
        [self updateProjectWithPath:filePath];
    }
}

- (NSString *)currentWorkspace {
    return @"workspace";
// this code below is not working if tried a few moments after opening xcode
//    NSString *workspacePath = [MHXcodeDocumentNavigator currentWorkspacePath];
//    return workspacePath;
}

- (void)updateProjectWithPath:(NSString *)path {
    NSAssert([self currentWorkspace], @"workspace can't be nil");
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"project path not found %@", path);
        return;
    }
    
    LAFProjectHeaderCache *projectCache = nil;
    for (LAFProjectHeaderCache *cache in [self projectsInCurrentWorkspace]) {
        if ([cache.filePath isEqualToString:path]) {
            projectCache = cache;
            break;
        }
    }
    
    if (!projectCache) {
        NSLog(@"creating project %@ for workspace %@", [path lastPathComponent], [[self currentWorkspace] lastPathComponent]);

        projectCache = [[LAFProjectHeaderCache alloc] initWithProjectPath:path];
        [[self projectsInCurrentWorkspace] addObject:projectCache];
    }
    
    _loading = YES;
    [projectCache refresh:^{
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

- (LAFImportResult)importHeader:(NSString *)header {
    return [self addImport:[NSString stringWithFormat:@"#import \"%@\"", header]];
}

- (LAFImportResult)importSymbol:(NSString *)symbol headerOut:(NSMutableString *)headerOut {
    for (LAFProjectHeaderCache *headers in [self projectsInCurrentWorkspace]) {
        NSString *header = [headers headerForSymbol:symbol];
        if (header) {
            [headerOut appendString:header];
            
            return [self importHeader:header];
        }
    }

    [headerOut appendString:symbol];
    return LAFImportResultNotFound;
}

- (void)showCaretTextBasedOn:(LAFImportResult)result item:(NSString *)item {
    NSString *text = nil;
    NSColor *color = nil;

    switch (result) {
        case LAFImportResultAlready:
            text = [NSString stringWithFormat:@"Header '%@' already added", item];
            color = [NSColor colorWithRed:1.0 green:1.0 blue:0.8 alpha:1.0];
            break;
        case LAFImportResultNotFound:
            text = [NSString stringWithFormat:@"Symbol '%@' not found", item];
            color = [NSColor colorWithRed:1.0 green:0.8 blue:0.8 alpha:1.0];
            break;
        case LAFImportResultDone:
            text = [NSString stringWithFormat:@"Header '%@' added!", item];
            color = [NSColor colorWithRed:0.8 green:1.0 blue:0.8 alpha:1.0];
            break;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self displayAboveCaretText:text color:color];
    });
}

- (void)importAction:(NSNotification *)notif {
    NSTextView *currentTextView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    NSRange range = currentTextView.selectedRange;
    if (_loading) {
        NSString *text = [NSString stringWithFormat:@"Indexing headers, please try later..."];
        NSColor *color = [NSColor colorWithRed:0.7 green:0.8 blue:1.0 alpha:1.0];
        [self displayAboveCaretText:text color:color];
    } else if (range.length > 0) {
        NSString *selection = [[currentTextView string] substringWithRange:range];
        NSMutableString *headerOut = [NSMutableString string];
        LAFImportResult result = [self importSymbol:selection headerOut:headerOut];
        [self showCaretTextBasedOn:result item:headerOut];
    } else {
        NSMutableArray *items = [NSMutableArray array];
        NSArray *projects = [self projectsInCurrentWorkspace];
        for (LAFProjectHeaderCache *project in projects) {
            [items addObjectsFromArray:[[project symbols] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
            [items addObjectsFromArray:[[project headers] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
        }
        
        [LAFImportListViewController sharedInstance].delegate = self;
        [LAFImportListViewController presentInView:currentTextView items:items];
    }
}

- (void)displayAboveCaretText:(NSString *)text color:(NSColor *)color {
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
    NSInteger numberOfMatches = [regex numberOfMatchesInString:string
                                                       options:0
                                                         range:NSMakeRange(0, string.length)];
    return numberOfMatches > 0;
}

#pragma mark - LAFImportListViewControllerDelegate

- (void)itemSelected:(NSString *)item {
    LAFImportResult result = 0;
    if ([item hasSuffix:@".h"]) {
        result = [self importHeader:item];
        [self showCaretTextBasedOn:result item:item];
    } else {
        NSMutableString *headerOut = [NSMutableString string];
        result = [self importSymbol:item headerOut:headerOut];
        [self showCaretTextBasedOn:result item:headerOut];
    }
}


@end
