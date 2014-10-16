//
//  LAFClassProcessor.m
//  AutoImporter
//
//  Created by Luis Floreani on 10/16/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFClassProcessor.h"
#import "LAFIdentifier.h"

@implementation LAFClassProcessor

- (NSString *)pattern {
    return @"(?:@interface)\\s+([a-z][a-z0-9_\\s*\()]+)";
}

- (LAFIdentifierType)identifierType {
    return LAFIdentifierTypeClass;
}

- (NSArray *)createElements:(NSString *)content {
    NSMutableArray *array = [NSMutableArray array];
    [self processContent:content resultBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        LAFIdentifier *element = [self createClassElement:match from:content];
        if (element) {
            element.type = [self identifierType];
            [array addObject:element];
        }
    }];
    
    return array;
}

- (LAFIdentifier *)createClassElement:(NSTextCheckingResult *)match from:(NSString *)content {
    NSRange matchRange = [match rangeAtIndex:1];
    NSString *matchString = [content substringWithRange:matchRange];
    NSString *matchTrim = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([matchTrim rangeOfString:@"("].location == NSNotFound) { // we're not adding categories
        NSRange matchRange = [match rangeAtIndex:1];
        NSString *matchString = [content substringWithRange:matchRange];
        NSString *matchTrim = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        LAFIdentifier *element = [LAFIdentifier new];
        element.name = matchTrim;
        
        return element;
    }
    
    return nil;
}

@end
