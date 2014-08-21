//
//  AutoImportTests.swift
//  AutoImportTests
//
//  Created by Luis Floreani on 8/21/14.
//  Copyright (c) 2014 luisfloreani.com. All rights reserved.
//

import Cocoa
import XCTest

class AutoImportTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFile1() {
        var file1 = FileContents.file1()
        var newLine = NSCharacterSet.newlineCharacterSet();
        
        XCTAssertEqual(file1.componentsSeparatedByCharactersInSet(newLine).count, 2)
    }
    
}
