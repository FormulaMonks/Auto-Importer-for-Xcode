//
//  LAFIdentifier.m
//  AutoImporter
//
//  Created by Luis Floreani on 10/16/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFIdentifier.h"

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
        case LAFIdentifierTypeCategory:
            return [_customTypeString stringByAppendingString:@"()"];
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
