//
//  main.swift
//  AutoImporter
//
//  Created by Luis Floreani on 8/20/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

import Foundation

let files = ["file1.m"]

for file in files {
    var bundle = NSBundle.mainBundle();
    var file1Path = bundle.pathForResource("files/file1", ofType: "xm")
//    var paths = bundle.pathsForResourcesOfType("m", inDirectory: bundle.bundlePath)
//    var paths = NSFileManager.defaultManager().contentsOfDirectoryAtPath(bundle.bundlePath, error:nil)
    
//    println(paths);
    
    var error:NSError?
    var fileContent: String? = String.stringWithContentsOfFile(file1Path!, encoding: NSUTF8StringEncoding, error: &error)
    
    if error == nil {
        println(fileContent)
    } else {
        println(error)
    }
}
