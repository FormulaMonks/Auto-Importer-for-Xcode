//
//  LAFIdentifier.h
//  AutoImporter
//
//  Created by Luis Floreani on 10/16/14.
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

@end
