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
#import "LAFProjectHeaderCache.h"
#import "LAFIdentifier.h"

@interface LAFImportListViewController () <NSPopoverDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>
@property (nonatomic, strong) NSPopover *popover;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSMutableSet *alreadyImported;
@property (nonatomic, strong) NSArray *filtered;
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

+ (instancetype)presentInView:(NSView *)view items:(NSArray *)items alreadyImported:(NSMutableSet *)alreadyImported searchText:(NSString *)searchText {
    LAFImportListViewController *instance = [self sharedInstance];
    
    if (![instance currentListView]) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = [NSString stringWithFormat:@"Failed to load nib file. Try deleting '$HOME/Library/Application Support/Developer/Shared/Xcode/Plug-ins/Auto-Importer.xcplugin' AND '$HOME/library/Developer/Xcode/DerivedData/*' and then reinstall the plugin"];
        alert.alertStyle = NSWarningAlertStyle;
        [alert beginSheetModalForWindow:[NSApp keyWindow] completionHandler:nil];

        return nil;
    }
    
    instance.items = items;
    instance.alreadyImported = alreadyImported;
    instance.filtered = items;

    if (searchText) {
        LAFImportListView *listView = [instance currentListView];
        [listView.searchField setStringValue:searchText];
    }

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
    if (!view) {
        LAFLog(@"Can't show identifiers import list since view is nil");
        return;
    }
    
    if (!self.popover.isShown) {
        _filtered = _items;
        [self filterItems];
        
        [self.popover showRelativeToRect:frame
                                  ofView:view
                           preferredEdge:NSMinYEdge];
    }
}

- (void)showImportListViewInTextView:(NSTextView *)textView {
    NSRect frame = [textView mhFrameForCaret];
    [self showImportListViewInView:textView frame:frame];
}

- (void)loadImportListView {
    NSBundle *bundle = [NSBundle bundleForClass:[LAFImportListView class]];
    
    NSString *nibName = @"LAFImportListView";
    
    NSString *path = [bundle pathForResource:nibName ofType:@"nib"];
    if (!path) {
        NSLog(@"Failed to load %@ nib", nibName);
        
        return;
    }
    
    NSViewController *contentViewController = [[NSViewController alloc] initWithNibName:nibName bundle:bundle];
    
    NSPopover *popover = [[NSPopover alloc] init];
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorTransient;
    popover.appearance = NSPopoverAppearanceMinimal;
    popover.animates = NO;
    popover.contentViewController = contentViewController;
    self.popover = popover;
    
    LAFImportListView *view = [self currentListView];
    view.tableView.dataSource = self;
    view.tableView.delegate = self;
    view.tableView.target = self;
    view.tableView.doubleAction = @selector(commitAction);
    view.tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    view.searchField.delegate = self;
}

- (void)commitAction {
    LAFImportListView *view = [self currentListView];
    NSIndexSet *indexes = [view.tableView selectedRowIndexes];
    if ([indexes count] == 1) {
        int index = (int)[indexes firstIndex];
        [_delegate itemSelected:[_filtered[index] name]];
        [self dismiss];
    }
}

- (LAFImportListView *)currentListView {
    return (LAFImportListView *)self.popover.contentViewController.view;
}

- (void)dismiss {
    [self.popover close];
}

- (void)filterItems {
    LAFImportListView *view = [self currentListView];

    if ([[view.searchField stringValue] length] == 0) {
        _filtered = _items;
    } else {
        _filtered = [_items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.description CONTAINS[cd] %@", [view.searchField stringValue]]];
    }
    
    [view.tableView reloadData];
    [view.tableView scrollRowToVisible:0];
    
    NSIndexSet *set = [NSIndexSet indexSetWithIndex:0];
    [view.tableView selectRowIndexes:set byExtendingSelection:NO];
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    [self filterItems];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {
    LAFImportListView *view = [self currentListView];
    NSIndexSet *indexes = [view.tableView selectedRowIndexes];
    int index = -1;
    if ([indexes count] == 1) {
        index = (int)[indexes firstIndex];
    }
    
    BOOL ret = NO;
    if (commandSelector == @selector(moveDown:)) {
        index++;
        if (index > [_filtered count] - 1) {
            index = (int)[_filtered count] - 1;
        }
        ret = YES;
    } else if (commandSelector == @selector(moveUp:)) {
        index--;
        if (index < 0) {
            index = 0;
        }
        ret = YES;
    } else if (commandSelector == @selector(cancelOperation:)) {
        [self dismiss];
    } else if (commandSelector == @selector(insertNewline:)) {
        [self commitAction];
    }
    
    [view.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [view.tableView scrollRowToVisible:index];
    
    return ret;
}

-(void)controlTextDidEndEditing:(NSNotification *)notification
{
    if ( [[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement ) {
        [self commitAction];
    }
}

#pragma mark - NSTableViewDataSource

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return _filtered[row];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
    return [_filtered count];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSTextFieldCell *cell = aCell;
    LAFIdentifier *identifier = (LAFIdentifier *)cell.objectValue;
    if ([_alreadyImported containsObject:identifier]) {
        [cell setTextColor:[NSColor lightGrayColor]];
    } else {
        [cell setTextColor:[NSColor darkGrayColor]];
    }
    
    if ([[aTableView selectedRowIndexes] containsIndex:rowIndex]) {
        [aCell setBackgroundColor: [NSColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]];
    } else {
        [aCell setBackgroundColor: [NSColor whiteColor]];
    }
    [aCell setDrawsBackground:YES];

}

@end
