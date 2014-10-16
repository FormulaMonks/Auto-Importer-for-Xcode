//
//  LAFElementProcessor.m
//  AutoImporter
//
//  Created by Luis Floreani on 10/16/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import "LAFElementProcessor.h"

@implementation LAFElementProcessor

- (NSString *)pattern {
    @throw [NSException exceptionWithName:@"LAFElementProcessorError" reason:@"pattern empty implementation" userInfo:nil];
}

- (NSArray *)createElements:(NSString *)content {
    @throw [NSException exceptionWithName:@"LAFElementProcessorError" reason:@"create elements empty implementation" userInfo:nil];
}

- (void)processContent:(NSString *)content resultBlock:(processorResultBlock)resultBlock {
    NSError *error = nil;
    NSString *classRegExp = [self pattern];
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:classRegExp
                                  options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionAnchorsMatchLines
                                  error:&error];
    
    if (error) {
        LAFLog(@"processing header path error: %@", error);
        return;
    }
    
    [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, [content length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        resultBlock(match, flags, stop);
    }];
}

@end
