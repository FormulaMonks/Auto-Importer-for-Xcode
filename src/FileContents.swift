//
//  FileContents.swift
//  AutoImporter
//
//  Created by Luis Floreani on 8/21/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

/*

*. create an index of class -> header file, so only if class is found, it will be imported (will avoid trying to import UIKit ones for instance)

*. search for '\[.* new]\' or '\[.* alloc]\', if there is no import of $1, add it as #import "$1.h"
- avoid importing NS* classes

*. protocols?

*. index category methods, then look for them inside the .m, if found import the header where the method declaration was found

*. find unused imports!

*. how to solve framework headers? <Bla/Bla.h>

*/


import Foundation

class FileContents {
    init() {}
    
    class func file1() -> String {
        return "#import \"bla1.h\"\n"
            + "\"bla2.h\""
    }
}