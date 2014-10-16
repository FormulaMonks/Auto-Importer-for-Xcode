//
//  LAFElementProcessor.h
//  AutoImporter
//
//  Created by Luis Floreani on 10/16/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^processorResultBlock)(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop);

@interface LAFElementProcessor : NSObject

// must override by subclass
- (NSString *)pattern;

// must override by subclass
- (NSArray *)createElements:(NSString *)content;

- (void)processContent:(NSString *)content resultBlock:(processorResultBlock)resultBlock;

@end
