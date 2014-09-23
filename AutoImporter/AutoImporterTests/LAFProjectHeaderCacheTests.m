//
//  AutoImporterTests.m
//  AutoImporterTests
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LAFProjectHeaderCache.h"
#import "LAFTestCase.h"

@interface LAFProjectHeaderCacheTests : LAFTestCase
@property (nonatomic, strong) NSString *projectPath;
@end

@implementation LAFProjectHeaderCacheTests

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

- (void)testHeaders
{
    dispatch_group_enter(self.requestGroup);
    
    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    [headers refresh:^{
        XCTAssertTrue([[headers headers] containsObject:[[LAFSymbol alloc] initWithName:@"LAFMyClass1.h"]]);
        XCTAssertTrue([[headers headers] containsObject:[[LAFSymbol alloc] initWithName:@"LAFMyClass2.h"]]);
        XCTAssertTrue([[headers headers] containsObject:[[LAFSymbol alloc] initWithName:@"NSColor+MyColor.h"]]);
        XCTAssertTrue([[headers headers] containsObject:[[LAFSymbol alloc] initWithName:@"LAFSubdirectoryClass1.h"]]);
        XCTAssertTrue([[headers headers] containsObject:[[LAFSymbol alloc] initWithName:@"LAFAppDelegate.h"]]);
        
        dispatch_group_leave(self.requestGroup);
    }];
}

- (void)testHeaderChanged
{
    dispatch_group_enter(self.requestGroup);
    
    LAFProjectHeaderCache *headers = [[LAFProjectHeaderCache alloc] initWithProjectPath:_projectPath];
    [headers refresh:^{
        XCTAssertNil([headers headerForSymbol:@"LAFMyClass2BisBis"]);
        
        NSString *headerPath = [[_projectPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"AutoImporterTestProject1/LAFMyClass2.h"];
        
        NSString *content = [NSString stringWithContentsOfFile:headerPath encoding:NSUTF8StringEncoding error:nil];
        
        NSString *newContent = [content stringByAppendingString:@"\n@interface LAFMyClass2BisBis : NSObject\n\n@end"];
        
        // replace file
        [newContent writeToFile:headerPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        [headers refreshHeader:headerPath];
        
        XCTAssertEqualObjects([headers headerForSymbol:@"LAFMyClass2BisBis"], @"LAFMyClass2.h");
        
        // restore file
        [content writeToFile:headerPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        dispatch_group_leave(self.requestGroup);
    }];
    
}

@end
