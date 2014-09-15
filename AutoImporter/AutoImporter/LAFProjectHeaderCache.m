//
//  LAFProjectHeaderCache.m
//  AutoImporter
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFProjectHeaderCache.h"
#import "XCProject.h"
#import "XCSourceFile.h"
#import "XCSourceFile+Path.h"

@interface LAFProjectHeaderCache()

@property (nonatomic, strong) NSMutableDictionary *headersBySymbols;

@end

@implementation LAFProjectHeaderCache

- (instancetype)initWithProjectPath:(NSString *)filePath
{
    self = [super init];
    if (self) {
        _filePath = filePath;
        _headersBySymbols = [NSMutableDictionary new];

        XCProject *project = [XCProject projectWithFilePath:filePath];
        [self updateProject:project];
    }
    return self;
}

- (NSString *)headerForSymbol:(NSString *)symbol {
    return _headersBySymbols[symbol];
}

- (NSArray *)fullPathsForFiles:(NSSet *)fileNames inDirectory:(NSString *)directoryPath {
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
    
    NSMutableArray *fullPaths = [NSMutableArray array];
    
    NSString *filePath = nil;
    while ( (filePath = [enumerator nextObject] ) != nil ){
        if ([fileNames containsObject:[filePath lastPathComponent]]) {
            [fullPaths addObject:[directoryPath stringByAppendingPathComponent:filePath]];
        }
    }
    
    return fullPaths;
}

- (void)processHeaderPath:(NSString *)headerPath {
    NSString *content = [NSString stringWithContentsOfFile:headerPath encoding:NSUTF8StringEncoding error:nil];
    
    NSError *error = nil;
    NSString *classDefinition = @"(?:@interface|@protocol)\\s+([a-z][a-z0-9_\\s*\()]+)";
//    NSString *classDefinition = @"@(?:interface|protocol)\\s+(\\w+)";
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:classDefinition
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    
    if (error) {
        NSLog(@"processing header path error: %@", error);
        return;
    }
    
    [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, [content length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        NSRange matchRange = [match rangeAtIndex:1];
        NSString *matchString = [content substringWithRange:matchRange];
        NSString *matchTrim = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([matchTrim rangeOfString:@"("].location == NSNotFound) { // we're not adding categories
            _headersBySymbols[matchTrim] = [headerPath lastPathComponent];
        }
    }];
}

- (void)updateProject:(XCProject *)project {
    NSDate *start = [NSDate date];
    NSMutableSet *missingFiles = [NSMutableSet set];
    for (XCSourceFile *header in project.headerFiles) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[header fullPath]]) {
            [self processHeaderPath:[header fullPath]];
        } else {
            [missingFiles addObject:[[header pathRelativeToProjectRoot] lastPathComponent]];
        }
    }
    
    NSString *projectDir = [[project filePath] stringByDeletingLastPathComponent];
    NSArray *missingHeaderFullPaths = [self fullPathsForFiles:missingFiles inDirectory:projectDir];
    
    for (NSString *headerMissingFullpath in missingHeaderFullPaths) {
        [self processHeaderPath:headerMissingFullpath];
    }
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
    
    NSLog(@"Parse Time for project %@: %f", [[project filePath] lastPathComponent], executionTime);
    
    NSLog(@"%@", _headersBySymbols);
}

@end
