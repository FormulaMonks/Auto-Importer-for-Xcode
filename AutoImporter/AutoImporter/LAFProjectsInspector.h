//
//  LAFProjectsInspector.h
//  AutoImporter
//
//  Created by Luis Floreani on 9/15/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LAFProjectsInspector : NSObject

+ (instancetype)sharedInspector;

- (void)updateHeader:(NSString *)headerPath;
- (void)updateProject:(NSString *)projectPath;
- (void)closeProject:(NSString *)projectPath;

@end
