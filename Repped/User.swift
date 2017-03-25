//
//  User.swift
//  Repped
//
//  Created by Kevin Avila on 2/28/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//
import UIKit

internal class User {
    
    internal let uid:String
    internal var name:String
    internal var rep:Int = 0
    internal var email:String = ""
    internal var profilePicture:UIImage = #imageLiteral(resourceName: "noprofile")
    internal var currentRoom:Room?
    internal var friendsList:[String:String] = [:]
    
    init(uid:String, name:String) {
        self.uid = uid
        self.name = name
    }
}
