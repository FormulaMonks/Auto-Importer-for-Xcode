//
//  XCSourceFile+Path.m
//  AutoImporter
//
//  Created by Luis Floreani on 9/11/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "XCSourceFile+Path.h"
#import "XCProject+Extensions.h"

@interface XCSourceFile()

@property (nonatomic, readonly) XCProject *project;

@end

@implementation XCSourceFile (Path)

//@dynamic project;

- (NSString *)fullPath {
    XCProject *project = [self valueForKey:@"_project"];
    NSString *projectPath = [project filePath];
    NSString *filePath = [self pathRelativeToProjectRoot];
    return [[projectPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:filePath];
}

@end
