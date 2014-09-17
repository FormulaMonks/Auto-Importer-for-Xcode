//
//  LAFTestCase.m
//  AutoImporter
//
//  Created by Luis Floreani on 9/17/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFTestCase.h"

@implementation LAFTestCase

- (void)waitForGroup;
{
    __block BOOL didComplete = NO;
    dispatch_group_notify(self.requestGroup, dispatch_get_main_queue(), ^{
        didComplete = YES;
    });
    while (! didComplete) {
        NSTimeInterval const interval = 0.002;
        if (! [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:interval]]) {
            [NSThread sleepForTimeInterval:interval];
        }
    }
}

- (void)setUp
{
    [super setUp];

    _requestGroup = dispatch_group_create();
}

- (void)tearDown
{
    [self waitForGroup];
    [super tearDown];
}

@end
