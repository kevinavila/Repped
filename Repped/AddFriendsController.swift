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
    var facebookFriends:[String] = []
    var facebookFriendNames:[String:String] = [:]
    
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
                        
                        self.facebookFriends.append(id)
                        self.facebookFriendNames[id] = name
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "addFriendsCell", for: indexPath) as! AddFriendsCell
        if (indexPath.row < facebookFriends.count) {
            let id = facebookFriends[(indexPath as IndexPath).row]
            cell.friendNameLabel.text = facebookFriendNames[id]
            cell.friendProfilePicture.image = returnProfilePic(id)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Route to user's profile
    }
    
    //MARK: Facebook Functions
    private func returnProfilePic(_ id:String) -> UIImage{
        let facebookProfileUrl = NSURL(string: "http://graph.facebook.com/\(id)/picture?type=large")
        
        let image:UIImage
        if let data = NSData(contentsOf: facebookProfileUrl as! URL) {
            image = UIImage(data: data as Data)!
        } else {
            image = #imageLiteral(resourceName: "noprofile")
        }
        return image
    }
    
    //MARK: Add Function
}
