//
//  LAFProjectHeaderCache.h
//  AutoImporter
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LAFIdentifierType) {
    LAFIdentifierTypeClass = 0,
    LAFIdentifierTypeProtocol = 1,
    LAFIdentifierTypeCategory = 2,
    LAFIdentifierTypeHeader = 3,
};

@interface LAFIdentifier : NSObject
@property (nonatomic) LAFIdentifierType type;
@property (nonatomic) NSString *customTypeString;
@property (nonatomic, strong) NSString *name;

- (instancetype)initWithName:(NSString *)name;
+ (LAFIdentifierType)typeFromString:(NSString *)string;

@end

@interface LAFProjectHeaderCache : NSObject

@property (nonatomic, readonly) NSString *filePath;

// array of LAFIdentifier
@property (nonatomic, readonly) NSArray *identifiers;

@property (nonatomic, readonly) NSArray *headers;

- (instancetype)initWithProjectPath:(NSString *)filePath;
- (void)refresh:(dispatch_block_t)doneBlock;
- (void)refreshHeader:(NSString *)headerPath;
- (BOOL)containsHeader:(NSString *)headerPath;
- (NSString *)headerForIdentifier:(NSString *)name;

@end
