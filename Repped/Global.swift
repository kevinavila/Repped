//
//  Global.swift
//  Repped
//
//  Created by Wes Draper on 3/9/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit

class Global {
    
    // Now Global.sharedGlobal is your singleton, no need to use nested or other classes
    static let sharedGlobal = Global()
    
    private init() {
        print("MyClass Initialized")
    }
    
    var thing:Int = 7
    
    var testString: String="Test" //for debugging
    
    var user:User? = nil
    
    var room:Room? = nil
    
    var song:Song? = nil
    
}

