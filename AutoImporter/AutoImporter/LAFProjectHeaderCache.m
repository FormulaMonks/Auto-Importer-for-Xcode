//
//  LAFProjectHeaderCache.m
//  AutoImporter
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Foundation/NSProxy.h>
#import "LAFProjectHeaderCache.h"
#import "XCProject.h"
#import "XCSourceFile.h"
#import "XCSourceFile+Path.h"

#define kPatternRegExp @"regexp"
#define kPatternType @"type"

@interface LAFProjectHeaderCache()

// value is NSString
@property (nonatomic, strong) NSMapTable *headersByIdentifiers;

// value is an array of LAFIdentifier
@property (nonatomic, strong) NSMapTable *identifiersByHeader;

@property (nonatomic, strong) NSOperationQueue *headersQueue;

@end

@implementation LAFProjectHeaderCache

- (instancetype)initWithProjectPath:(NSString *)filePath
{
    self = [super init];
    if (self) {
        _filePath = filePath;
        _headersByIdentifiers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
        _identifiersByHeader = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
        _headersQueue = [NSOperationQueue new];
        _headersQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)refresh:(dispatch_block_t)doneBlock {
    [_headersByIdentifiers removeAllObjects];
    [_identifiersByHeader removeAllObjects];
    
    XCProject *project = [XCProject projectWithFilePath:_filePath];
    [_headersQueue addOperationWithBlock:^{
        [self updateProject:project];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            doneBlock();
        }];
    }];
}

- (BOOL)containsHeader:(NSString *)headerPath {
    return [[[_identifiersByHeader keyEnumerator] allObjects] containsObject:[headerPath lastPathComponent]];
}

- (void)refreshHeader:(NSString *)headerPath {
    for (LAFIdentifier *identifier in [_identifiersByHeader objectForKey:[headerPath lastPathComponent]]) {
        [_headersByIdentifiers removeObjectForKey:identifier];
    }
    
    NSMutableArray *identifiers = [_identifiersByHeader objectForKey:[headerPath lastPathComponent]];
    [identifiers removeAllObjects];
    
    [self processHeaderPath:headerPath];
}

- (NSString *)headerForIdentifier:(NSString *)name {
    LAFIdentifier *identifier = [LAFIdentifier new];
    identifier.name = name;
    return [_headersByIdentifiers objectForKey:identifier];
}

- (NSArray *)headers {
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *header in [[_identifiersByHeader keyEnumerator] allObjects]) {
        LAFIdentifier *identifier = [LAFIdentifier new];
        identifier.name = header;
        identifier.type = LAFIdentifierTypeHeader;
        [array addObject:identifier];
    }
    return array;
}

- (NSArray *)identifiers {
    NSMutableArray *identifiers = [NSMutableArray array];
    for (NSString *header in [[_identifiersByHeader keyEnumerator] allObjects]) {
        NSArray *objs = [_identifiersByHeader objectForKey:header];
        [identifiers addObjectsFromArray:objs];
    }
    return identifiers;
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

- (BOOL)processHeaderPath:(NSString *)headerPath {
    @autoreleasepool {
        NSError *error = nil;
        NSString *content = [NSString stringWithContentsOfFile:headerPath encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            return NO;
        }
        
        NSMutableArray *identifiers = [_identifiersByHeader objectForKey:headerPath];
        if (!identifiers) {
            identifiers = [NSMutableArray array];
            [_identifiersByHeader setObject:identifiers forKey:[headerPath lastPathComponent]];
        }
        
        NSDictionary *pattern1 = @{kPatternRegExp: @"(?:@interface)\\s+([a-z][a-z0-9_\\s*\()]+)", kPatternType:@"LAFIdentifierTypeClass"};
        NSDictionary *pattern2 = @{kPatternRegExp: @"(?:@protocol)\\s+([a-z][a-z0-9_\\s*\()]+)", kPatternType:@"LAFIdentifierTypeProtocol"};
        NSArray *patterns = @[pattern1, pattern2];
        
        for (NSDictionary *pattern in patterns) {
            NSError *error = nil;
            NSString *classRegExp = pattern[kPatternRegExp];
            NSRegularExpression *regex = [NSRegularExpression
                                          regularExpressionWithPattern:classRegExp
                                          options:NSRegularExpressionCaseInsensitive
                                          error:&error];
            
            if (error) {
                LAFLog(@"processing header path error: %@", error);
                continue;
            }
            
            [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, [content length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                NSRange matchRange = [match rangeAtIndex:1];
                NSString *matchString = [content substringWithRange:matchRange];
                NSString *matchTrim = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([matchTrim rangeOfString:@"("].location == NSNotFound) { // we're not adding categories
                    LAFIdentifier *element = [LAFIdentifier new];
                    element.name = matchTrim;
                    element.type = [element typeFromString:pattern[kPatternType]];
                    [_headersByIdentifiers setObject:[headerPath lastPathComponent] forKey:element];
                    [identifiers addObject:element];
                }
            }];
        }
        
        return YES;
    }
}

- (void)updateProject:(XCProject *)project {
    NSDate *start = [NSDate date];
    NSMutableSet *missingFiles = [NSMutableSet set];
    for (XCSourceFile *header in project.headerFiles) {
        if (![self processHeaderPath:[header fullPath]]) {
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
    
    LAFLog(@"%d Headers in project %@ - parse time: %f", (int)[_headersByIdentifiers count], [[project filePath] lastPathComponent], executionTime);
}

@end

@implementation LAFIdentifier

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = name;
    }
    
    return self;
}

- (NSUInteger)hash {
    return [_name hash];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[LAFIdentifier class]])
        return NO;
    
    return [self.name isEqualToString:[object name]];
}

- (LAFIdentifierType)typeFromString:(NSString *)string {
    if ([string isEqualToString:@"LAFIdentifierTypeClass"]) {
        return LAFIdentifierTypeClass;
    } else if ([string isEqualToString:@"LAFIdentifierTypeProtocol"]) {
        return LAFIdentifierTypeProtocol;
    } else if ([string isEqualToString:@"LAFIdentifierTypeHeader"]) {
        return LAFIdentifierTypeHeader;
    } else {
        return LAFIdentifierTypeClass;
    }
}

- (NSString *)typeString {
    switch (_type) {
        case LAFIdentifierTypeClass:
            return @"C";
            break;
        case LAFIdentifierTypeProtocol:
            return @"P";
            break;
        case LAFIdentifierTypeHeader:
            return @"H";
            break;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[%@] %@", [self typeString], _name];
}

- (NSComparisonResult)localizedCaseInsensitiveCompare:(id)obj {
    return [_name localizedCaseInsensitiveCompare:[obj name]];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
