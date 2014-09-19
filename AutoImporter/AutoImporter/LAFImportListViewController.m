//
//  LAFImportListViewController.m
//  AutoImporter
//
//  Created by Luis Floreani on 9/19/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFImportListViewController.h"
#import "LAFImportListView.h"
#import "NSTextView+Operations.h"

@interface LAFImportListViewController () <NSPopoverDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>
@property (nonatomic, strong) NSPopover *popover;
@end


@implementation LAFImportListViewController

+ (instancetype)sharedInstance {
    static LAFImportListViewController *_viewController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _viewController = [[self alloc] init];
    });
    return _viewController;
}

+ (instancetype)presentInView:(NSView *)view {
    LAFImportListViewController *instance = [self sharedInstance];
    if([view isKindOfClass:[NSTextView class]]) {
        [instance showImportListViewInTextView:(NSTextView *)view];
    } else {
        [instance showImportListViewInView:view frame:view.frame];
    }
    return instance;
   
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadImportListView];
    }
    return self;
}

- (void)showImportListViewInView:(NSView *)view frame:(NSRect)frame {
    if (!self.popover.isShown) {
        [self.popover showRelativeToRect:frame
                                  ofView:view
                           preferredEdge:NSMinYEdge];
    }
}

- (void)showImportListViewInTextView:(NSTextView *) textView {
    NSRect frame = [textView mhFrameForCaret];
    [self showImportListViewInView:textView frame:frame];
}

- (void)loadImportListView {
    NSBundle *bundle = [NSBundle bundleForClass:[LAFImportListView class]];
    NSViewController *contentViewController = [[NSViewController alloc] initWithNibName:@"LAFImportListView" bundle:bundle];
    
    NSPopover *popover = [[NSPopover alloc] init];
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorTransient;
    popover.appearance = NSPopoverAppearanceMinimal;
    popover.animates = NO;
    popover.contentViewController = contentViewController;
    self.popover = popover;
    
    LAFImportListView *view = [self currentListView];
    view.tableView.dataSource = self;
    view.searchField.delegate = self;
}

- (LAFImportListView *)currentListView {
    return (LAFImportListView *)self.popover.contentViewController.view;
}

- (void)dismiss {
    [self.popover close];
}

#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    LAFImportListView *view = [self currentListView];

    NSIndexSet *set = [NSIndexSet indexSetWithIndex:0];
    [view.tableView selectRowIndexes:set byExtendingSelection:NO];
    
    return YES;
}

#pragma mark - NSTableViewDataSource

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return @"MyClass (MyClass.h)";
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
    return 10;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
}

@end
