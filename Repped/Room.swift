//
//  Room.swift
//  Repped
//
//  Created by Kevin Avila on 2/26/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

internal class Room {
    
    internal let rid:String
    internal let name:String
    internal var leader:String
    internal var songID:String
    internal var isEmpty:Bool = true
    internal var previousPlayed:[String] = []
    
    init(rid:String, name:String, leader:String) {
        self.rid = rid
        self.name = name
        self.leader = leader
        self.songID = ""
    }
}
