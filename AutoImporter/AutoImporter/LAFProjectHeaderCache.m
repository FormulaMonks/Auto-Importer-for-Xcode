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
@property (nonatomic, strong) NSMapTable *headersBySymbols;

// value is an array of LAFSymbol
@property (nonatomic, strong) NSMapTable *symbolsByHeader;

@property (nonatomic, strong) NSOperationQueue *headersQueue;

@end

@implementation LAFProjectHeaderCache

- (instancetype)initWithProjectPath:(NSString *)filePath
{
    self = [super init];
    if (self) {
        _filePath = filePath;
        _headersBySymbols = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
        _symbolsByHeader = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
        _headersQueue = [NSOperationQueue new];
        _headersQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)refresh:(dispatch_block_t)doneBlock {
    [_headersBySymbols removeAllObjects];
    [_symbolsByHeader removeAllObjects];
    
    XCProject *project = [XCProject projectWithFilePath:_filePath];
    [_headersQueue addOperationWithBlock:^{
        [self updateProject:project];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            doneBlock();
        }];
    }];
}

- (BOOL)containsHeader:(NSString *)headerPath {
    return [[[_symbolsByHeader keyEnumerator] allObjects] containsObject:[headerPath lastPathComponent]];
}

- (void)refreshHeader:(NSString *)headerPath {
    for (LAFSymbol *symbol in [_symbolsByHeader objectForKey:[headerPath lastPathComponent]]) {
        [_headersBySymbols removeObjectForKey:symbol];
    }
    
    NSMutableArray *symbols = [_symbolsByHeader objectForKey:[headerPath lastPathComponent]];
    [symbols removeAllObjects];
    
    [self processHeaderPath:headerPath];
}

- (NSString *)headerForSymbol:(NSString *)name {
    LAFSymbol *symbol = [LAFSymbol new];
    symbol.name = name;
    return [_headersBySymbols objectForKey:symbol];
}

- (NSArray *)headers {
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *header in [[_symbolsByHeader keyEnumerator] allObjects]) {
        LAFSymbol *symbol = [LAFSymbol new];
        symbol.name = header;
        symbol.type = LAFSymbolTypeHeader;
        [array addObject:symbol];
    }
    return array;
}

- (NSArray *)symbols {
    NSMutableArray *symbols = [NSMutableArray array];
    for (NSString *header in [[_symbolsByHeader keyEnumerator] allObjects]) {
        NSArray *objs = [_symbolsByHeader objectForKey:header];
        [symbols addObjectsFromArray:objs];
    }
    return symbols;
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
        
        NSMutableArray *symbols = [_symbolsByHeader objectForKey:headerPath];
        if (!symbols) {
            symbols = [NSMutableArray array];
            [_symbolsByHeader setObject:symbols forKey:[headerPath lastPathComponent]];
        }
        
        NSDictionary *pattern1 = @{kPatternRegExp: @"(?:@interface)\\s+([a-z][a-z0-9_\\s*\()]+)", kPatternType:@"LAFSymbolTypeClass"};
        NSDictionary *pattern2 = @{kPatternRegExp: @"(?:@protocol)\\s+([a-z][a-z0-9_\\s*\()]+)", kPatternType:@"LAFSymbolTypeProtocol"};
        NSArray *patterns = @[pattern1, pattern2];
        
        for (NSDictionary *pattern in patterns) {
            NSError *error = nil;
            NSString *classRegExp = pattern[kPatternRegExp];
            NSRegularExpression *regex = [NSRegularExpression
                                          regularExpressionWithPattern:classRegExp
                                          options:NSRegularExpressionCaseInsensitive
                                          error:&error];
            
            if (error) {
                NSLog(@"processing header path error: %@", error);
                continue;
            }
            
            [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, [content length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                NSRange matchRange = [match rangeAtIndex:1];
                NSString *matchString = [content substringWithRange:matchRange];
                NSString *matchTrim = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([matchTrim rangeOfString:@"("].location == NSNotFound) { // we're not adding categories
                    LAFSymbol *element = [LAFSymbol new];
                    element.name = matchTrim;
                    element.type = [element typeFromString:pattern[kPatternType]];
                    [_headersBySymbols setObject:[headerPath lastPathComponent] forKey:element];
                    [symbols addObject:element];
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
    
    NSLog(@"%d Headers in project %@ - parse time: %f", (int)[_headersBySymbols count], [[project filePath] lastPathComponent], executionTime);
}

@end

@implementation LAFSymbol

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
    if (![object isKindOfClass:[LAFSymbol class]])
        return NO;
    
    return [self.name isEqualToString:[object name]];
}

- (LAFSymbolType)typeFromString:(NSString *)string {
    if ([string isEqualToString:@"LAFSymbolTypeClass"]) {
        return LAFSymbolTypeClass;
    } else if ([string isEqualToString:@"LAFSymbolTypeProtocol"]) {
        return LAFSymbolTypeProtocol;
    } else if ([string isEqualToString:@"LAFSymbolTypeHeader"]) {
        return LAFSymbolTypeHeader;
    } else {
        return LAFSymbolTypeClass;
    }
}

- (NSString *)typeString {
    switch (_type) {
        case LAFSymbolTypeClass:
            return @"C";
            break;
        case LAFSymbolTypeProtocol:
            return @"P";
            break;
        case LAFSymbolTypeHeader:
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
