//
//  LAFLogger.h
//  AutoImporter
//
//  Created by Luis Floreani on 10/2/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

#ifndef AutoImporter_LAFLogger_h
#define AutoImporter_LAFLogger_h

#define LAFLog(fmt,...) NSLog(@"Auto Importer: %@",[NSString stringWithFormat:(fmt), ##__VA_ARGS__]);

#endif
