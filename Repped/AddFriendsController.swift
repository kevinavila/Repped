//
//  AddFriendsController.swift
//  Repped
//
//  Created by Kevin Avila on 3/3/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import FBSDKCoreKit

class AddFriendsController: UITableViewController {
    
    var user:User? = nil
    var facebookFriends:[String:String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "friends"]).start(completionHandler: { (connection, result, error) -> Void in
            let fBData = result as! [String:Any]
            if (error == nil) {
                
                //grab facebook friends
                if let resultdict = fBData["friends"] {
                    let data : NSArray = (resultdict as AnyObject).object(forKey: "data") as! NSArray
                
                    for entry in data {
                        let valueDict : NSDictionary = entry as! NSDictionary
                        let id = valueDict.object(forKey: "id") as! String
                        let name = valueDict.object(forKey: "name") as! String
                        self.facebookFriends[id] = name
                    }
                }
                
                self.tableView.reloadData()
            }
        })
    }
    
    
    //MARK: Table View Functions
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return facebookFriends.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
