//
//  LAFAutoImporter.m
//  LAFAutoImporter
//
//  Created by Luis Floreani on 9/10/14.
//    Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFAutoImporter.h"
#import "XCProject.h"
#import "XCFXcodePrivate.h"
#import "XCWorkspace.h"
#import "MHXcodeDocumentNavigator.h"

static LAFAutoImporter *sharedPlugin;

@interface LAFAutoImporter()
@property (nonatomic, strong) NSMutableDictionary *workspaceCacheDictionary;
@property (nonatomic, strong) NSBundle *bundle;
@end

@implementation LAFAutoImporter

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        _workspaceCacheDictionary = [NSMutableDictionary new];

        // reference to plugin's bundle, for resource acccess
        self.bundle = plugin;
        
        // Create menu items, initialize UI, etc.

        // Sample Menu Item:
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"File"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Do Auto Importer Action" action:@selector(doMenuAction) keyEquivalent:@""];
            [actionMenuItem setTarget:self];
            [[menuItem submenu] addItem:actionMenuItem];
        }
        
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

        [notificationCenter addObserver:self
                               selector:@selector(projectDidChange:)
                                   name:@"PBXProjectDidOpenNotification"
                                 object:nil];

        [notificationCenter addObserver:self
                               selector:@selector(projectDidChange:)
                                   name:@"PBXProjectDidChangeNotification"
                                 object:nil];

    }
    return self;
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

- (void)projectDidChange:(NSNotification *)notification {
    NSString *filePath = [self filePathForProjectFromNotification:notification];
    if (filePath) {
        
        //TODO: This is a temporary solution which works. When opening .xcodeproj
        //files, it seems that the notification order is differrent and we can't find
        //the current workspace. Find out which notification gets fired after opening
        //.xcodeproj and act after that perhaps...
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateProjectWithPath:filePath];
        });
    }
}

+ (IDEWorkspaceDocument *)currentWorkspaceDocument {
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
    id document = [currentWindowController document];
    if (currentWindowController && [document isKindOfClass:NSClassFromString(@"IDEWorkspaceDocument")]) {
        return (IDEWorkspaceDocument *)document;
    }
    return nil;
}

+ (NSString *)currentWorkspacePath {
    IDEWorkspaceDocument *document = [MHXcodeDocumentNavigator currentWorkspaceDocument];
    return [[document fileURL] path];
}

- (XCWorkspace *)currentWorkspace {
    NSString *workspacePath = [MHXcodeDocumentNavigator currentWorkspacePath];
    if (!workspacePath) return nil;
    return [self workspaceWithPath:workspacePath];
}

- (XCWorkspace *)workspaceWithPath:(NSString *)workspacePath {
    XCWorkspace *workspace = self.workspaceCacheDictionary[workspacePath];
    if (!workspace) {
        workspace = [XCWorkspace workspaceWithFilePath:workspacePath];
        self.workspaceCacheDictionary[workspacePath] = workspace;
    }
    
    return workspace;
}

- (void)updateProject:(XCProject *)project {
//    [self removeProjectWithPath:project.filePath];
//    
    XCWorkspace *workspace = self.currentWorkspace;
    
    NSLog(workspace.projects);
//    NSMapTable *projectsMapTable = [self mapTableForWorkspace:workspace
//                                                         kind:MHHeaderCacheHeaderKindProjects];
//    [projectsMapTable setObject:project.headerFiles
//                         forKey:project];
//    
//    NSArray *frameworkHeaders = [self frameworkHeadersForProject:project];
//    
//    NSMapTable *frameworksMapTable = [self mapTableForWorkspace:workspace
//                                                           kind:MHHeaderCacheHeaderKindFrameworks];
//    [frameworksMapTable setObject:frameworkHeaders
//                           forKey:project];
}

- (void)updateProjectWithPath:(NSString *)path {
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) return;
    XCProject *project = [XCProject projectWithFilePath:path];
    [self updateProject:project];
}


// Sample Action, for menu item:
- (void)doMenuAction
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Hello, Auto Importer World" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [alert runModal];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
