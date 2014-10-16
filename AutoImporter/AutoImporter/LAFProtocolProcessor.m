//
//  LAFProtocolProcessor.m
//  AutoImporter
//
//  Created by Luis Floreani on 10/16/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFProtocolProcessor.h"
#import "LAFIdentifier.h"

@implementation LAFProtocolProcessor

- (NSString *)pattern {
    return @"(?:@protocol)\\s+([a-z][a-z0-9_\\s*\()]+)";
}

- (LAFIdentifierType)identifierType {
    return LAFIdentifierTypeProtocol;
}

@end
