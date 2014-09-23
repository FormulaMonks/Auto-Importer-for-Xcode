//
//  LAFProjectHeaderCache.h
//  AutoImporter
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LAFSymbolType) {
    LAFSymbolTypeClass = 0,
    LAFSymbolTypeProtocol = 1,
    LAFSymbolTypeHeader = 2,
};

@interface LAFSymbol : NSObject
@property (nonatomic) LAFSymbolType type;
@property (nonatomic, strong) NSString *name;

- (instancetype)initWithName:(NSString *)name;
- (LAFSymbolType)typeFromString:(NSString *)string;

@end

@interface LAFProjectHeaderCache : NSObject

@property (nonatomic, readonly) NSString *filePath;

// array of LAFSymbol
@property (nonatomic, readonly) NSArray *symbols;

@property (nonatomic, readonly) NSArray *headers;

- (instancetype)initWithProjectPath:(NSString *)filePath;
- (void)refresh:(dispatch_block_t)doneBlock;
- (void)refreshHeader:(NSString *)headerPath;
- (BOOL)containsHeader:(NSString *)headerPath;
- (NSString *)headerForSymbol:(NSString *)name;

@end
