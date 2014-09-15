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

static LAFAutoImporter *sharedPlugin;

@interface LAFAutoImporter()
@property (nonatomic, strong) NSMutableDictionary *workspaceCacheDictionary;
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

        // init inspector
        [LAFProjectsInspector sharedInspector];
        
        // reference to plugin's bundle, for resource acccess
        self.bundle = plugin;
        
        [self loadKeyboardHandler];
    }
    return self;
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
