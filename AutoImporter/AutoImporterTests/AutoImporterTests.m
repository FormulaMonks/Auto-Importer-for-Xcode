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
@property (nonatomic) dispatch_group_t requestGroup;
@end

@implementation AutoImporterTests

- (void)setUp
{
    [super setUp];
    
    NSString *curDir = [[NSFileManager defaultManager] currentDirectoryPath];
    _projectPath = [curDir stringByAppendingPathComponent:@"/../TestProjects/AutoImporterTestProject1/AutoImporterTestProject1.xcodeproj"];
    
    _requestGroup = dispatch_group_create();
}

- (void)tearDown
{
    [self waitForGroup];
    [super tearDown];
}

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

- (void)testClassesAreImported
{
    dispatch_group_enter(self.requestGroup);

    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    [headers refresh:^{
        XCTAssertEqualObjects([headers headerForSymbol:@"LAFMyClass1"], @"LAFMyClass1.h");
        XCTAssertEqualObjects([headers headerForSymbol:@"LAFMyClass_1"], @"LAFMyClass1.h");
        XCTAssertEqualObjects([headers headerForSymbol:@"LAFMyClass2"], @"LAFMyClass2.h");
        XCTAssertEqualObjects([headers headerForSymbol:@"LAFMyClass2Bis"], @"LAFMyClass2.h");
        XCTAssertEqualObjects([headers headerForSymbol:@"LAFMyProtocol1"], @"LAFMyClass1.h");
        XCTAssertNil([headers headerForSymbol:@"NSColor"]);
        
        dispatch_group_leave(self.requestGroup);
    }];
}

- (void)testGroupClassIsImported
{
    dispatch_group_enter(self.requestGroup);

    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    [headers refresh:^{
        XCTAssertEqualObjects([headers headerForSymbol:@"LAFGroupClass1"], @"LAFGroupClass1.h");
        
        dispatch_group_leave(self.requestGroup);
    }];
}

- (void)testSubdirectoryClassIsImported
{
    dispatch_group_enter(self.requestGroup);

    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    [headers refresh:^{
        XCTAssertEqualObjects([headers headerForSymbol:@"LAFSubdirectoryClass1"], @"LAFSubdirectoryClass1.h");
        
        dispatch_group_leave(self.requestGroup);
    }];
}

@end
