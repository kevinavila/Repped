//
//  HomeController.swift
//  Repped
//
//  Created by Kevin Avila on 2/17/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

class HomeController: UITableViewController {
    
    //MARK: Properties
    private var rooms:[Room] = []
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    private lazy var joinRef:FIRDatabaseReference = FIRDatabase.database().reference().child("joinTable")
    private var roomRefHandle:FIRDatabaseHandle?
    
    var global:Global = Global.sharedGlobal
    //Use for Testing only
    let sampleData:SampleData = SampleData.sharedSample
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
       
        //Use for testing
        //sampleData.makeSampleUsers()
        
        
        self.userRef.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
            
            if (snapshot.hasChild(FBSDKAccessToken.current().userID)) {
                let results = snapshot.value as! Dictionary<String, AnyObject>
                let userData = results[FBSDKAccessToken.current().userID] as! Dictionary<String, AnyObject>
                self.setUser(userData: userData)
            } else {
                // initialize new user
                self.newUser()
            }
        })
        
        //only run if user already exists in Firebase, checking for new friends
        //self.getFriends()
        
        
        self.observeRooms()
    }
 
    private func getFriends(){
        let params = ["fields": "id, name"]
        FBSDKGraphRequest(graphPath: "me/friends", parameters: params).start { (connection, result , error) -> Void in
            
            var friendList: [String:String] = [:]
            
            if error != nil {
                print("wes_ error: ", error!)
            } else {
                let resultdict = result as! NSDictionary
                let data : NSArray = resultdict.object(forKey: "data") as! NSArray
  
                for entry in data {
                    let valueDict : NSDictionary = entry as! NSDictionary
                    let id = valueDict.object(forKey: "id") as! String
                    let name = valueDict.object(forKey: "name") as! String
                    friendList[id] = name
                }
            }
            self.global.user?.friendsList.update(other: friendList)
            
            //update firebase
            self.userRef.child("\((self.global.user?.uid)!)/friends").setValue(friendList)
        }
        
        
    }

    
    private func setUser(userData: Dictionary<String, AnyObject>) {
        self.global.user = User(uid: userData["id"] as! String, name: userData["name"] as! String)
        self.global.user?.email =  userData["email"] as! String
        self.global.user?.rep = userData["rep"] as! Int
        if (userData["friends"] != nil) {
            self.global.user?.friendsList = userData["friends"] as! [String : String]
        }
        self.global.user?.profilePicture = self.returnProfilePic(userData["id"] as! String)
    }
    
    private func newUser(){
        print(((FBSDKAccessToken.current()) != nil))
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email"]).start(completionHandler: { (connection, result, error) -> Void in
                let fBData = result as! [String:Any]
                if (error == nil){
                    self.global.user = User(uid: fBData["id"] as! String, name: fBData["name"] as! String)
                    self.global.user?.email =  fBData["email"] as! String
                    self.global.user?.profilePicture = self.returnProfilePic(fBData["id"] as! String)
                    
                    //build friendlist
//                    var friendList: [String:String] = [:]
//                    
//                    if let resultdict = fBData["friends"]{
//                        let data : NSArray = (resultdict as AnyObject).object(forKey: "data") as! NSArray
//                        
//                        for entry in data {
//                            let valueDict : NSDictionary = entry as! NSDictionary
//                            let id = valueDict.object(forKey: "id") as! String
//                            let name = valueDict.object(forKey: "name") as! String
//                            friendList[id] = name
//                        }
//                    }
                    
                    //TODO REMOVE ADDINGMORE FRIENDS 
                    //for (key,value) in self.sampleData.testFriendList {
                    //  friendList.updateValue(value, forKey:key)
                    //}
                
                    //self.global.user?.facebookFriendsList.update(other: friendList)
                    
                    
                    //set user info in firebase
                    let user = [
                        "name": fBData["name"]!,
                        "email": fBData["email"]!,
                        "rep": 0,
                        "id": fBData["id"]!,
                        "friends": [:]
                        ] as [String:Any]
                    self.userRef.child(fBData["id"] as! String).setValue(user)
                    
                }
            })
        }
    }
    
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
    
    
    //MARK: Table View Functions
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "homeViewCell", for: indexPath) as! HomeViewCell
        if (indexPath.row < rooms.count) {
            cell.roomName.text = rooms[(indexPath as IndexPath).row].name
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let room = rooms[(indexPath as IndexPath).row]
        
        print("self.global.room", self.global.room?.rid)
        if (self.global.room != nil) {
            if (self.global.room?.rid != room.rid) {
                print("joing room not already in")
                // User is attempting to joining a new room
                if (self.global.room?.leader != self.global.user?.uid) {
                    
                    userLeavingRoom()
                    userJoiningRoom(room: room)
                    self.performSegue(withIdentifier: "showRoom", sender: room)
                } else {
                    // User is leader of their current room. Do something.
                    
                }
            } else {
                self.performSegue(withIdentifier: "showRoom", sender: room)
            }
        } else {
            // User is joining a room for first time
            userJoiningRoom(room: room)
            self.performSegue(withIdentifier: "showRoom", sender: room)
        }
        
    }
    
    //MARK: Create New Room
    @IBAction func createNewRoom(_ sender: Any) {
        
        if (self.global.room == nil) {
            createRoomHelper()
            // Segue to room
        } else if (self.global.room?.leader != self.global.user?.uid) {
            createRoomHelper()
            // Segue to room
        } else {
            // User cannot creat new room because he/she is currently leading the room they're in
        }
    }
    
    private func createRoomHelper() {
        let alertController = UIAlertController(title: "New Room", message: "Please enter a name for your room.", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Create", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                // store room in database
                let name = field.text
                let newRoomRef = self.roomRef.childByAutoId()
                let roomItem = [
                    "name": name!,
                    "leader": self.global.user?.uid
                    ] as [String:Any]
                newRoomRef.setValue(roomItem)
                
                if (self.global.room != nil) {
                    self.userLeavingRoom()
                }
                
            } else {
                // user did not fill field
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Room name"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: Firebase Functions
    private func observeRooms() {
        // Observe for any changes made to the rooms in the Firebase DB
        // What about when a room is destroyed?
        roomRefHandle = roomRef.observe(.childAdded, with: { (snapshot) -> Void in
            
            let roomData = snapshot.value as! Dictionary<String, AnyObject>
            let rid = snapshot.key
            let name = roomData["name"] as! String
            let leader = roomData["leader"] as! String
            let room = Room(rid: rid, name: name, leader: leader)
            if (leader == self.global.user?.uid) {
                self.userJoiningRoom(room: room)
            }
            
            self.rooms.append(room)
            self.tableView.reloadData()
        })
    }
    
    private func userJoiningRoom(room: Room) {
        print("joing room_ ", room.rid)
        self.global.room = Room(rid: room.rid, name: room.name, leader: room.leader)
        print("should have a room", self.global.room?.rid)
        self.joinRef.child((self.global.user?.uid)!).setValue(room.rid)
    }
    
    private func userLeavingRoom() {
        self.joinRef.child((self.global.user?.uid)!).removeValue()
    }
    
    deinit {
        if let refHandle = roomRefHandle {
            roomRef.removeObserver(withHandle: refHandle)
        }
    }
    
    @IBAction func profileClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "showProfile", sender: self.global.user)
    }
    
    //MARK: Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            if let nextScene = segue.destination as? ProfileController {
                nextScene.user = self.global.user
            }
        } else if segue.identifier == "showAddFriends" {
            if let nextScene = segue.destination as? AddFriendsController {
                nextScene.user = self.global.user
            }
        }
    }
    
}
