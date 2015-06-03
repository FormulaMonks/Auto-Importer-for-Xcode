//
//  LAFAutoImporter.m
//  LAFAutoImporter
//
//  Created by Luis Floreani on 9/10/14.
//    Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "LAFAutoImporter.h"
#import "LAFProjectsInspector.h"
#import "LAFIDENotificationHandler.h"

static LAFAutoImporter *sharedPlugin;

@interface LAFAutoImporter()
@end

@implementation LAFAutoImporter

static OSStatus lafHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
    
    EventHotKeyID lafRef;
    GetEventParameter(anEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,sizeof(lafRef),NULL,&lafRef);
    switch (lafRef.id) {
        case 1:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LAFShowHeaders" object:nil];
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
            sharedPlugin = [[self alloc] init];
        });
    }
}

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification*)noti{
    // init inspector
    [LAFIDENotificationHandler sharedHandler];
    [self loadKeyboardHandler];
}

- (void)loadKeyboardHandler {
    EventHotKeyRef lafHotKeyRef;
    EventHotKeyID lafHotKeyID;
    EventTypeSpec eventType;
    
    eventType.eventClass=kEventClassKeyboard;
    eventType.eventKind=kEventHotKeyPressed;
    InstallApplicationEventHandler(&lafHotKeyHandler,1,&eventType,NULL,NULL);
    
    lafHotKeyID.signature='lak1';
    lafHotKeyID.id=1;
    
    RegisterEventHotKey(kVK_ANSI_H, cmdKey+controlKey, lafHotKeyID, GetApplicationEventTarget(), 0, &lafHotKeyRef);
}

@end
