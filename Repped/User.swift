//
//  User.swift
//  Repped
//
//  Created by Kevin Avila on 2/28/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

internal class User {
    
    internal let uid:String
    internal var name:String
    internal var rep:Int = 0
    internal var currentRoom:Room?
    
    init(uid:String, name:String) {
        self.uid = uid
        self.name = name
    }
}
