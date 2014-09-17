//
//  LAFTestCase.h
//  AutoImporter
//
//  Created by Luis Floreani on 9/17/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface LAFTestCase : XCTestCase

@property (nonatomic) dispatch_group_t requestGroup;

@end
