//
//  LAFIDENotificationHandler.m
//  AutoImporter
//
//  Created by Luis Floreani on 10/1/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFIDENotificationHandler.h"
#import "LAFProjectsInspector.h"
#import "XCFXcodePrivate.h"

@implementation LAFIDENotificationHandler

+ (instancetype)sharedHandler {
    static LAFIDENotificationHandler *_sharedInstance;
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
        // initiate project inspector
        [LAFProjectsInspector sharedInspector];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
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
        
    }
    return self;
}

- (void)fileDidSave:(NSNotification *)notification {
    NSString *path = [[[notification object] fileURL] path];
    if ([path hasSuffix:@".h"]) {
        [[LAFProjectsInspector sharedInspector] updateHeader:path];
    }
}

- (void)projectDidChange:(NSNotification *)notification {
    NSString *filePath = [self filePathForProjectFromNotification:notification];
    
    if (filePath) {
        [[LAFProjectsInspector sharedInspector] updateProject:filePath doneBlock:nil];
    }
}

- (void)projectDidClose:(NSNotification *)notification {
    NSString *filePath = [self filePathForProjectFromNotification:notification];

    if (filePath) {
        [[LAFProjectsInspector sharedInspector] closeProject:filePath];
    }
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
