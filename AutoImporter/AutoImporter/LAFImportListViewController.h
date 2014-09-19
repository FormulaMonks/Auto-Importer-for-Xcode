//
//  LAFImportListViewController.h
//  AutoImporter
//
//  Created by Luis Floreani on 9/19/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface LAFImportListViewController : NSObject

+ (instancetype)sharedInstance;
+ (instancetype)presentInView:(NSView *)view;

@end
