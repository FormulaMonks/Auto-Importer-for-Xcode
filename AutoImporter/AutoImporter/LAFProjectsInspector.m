//
//  LAFProjectsInspector.m
//  AutoImporter
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFProjectsInspector.h"
#import "XCFXcodePrivate.h"
#import "NSTextView+Operations.h"
#import "LAFProjectHeaderCache.h"
#import "LAFImportListViewController.h"
#import "LAFIDESourceCodeEditor.h"
#import "LAFIdentifier.h"

@interface LAFProjectsInspector () <LAFImportListViewControllerDelegate>
@property (nonatomic, strong) NSMapTable *projectsByWorkspace;
@property (nonatomic, strong) LAFIDESourceCodeEditor *editor;
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
        
        _editor = [[LAFIDESourceCodeEditor alloc] init];

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver:self selector:@selector(importAction:)
                                                     name:@"LAFShowHeaders"
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
//    LAFLog(@"  Notification: %@", [notification name]);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)updateHeader:(NSString *)headerPath {
    for (LAFProjectHeaderCache *headers in [self projectsInCurrentWorkspace]) {
        if ([headers containsHeader:headerPath]) {
            [headers refreshHeader:headerPath];
            return YES;
        }
    }
    
    return NO;
}

- (void)updateProject:(NSString *)projectPath doneBlock:(dispatch_block_t)doneBlock {
    NSAssert([self currentWorkspace], @"workspace can't be nil");
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:projectPath]) {
        LAFLog(@"project path not found %@", projectPath);
        
        if (doneBlock) {
            doneBlock();
        }

        return;
    }
    
    LAFProjectHeaderCache *projectCache = nil;
    for (LAFProjectHeaderCache *cache in [self projectsInCurrentWorkspace]) {
        if ([cache.filePath isEqualToString:projectPath]) {
            projectCache = cache;
            break;
        }
    }
    
    if (!projectCache) {
        LAFLog(@"creating project %@ for workspace %@", [projectPath lastPathComponent], [[self currentWorkspace] lastPathComponent]);
        
        projectCache = [[LAFProjectHeaderCache alloc] initWithProjectPath:projectPath];
        [[self projectsInCurrentWorkspace] addObject:projectCache];
    }
    
    _loading = YES;
    [projectCache refresh:^{
        _loading = NO;
        
        if (doneBlock) {
            doneBlock();
        }
    }];
}

- (void)closeProject:(NSString *)projectPath {
    LAFProjectHeaderCache *toRemove = nil;
    NSMutableArray *projects = [self projectsInCurrentWorkspace];
    for (LAFProjectHeaderCache *headers in projects) {
        if ([headers.filePath isEqualToString:projectPath]) {
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

- (NSString *)currentWorkspace {
    return @"workspace";
// this code below is not working if tried a few moments after opening xcode
//    NSString *workspacePath = [MHXcodeDocumentNavigator currentWorkspacePath];
//    return workspacePath;
}

- (LAFImportResult)importIdentifier:(NSString *)identifier headerOut:(NSMutableString *)headerOut {
    for (LAFProjectHeaderCache *headers in [self projectsInCurrentWorkspace]) {
        NSString *header = [headers headerForIdentifier:identifier];
        if (header) {
            [headerOut appendString:header];
            
            return [_editor importHeader:header];
        }
    }

    [headerOut appendString:identifier];
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
            text = [NSString stringWithFormat:@"Identifier '%@' not found", item];
            color = [NSColor colorWithRed:1.0 green:0.8 blue:0.8 alpha:1.0];
            break;
        case LAFImportResultDone:
            text = [NSString stringWithFormat:@"Header '%@' added!", item];
            color = [NSColor colorWithRed:0.8 green:1.0 blue:0.8 alpha:1.0];
            break;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_editor showAboveCaret:text color:color];
    });
}

- (void)importAction:(NSNotification *)notif {
    NSString *selection = [_editor selectedText];
    if (_loading) {
        NSString *text = [NSString stringWithFormat:@"Indexing headers, please try later..."];
        NSColor *color = [NSColor colorWithRed:0.7 green:0.8 blue:1.0 alpha:1.0];
        [_editor showAboveCaret:text color:color];
    } else if (selection.length > 0) {
        NSMutableString *headerOut = [NSMutableString string];
        LAFImportResult result = [self importIdentifier:selection headerOut:headerOut];
        if (result != LAFImportResultNotFound) {
            [self showCaretTextBasedOn:result item:headerOut];
        } else {
            [self showImportList:selection];
        }
    } else {
        [self showImportList:nil];
    }
}

- (void)showImportList:(NSString *)searchString {
    NSMutableArray *items = [NSMutableArray array];
    NSArray *projects = [self projectsInCurrentWorkspace];
    NSMutableSet *alreadyImported = [NSMutableSet set];
    
    [_editor cacheImports];
    for (LAFProjectHeaderCache *project in projects) {
        NSArray *identifiers = [[project identifiers] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *headers = [[project headers] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [items addObjectsFromArray:identifiers];
        [items addObjectsFromArray:headers];
        
        for (LAFIdentifier *identifier in identifiers) {
            if ([_editor hasImportedHeader:[project headerForIdentifier:identifier.name]]) {
                [alreadyImported addObject:identifier];
            }
        }
        for (LAFIdentifier *identifier in headers) {
            if ([_editor hasImportedHeader:identifier.name]) {
                [alreadyImported addObject:identifier];
            }
        }
    }
    [_editor invalidateImportsCache];
    
    [LAFImportListViewController sharedInstance].delegate = self;
    [LAFImportListViewController presentInView:[_editor view] items:items alreadyImported:alreadyImported searchText:searchString];
}


#pragma mark - LAFImportListViewControllerDelegate

- (void)itemSelected:(NSString *)item {
    LAFImportResult result = 0;
    if ([item hasSuffix:@".h"]) {
        result = [_editor importHeader:item];
        [self showCaretTextBasedOn:result item:item];
    } else {
        // insert text
        [_editor insertOnCaret:item];

        // notify
        NSMutableString *headerOut = [NSMutableString string];
        result = [self importIdentifier:item headerOut:headerOut];
        [self showCaretTextBasedOn:result item:headerOut];
    }
}


@end
