//
//  AutoImporterTests.m
//  AutoImporterTests
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LAFProjectHeaderCache.h"

@interface AutoImporterTests : XCTestCase

@end

@implementation AutoImporterTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testExample
{
    NSString *curDir = [[NSFileManager defaultManager] currentDirectoryPath];
    NSString *projectPath = [curDir stringByAppendingPathComponent:@"/../TestProjects/AutoImporterTestProject1/AutoImporterTestProject1.xcodeproj"];
    
    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:projectPath];
    XCTAssertEqualObjects([headers headerForSymbol:@"LAFMyClass1"], @"LAFMyClass1.h");
}

@end
