//
//  LAFImportListView.h
//  AutoImporter
//
//  Created by Luis Floreani on 9/19/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LAFImportListView : NSView

@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) IBOutlet NSSearchField *searchField;

@end
