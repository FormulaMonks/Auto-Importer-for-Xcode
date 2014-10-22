//
//  LAFProjectHeaderCache.h
//  AutoImporter
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LAFProjectHeaderCache : NSObject

@property (nonatomic, readonly) NSString *filePath;

// array of LAFIdentifier
@property (nonatomic, readonly) NSArray *identifiers;

// array of LAFIdentifier
@property (nonatomic, readonly) NSArray *headers;

- (instancetype)initWithProjectPath:(NSString *)filePath;
- (void)refresh:(dispatch_block_t)doneBlock;
- (void)refreshHeader:(NSString *)headerPath;
- (BOOL)containsHeader:(NSString *)headerPath;
- (NSString *)headerForIdentifier:(NSString *)name;

@end
