//
//  Global.swift
//  Repped
//
//  Created by Wes Draper on 3/9/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import MediaPlayer
import LNPopupController

class Global {
    
    // Now Global.sharedGlobal is your singleton, no need to use nested or other classes
    static let sharedGlobal = Global()
    
    var queue: [Song] = []
    var idQueue: [String] = []
    var repHistory: [String:String] = [:]  //trackId leaderUID
    let systemMusicPlayer = MPMusicPlayerController.systemMusicPlayer()
    
    private init() {
        print("MyClass Initialized")
    }
    
    var thing:Int = 7
    
    var testString: String="Test" //for debugging
    
    var user:User? = nil
    
    var room:Room? = nil
    
    var song:Song? = nil
    
    var isLeader:Bool = false
    
}

