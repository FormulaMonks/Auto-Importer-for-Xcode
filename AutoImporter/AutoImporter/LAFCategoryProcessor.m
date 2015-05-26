//
//  LAFCategoryProcessor.m
//  AutoImporter
//
//  Created by Luis Floreani on 10/16/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFCategoryProcessor.h"
#import "LAFIdentifier.h"

@implementation LAFCategoryProcessor

- (NSString *)pattern {
    return @"(?:@interface)\\s+([a-z][a-z0-9_\\s*]+)\\(.+\\)$(.+)^@end";
}

- (NSArray *)createElements:(NSString *)content {
    NSMutableArray *array = [NSMutableArray array];
    [self processContent:content resultBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        NSArray *elements = [self createCategoryElements:match from:content];
        [array addObjectsFromArray:elements];
    }];
    
    return array;
}

- (NSArray *)createCategoryElements:(NSTextCheckingResult *)match from:(NSString *)content {
    NSRange matchRange = [match rangeAtIndex:1];
    NSString *matchString = [content substringWithRange:matchRange];
    NSString *matchClass = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    matchRange = [match rangeAtIndex:2];
    matchString = [content substringWithRange:matchRange];
    NSString *matchMethods = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *methods = [matchMethods componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *elements = [NSMutableArray array];
    for (NSString *method in methods) {
        NSString *signature = [self extractSignature:method];
        if (signature) {
            LAFIdentifier *element = [LAFIdentifier new];
            element.name = [self extractSignature:method];
            element.customTypeString = matchClass;
            element.type = LAFIdentifierTypeCategory;
            [elements addObject:element];
        }
    }
    
    return elements;
}

- (NSString *)extractSignature:(NSString *)method {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"([a-z][a-z0-9_]+\\s*[:;])"
                                  options:NSRegularExpressionCaseInsensitive|NSRegularExpressionAllowCommentsAndWhitespace
                                  error:&error];
    
    if (error) {
        LAFLog(@"processing header path error: %@", error);
        return nil;
    }
    
    NSMutableString *signature = [NSMutableString string];
    [regex enumerateMatchesInString:method options:0 range:NSMakeRange(0, [method length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        NSRange matchRange = [match rangeAtIndex:1];
        NSString *matchString = [method substringWithRange:matchRange];
        NSString *matchPart = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *partWithoutSpaces = [matchPart stringByReplacingOccurrencesOfString:@" " withString:@""];
        if ([partWithoutSpaces hasSuffix:@";"]) {
            if ([signature length] > 0) {
                return; // it's not the first part so it already has a name
            } else {
                // remove ';' since we're not interested in it
                partWithoutSpaces = [partWithoutSpaces substringToIndex:partWithoutSpaces.length - 1];
            }
        }
        
        [signature appendString:partWithoutSpaces];
    }];
    
    if ([signature length] > 0)
        return signature;
    else
        return nil;
}


@end
