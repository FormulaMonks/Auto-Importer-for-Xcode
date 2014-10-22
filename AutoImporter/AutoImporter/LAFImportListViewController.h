//
//  LAFImportListViewController.h
//  AutoImporter
//
//  Created by Luis Floreani on 9/19/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@protocol LAFImportListViewControllerDelegate <NSObject>

- (void)itemSelected:(NSString *)item;

@end

@interface LAFImportListViewController : NSObject

@property (nonatomic, weak) id<LAFImportListViewControllerDelegate> delegate;

+ (instancetype)sharedInstance;
+ (instancetype)presentInView:(NSView *)view items:(NSArray *)items alreadyImported:(NSMutableSet *)alreadyImported searchText:(NSString *)searchText;

@end
