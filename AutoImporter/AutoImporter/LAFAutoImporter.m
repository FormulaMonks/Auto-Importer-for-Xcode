//
//  LAFAutoImporter.m
//  LAFAutoImporter
//
//  Created by Luis Floreani on 9/10/14.
//    Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "LAFAutoImporter.h"
#import "XCProject.h"
#import "XCFXcodePrivate.h"
#import "XCWorkspace.h"
#import "MHXcodeDocumentNavigator.h"
#import "XCSourceFile.h"
#import "XCSourceFile+Path.h"
#import "NSString+Extensions.h"
#import "DVTSourceTextStorage+Operations.h"
#import "NSTextView+Operations.h"

NSString * const LAFAddImportOperationImportRegexPattern = @".*#.*(import|include).*[\",<].*[\",>]";

static LAFAutoImporter *sharedPlugin;

@interface LAFAutoImporter()
@property (nonatomic, strong) NSMutableDictionary *workspaceCacheDictionary;
@property (nonatomic, strong) NSMutableDictionary *headersBySymbols;
@property (nonatomic, strong) NSBundle *bundle;
@end

@implementation LAFAutoImporter

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
    
    EventHotKeyID hkRef;
    GetEventParameter(anEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,sizeof(hkRef),NULL,&hkRef);
    switch (hkRef.id) {
        case 1:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LAFShowHeaders"
                                                                object:nil];
        }
            break;
            
    }
    return noErr;
}

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
        _headersBySymbols = [NSMutableDictionary new];

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
        
        [notificationCenter addObserver:self
                               selector:@selector(projectDidClose:)
                                   name:@"PBXProjectDidCloseNotification"
                                 object:nil];

        
        [self loadKeyboardHandler];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showHeaders:)
                                                     name:@"LAFShowHeaders"
                                                   object:nil];

    }
    return self;
}

- (void)addImport:(NSString *)statement {
    DVTSourceTextStorage *textStorage = [self currentTextStorage];
    NSInteger lastLine = [self appropriateLine:textStorage statement:statement];
    
    if (lastLine != NSNotFound) {
        NSString *importString = [NSString stringWithFormat:@"%@\n", statement];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [textStorage mhInsertString:importString
                                 atLine:lastLine+1];
        });
    }}

- (NSUInteger)appropriateLine:(DVTSourceTextStorage *)source statement:(NSString *)statement {
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
    
    if (foundDuplicate) return NSNotFound;
    
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

- (void)showHeaders:(NSNotification *)notif {
    NSTextView *currentTextView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    NSRange range = currentTextView.selectedRange;
    NSString *text = nil;
    NSColor *color = nil;
    if (range.length > 0) {
        NSString *selection = [[currentTextView string] substringWithRange:range];
        NSString *header = _headersBySymbols[selection];
        if (header) {
            text = [NSString stringWithFormat:@"Header '%@' added!", header];
            color = [NSColor colorWithRed:0.8 green:1.0 blue:0.8 alpha:1.0];
            [self addImport:[NSString stringWithFormat:@"#import \"%@\"", header]];
        } else {
            text = [NSString stringWithFormat:@"Symbol '%@' not found", selection];
            color = [NSColor colorWithRed:1.0 green:0.8 blue:0.8 alpha:1.0];
        }
    } else {
        text = [NSString stringWithFormat:@"No text selection"];
        color = [NSColor colorWithCalibratedWhite:0.95 alpha:1.0];
    }
    
    NSLog(@"%@", text);
    NSRange selectedRange = [[currentTextView.selectedRanges objectAtIndex:0] rangeValue];
    NSRect keyRectOnScreen = [currentTextView firstRectForCharacterRange:selectedRange];
    NSRect keyRectOnWindow = [currentTextView.window convertRectFromScreen:keyRectOnScreen];
    NSRect keyRectOnTextView = [currentTextView convertRect:keyRectOnWindow fromView:nil];
    keyRectOnTextView.size.width = 1;
    
    NSTextField *field = [[NSTextField alloc] initWithFrame:CGRectMake(keyRectOnTextView.origin.x, keyRectOnTextView.origin.y - 22, 0, 0)];
    [field setBackgroundColor:color];
    [field setTextColor:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]];
    [field setStringValue:text];
    [field sizeToFit];
    [field setBordered:NO];
    [field setEditable:NO];
    
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


- (void)loadKeyboardHandler {
    EventHotKeyRef myHotKeyRef;
    EventHotKeyID myHotKeyID;
    EventTypeSpec eventType;
    
    eventType.eventClass=kEventClassKeyboard;
    eventType.eventKind=kEventHotKeyPressed;
    InstallApplicationEventHandler(&myHotKeyHandler,1,&eventType,NULL,NULL);
    
    myHotKeyID.signature='lak1';
    myHotKeyID.id=1;
    
    RegisterEventHotKey(kVK_ANSI_H, cmdKey+controlKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);
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

- (void)projectDidClose:(NSNotification *)notification {
    [_headersBySymbols removeAllObjects];
}

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
//    XCWorkspace *workspace = self.currentWorkspace;
    
    NSLog(@"updating project %@", [project filePath]);
    
    for (XCSourceFile *header in project.headerFiles) {
        NSString *content = [NSString stringWithContentsOfFile:[header fullPath] encoding:NSUTF8StringEncoding error:nil];
        
        if ([content length] == 0) {
            NSLog(@"not reading %@", [header fullPath]);
            continue;
        }

        NSError *error = nil;
        NSString *classDefinition = @"@(?:interface|protocol)\\s+(\\w+)";
//        NSString *classDefinition = @"@interface\\s+([a-z][a-z0-9]*)";
//        NSString *categoryDefinition = @"@interface\\s+(\\w+)\\s+\(\\w";
//        NSString *protocolDefinition = @"@protocol\\s+(\\w+)";
        NSRegularExpression *regex = [NSRegularExpression
                                      regularExpressionWithPattern:classDefinition
                                      options:NSRegularExpressionCaseInsensitive
                                      error:&error];
        
        if (error) {
            NSLog(@"error: %@", error);
            continue;
        }
        
        [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, [content length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
            NSRange matchRange = [match rangeAtIndex:1];
            NSString *matchString = [content substringWithRange:matchRange];
            _headersBySymbols[matchString] = [[header fullPath] lastPathComponent];
        }];
    }
    
    NSLog(@"%@", _headersBySymbols);
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
