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

- (void)updateProject:(XCProject *)project {
    NSLog(@"updating project %@", [project filePath]);
    
    for (XCSourceFile *header in project.headerFiles) {
        NSString *content = [NSString stringWithContentsOfFile:[header fullPath] encoding:NSUTF8StringEncoding error:nil];
        
        if ([content length] == 0) {
            NSLog(@"not reading %@", [header fullPath]);
            continue;
        }
        
        NSError *error = nil;
        NSString *classDefinition = @"@(?:interface|protocol)\\s+(\\w+)";
        //        NSString *classDefinition = @"@interface\\s+([a-z][a-z0-9]*)";
        //        NSString *categoryDefinition = @"@interface\\s+(\\w+)\\s+\(\\w";
        //        NSString *protocolDefinition = @"@protocol\\s+(\\w+)";
        NSRegularExpression *regex = [NSRegularExpression
                                      regularExpressionWithPattern:classDefinition
                                      options:NSRegularExpressionCaseInsensitive
                                      error:&error];
        
        if (error) {
            NSLog(@"error: %@", error);
            continue;
        }
        
        [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, [content length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
            NSRange matchRange = [match rangeAtIndex:1];
            NSString *matchString = [content substringWithRange:matchRange];
            _headersBySymbols[matchString] = [[header fullPath] lastPathComponent];
        }];
    }
    
    NSLog(@"%@", _headersBySymbols);
}

@end
