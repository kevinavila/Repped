//
//  Room.swift
//  Repped
//
//  Created by Kevin Avila on 2/26/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

internal class Room {
    
    internal let id:String
    internal let name:String
    internal var leader:String
    internal var listeners:[String:String]
    
    init(id:String, name:String, leader:String,  listeners:[String:String]) {
        self.id = id
        self.name = name
        self.leader = leader
        self.listeners = listeners
    }
}
