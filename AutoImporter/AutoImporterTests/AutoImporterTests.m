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
@property (nonatomic, strong) NSString *projectPath;
@end

@implementation AutoImporterTests

- (void)setUp
{
    [super setUp];
    
    NSString *curDir = [[NSFileManager defaultManager] currentDirectoryPath];
    _projectPath = [curDir stringByAppendingPathComponent:@"/../TestProjects/AutoImporterTestProject1/AutoImporterTestProject1.xcodeproj"];
}

- (void)tearDown
{
    [super tearDown];
}


- (void)testClassesAreImported
{
    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    XCTAssertEqualObjects([headers headerForSymbol:@"LAFMyClass1"], @"LAFMyClass1.h");
    XCTAssertEqualObjects([headers headerForSymbol:@"LAFMyClass2"], @"LAFMyClass2.h");
    XCTAssertEqualObjects([headers headerForSymbol:@"LAFMyClass2Bis"], @"LAFMyClass2.h");
    XCTAssertEqualObjects([headers headerForSymbol:@"LAFMyProtocol1"], @"LAFMyClass1.h");
}

- (void)testGroupClassIsImported
{
    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    XCTAssertEqualObjects([headers headerForSymbol:@"LAFGroupClass1"], @"LAFGroupClass1.h");
}

- (void)testSubdirectoryClassIsImported
{
    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    XCTAssertEqualObjects([headers headerForSymbol:@"LAFSubdirectoryClass1"], @"LAFSubdirectoryClass1.h");
}

@end
