//
//  LAFProjectsInspectorTests.m
//  AutoImporter
//
//  Created by Luis Floreani on 9/17/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LAFTestCase.h"
#import "LAFProjectsInspector.h"

@interface LAFProjectsInspectorTests : LAFTestCase
@property (nonatomic, strong) NSString *projectPath;
@end

@implementation LAFProjectsInspectorTests

- (void)setUp
{
    [super setUp];
    
    NSString *curDir = [[NSFileManager defaultManager] currentDirectoryPath];
    _projectPath = [curDir stringByAppendingPathComponent:@"/../TestProjects/AutoImporterTestProject1/AutoImporterTestProject1.xcodeproj"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testProjectAndHeaderUpdated
{
    dispatch_group_enter(self.requestGroup);

    LAFProjectsInspector *inspector = [LAFProjectsInspector sharedInspector];
    NSString *headerBasePath = [[_projectPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"AutoImporterTestProject1"];
    [inspector updateProject:_projectPath doneBlock:^{
        XCTAssertFalse([inspector updateHeader:@"/no/path/bla.h"]);
        XCTAssertTrue([inspector updateHeader:[headerBasePath stringByAppendingPathComponent:@"LAFMyClass1.h"]]);
        
        dispatch_group_leave(self.requestGroup);
    }];
}

- (void)testProjectClosed
{
    dispatch_group_enter(self.requestGroup);
    
    LAFProjectsInspector *inspector = [LAFProjectsInspector sharedInspector];
    NSString *headerBasePath = [[_projectPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"AutoImporterTestProject1"];
    [inspector updateProject:_projectPath doneBlock:^{
        XCTAssertTrue([inspector updateHeader:[headerBasePath stringByAppendingPathComponent:@"LAFMyClass1.h"]]);
        
        [inspector closeProject:_projectPath];

        XCTAssertFalse([inspector updateHeader:[headerBasePath stringByAppendingPathComponent:@"LAFMyClass1.h"]]);

        dispatch_group_leave(self.requestGroup);
    }];
    
}

@end
