//
//  FileContents.swift
//  AutoImporter
//
//  Created by Luis Floreani on 8/21/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

import Foundation

class FileContents {
    init() {}
    
    class func file1() -> String {
        return "#import \"bla1.h\"\n"
            + "\"bla2.h\""
    }
}