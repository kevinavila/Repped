//
//  AddFriendsController.swift
//  Repped
//
//  Created by Kevin Avila on 3/3/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Firebase

class AddFriendsController: UITableViewController {
    
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    
    var user:User? = nil
    var facebookFriends:[String] = []
    var facebookFriendNames:[String:String] = [:]
    var pendingRequests:[Bool] = []
    
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
                        
                        if (self.user?.friendsList[id] == nil) {
                            self.facebookFriends.append(id)
                            self.facebookFriendNames[id] = name
                            
                            if (self.user?.sentRequests[id] != nil) {
                                // We already sent this user a friend request
                                self.pendingRequests.append(true)
                            } else {
                                self.pendingRequests.append(false)
                            }
                        }
                        
                        
                        //TODO: We need to make sure the friend is not already on our friendslist and that we havent
                        //already sent them a friend request. But when grabbing from firebase we get a race condition.
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
        cell.requestSentLabel.isHidden = true
        if (indexPath.row < facebookFriends.count) {
            let id = facebookFriends[(indexPath as IndexPath).row]
            cell.friendNameLabel.text = facebookFriendNames[id]
            cell.friendProfilePicture.image = returnProfilePic(id)
            cell.friendID = id
            
            if (pendingRequests[(indexPath as IndexPath).row]) {
                cell.addFriendButton.isHidden = true
                cell.friendNameLabel.textColor = UIColor.lightGray
                cell.requestSentLabel.isHidden = false
            }
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
    @IBAction func addFriend(_ sender: Any) {
        let button = sender as! UIButton
        let view = button.superview!
        let cell = view.superview as! AddFriendsCell
        let friendID = cell.friendID!
        self.userRef.child("\(friendID)/requests/\((self.user?.uid)!)").setValue(self.user?.name)
        print("SENT REQUEST TO: \(cell.friendNameLabel.text!) with id \(friendID)")
        self.userRef.child("\((self.user?.uid)!)/sentRequests/\(friendID)").setValue(facebookFriendNames[friendID])
        
        toast("Sent \(facebookFriendNames[friendID]) a friend request!")
        
        //FUTURE: Have section for sent requests, and send push notification to user to notify them of the new request
    }
    
    func toast(_ toast: String){
        //Show alert telling the user the song was added to the playback queue
        let requestDecisionAlert = UIAlertController(title: nil, message: toast, preferredStyle: .alert)
        self.present(requestDecisionAlert, animated: true, completion: nil)
        let delay = 0.5 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            requestDecisionAlert.dismiss(animated: true, completion: nil)
        })
        
    }
    
}
