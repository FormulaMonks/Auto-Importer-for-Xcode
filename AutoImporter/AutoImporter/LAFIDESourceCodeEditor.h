//
//  LAFIDESourceCodeEditor.h
//  AutoImporter
//
//  Created by Luis Floreani on 10/2/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

typedef enum {
    LAFImportResultAlready,
    LAFImportResultNotFound,
    LAFImportResultDone,
} LAFImportResult;

@interface LAFIDESourceCodeEditor : NSObject

- (void)cacheImports;
- (void)invalidateImportsCache;

// need to call cacheImports before
- (BOOL)hasImportedHeader:(NSString *)header;

- (LAFImportResult)importHeader:(NSString *)header;
- (void)showAboveCaret:(NSString *)text color:(NSColor *)color;
- (NSString *)selectedText;
- (void)insertOnCaret:(NSString *)text;
- (NSView *)view;

@end
