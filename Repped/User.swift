//
//  User.swift
//  Repped
//
//  Created by Kevin Avila on 2/28/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//
import UIKit

internal class User : NSObject {
    
    internal let uid:String
    internal var name:String
    internal var rep:Int = 0
    internal var email:String = ""
    internal var profilePicture:UIImage = #imageLiteral(resourceName: "noprofile")
    internal var currentRoom:Room?
    internal var rid:String?
    internal var friendsList:[String:String] = [:]
    internal var friendRequests:[String:String] = [:]
    internal var sentRequests:[String:String] = [:]
    
    init(uid:String, name:String) {
        self.uid = uid
        self.name = name
    }
    
    init(userDict:[String:Any]){
        self.uid = userDict["uid"] as! String
        self.name = userDict["name"] as! String
        self.rep = userDict["rep"] as! Int
        self.friendsList = userDict["friendList"] as! [String : String]
        self.friendRequests = userDict["friendRequests"] as! [String : String]
        self.sentRequests = userDict["sentRequests"] as! [String : String]
    }
    
    public func deconstructUser() -> [String:Any]{
        var result = [String:Any]()
        result["uid"] = self.uid
        result["name"] = self.name
        result["rep"] = self.rep
        result["email"] = self.email
        result["friendList"] = self.friendsList
        result["friendRequests"] = self.friendRequests
        result["sentRequests"] = self.sentRequests
        
        return result
    }
}
