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
    private var rooms:[String:Room] = [:]
    private var onlinefriends:[User] = []
    private var offlineFriendList:[String:String] = [:]
    private var friendRequests:[String:String] = [:]
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    private lazy var joinRef:FIRDatabaseReference = FIRDatabase.database().reference().child("joinTable")
    private var roomRefHandle:FIRDatabaseHandle?
    private var joinRefHandle:FIRDatabaseHandle?
    
    var global:Global = Global.sharedGlobal
    // Use for Testing only
    let sampleData:SampleData = SampleData.sharedSample
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.navigationController?.navigationBar.barTintColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1.0)
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
       
        // Use for testing
//        sampleData.makeSampleUsers()
//        self.offlineFriendList = self.sampleData.testFriendList
        
        if let savedUser = defaults.object(forKey: "User") {
            // When do we update the user saved in defaults? (e.g. if their friends list updates?)
            print("User was loaded from User Defaults")
            print(savedUser)
            self.global.user = User(userDict: savedUser as! [String:Any])
            self.global.user?.profilePicture = self.returnProfilePic((self.global.user?.uid)!)
            self.offlineFriendList = (self.global.user?.friendsList)!
            self.getFriends()
        } else {
            self.userRef.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
                
                if (snapshot.hasChild(FBSDKAccessToken.current().userID)) {
                    print("User was loaded from Firbase")
                    let results = snapshot.value as! Dictionary<String, AnyObject>
                    let userData = results[FBSDKAccessToken.current().userID] as! Dictionary<String, AnyObject>
                    self.setUser(userData: userData)
                    self.observeJoinTable()
                    self.observeRep()
                } else {
                    print("Making new user")
                    // Initialize new user
                    self.newUser()
                }
            })
        }
        
        self.observeRooms()
    }
 
    private func getFriends(){
        // Update user friends and requests
        let specficUserRef = userRef.child((self.global.user?.uid)!)
        specficUserRef.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
            let userData = snapshot.value as! Dictionary<String, AnyObject>
            if (userData["friends"] != nil) {
                self.global.user?.friendsList = userData["friends"] as! [String : String]
                self.offlineFriendList = (self.global.user?.friendsList)!
            }
            if (userData["requests"] != nil) {
                self.global.user?.friendRequests = userData["requests"] as! [String : String]
                self.friendRequests = (self.global.user?.friendRequests)!
            }
            if (userData["sentRequests"] != nil) {
                self.global.user?.sentRequests = userData["sentRequests"] as! [String : String]
            }
            
            self.defaults.set(self.global.user?.deconstructUser(), forKey: "User")
            self.observeJoinTable()
            self.observeRep()
            self.tableView.reloadData()
        })
        
        
    }

    
    private func setUser(userData: Dictionary<String, AnyObject>) {
        self.global.user = User(uid: userData["id"] as! String, name: userData["name"] as! String)
        self.global.user?.email =  userData["email"] as! String
        self.global.user?.rep = userData["rep"] as! Int
        if (userData["friends"] != nil) {
            self.global.user?.friendsList = userData["friends"] as! [String : String]
            self.offlineFriendList = (self.global.user?.friendsList)!
        }
        if (userData["requests"] != nil) {
            self.global.user?.friendRequests = userData["requests"] as! [String : String]
            self.friendRequests = (self.global.user?.friendRequests)!
        }
        if (userData["sentRequests"] != nil) {
            self.global.user?.sentRequests = userData["sentRequests"] as! [String : String]
        }
        self.global.user?.profilePicture = self.returnProfilePic(userData["id"] as! String)
       
        self.defaults.set(self.global.user?.deconstructUser(), forKey: "User")
        print("Saving user to defaults 1")
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
                    
                    // Set user info in firebase
                    let user = [
                        "name": fBData["name"]!,
                        "email": fBData["email"]!,
                        "rep": 0,
                        "id": fBData["id"]!,
                        "friends": [:],
                        "requests": [:],
                        "sentRequest": [:],
                        ] as [String:Any]
                    self.userRef.child(fBData["id"] as! String).setValue(user)
                    
                    
                    self.defaults.set(self.global.user?.deconstructUser(), forKey: "User")
                    print("Saving user to defaults 2")
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
        if section == 0 {
            return onlinefriends.count
        } else if section == 1 {
            return offlineFriendList.count
        } else {
            return self.friendRequests.count
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "homeViewCell", for: indexPath) as! HomeViewCell
            if (indexPath.row < onlinefriends.count) {
                let friend = onlinefriends[(indexPath as IndexPath).row]
                cell.friendName.text = friend.name
                cell.roomName.text = rooms[friend.rid!]?.name
                return cell
            }
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "homeViewOfflineCell", for: indexPath) as! HomeViewOfflineCell
            if (indexPath.row < self.offlineFriendList.count) {
                print("building table", self.offlineFriendList.count)
                cell.offlineFriendNameLabel.text = Array(self.offlineFriendList.values)[indexPath.row]
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "homeViewRequestCell", for: indexPath) as! HomeViewRequestCell
            if (indexPath.row < friendRequests.count) {
                cell.friendID = Array(friendRequests.keys)[indexPath.row]
                cell.pendingFriendLabel.text = Array(friendRequests.values)[indexPath.row]
                return cell
            }
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "LIVE"
        } else if section == 1 {
            return "Offline"
        } else {
            return "Friend Requests"
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        if (section == 0) {
            header.textLabel?.textColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
        } else {
            header.textLabel?.textColor = UIColor.lightGray
        }

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let friend = onlinefriends[(indexPath as IndexPath).row]
        
            let room = rooms[friend.rid!]

            print("Current global room: \(self.global.room?.rid)")
            if (self.global.room != nil) {
                if (self.global.room?.rid != room?.rid) {
                    print("Joing a new room")
                    //New previous Song List 
                    self.global.previousSongs = [Song]()
                    // User is attempting to joining a new room
                    if (self.global.room?.leader != self.global.user?.uid) {
                        userLeavingRoom()
                        userJoiningRoom(room: room!)
                        self.performSegue(withIdentifier: "showRoom", sender: room)
                    } else {
                        if (self.global.room?.isEmpty)! {
                            // User is leader of their room but it's empty. Let them join the other room and destroy their current one
                            let oldRid = self.global.room?.rid
                            userLeavingRoom()
                            userJoiningRoom(room: room!)
                            roomRef.child(oldRid!).removeValue()
                            self.performSegue(withIdentifier: "showRoom", sender: room)
                        } else {
                            // User is leader of their room and there are listneners. Show message saying they must end room to leave
                        }
                    }
                } else {
                    self.performSegue(withIdentifier: "showRoom", sender: room)
                }
            } else {
                // User is joining a room for first time
                userJoiningRoom(room: room!)
                self.performSegue(withIdentifier: "showRoom", sender: room)
            }
        } else {
            
        }
        
    }
    
    //MARK: Create New Room
    @IBAction func createNewRoom(_ sender: Any) {
        if (self.global.room == nil) {
            print("option 1")
            createRoomHelper()
        } else if (self.global.room?.leader != self.global.user?.uid) {
             print("option 2")
            createRoomHelper()
        } else {
             print("option 3")
            if (self.global.room?.isEmpty)! {
                let oldRid = self.global.room?.rid
                createRoomHelper()
                roomRef.child(oldRid!).removeValue()
            }
            // User is leader of their current room. Do something.

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
    
    //MARK: Accept Friend Requests
    @IBAction func acceptingFriend(_ sender: Any) {
        let button = sender as! UIButton
        let view = button.superview!
        let cell = view.superview as! HomeViewRequestCell
        let friendID = cell.friendID!
        
        // Firebase updates
        self.userRef.child("\((self.global.user?.uid)!)/friends/\(friendID)").setValue(self.friendRequests[friendID])
        self.userRef.child("\(friendID)/friends/\((self.global.user?.uid)!)").setValue(self.global.user?.name)
        self.userRef.child("\((self.global.user?.uid)!)/requests/\(friendID)").removeValue()
        self.userRef.child("\(friendID)/sentRequests/\((self.global.user?.uid)!)").removeValue()
        
        
        toast("You are now friends with \(self.friendRequests[friendID]!)!")
        
        // Local updates
        self.global.user?.friendsList.updateValue(self.friendRequests[friendID]!, forKey: friendID)
        self.friendRequests.removeValue(forKey: friendID)
        self.global.user?.friendRequests.removeValue(forKey: friendID)
        self.tableView.reloadData()
    }
    
    @IBAction func rejectingFriend(_ sender: Any) {
        let button = sender as! UIButton
        let view = button.superview!
        let cell = view.superview as! HomeViewRequestCell
        let friendID = cell.friendID!
        
        // Firebase updates
        self.userRef.child("\((self.global.user?.uid)!)/requests/\(friendID)").removeValue()
        self.userRef.child("\(friendID)/sentRequests/\((self.global.user?.uid)!)").removeValue()
        
        toast("Declined \(self.friendRequests[friendID]!).")
        
        // Local updates
        self.friendRequests.removeValue(forKey: friendID)
        self.global.user?.friendRequests.removeValue(forKey: friendID)
        self.tableView.reloadData()

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
                self.global.isLeader = true
                // Segue to room
                self.performSegue(withIdentifier: "showRoom", sender: self.global.room)
            }
            
            self.rooms.updateValue(room, forKey: rid)
        })
    }
    
    private func observeJoinTable() {
        // Observe for any changes made to the rooms in the Firebase DB
        // What about when a room is destroyed?
        joinRefHandle = joinRef.observe(.childAdded, with: { (snapshot) -> Void in
            let rid = snapshot.value as! String
            let uid = snapshot.key 

            
            if let name = self.offlineFriendList[uid] {
                let friend = User(uid: uid, name: name)
                friend.rid = rid
                self.onlinefriends.append(friend)
                print("added ", friend.name)
                print(self.offlineFriendList.count)
                self.offlineFriendList.removeValue(forKey: uid)
                print(self.offlineFriendList.count)
            }
            
            self.tableView.reloadData()
        })
    }
    
    // Listen for changes in user's rep
    private func observeRep() {
        var userRepHandle:FIRDatabaseHandle?
        let repUserRef = userRef.child("\((self.global.user?.uid)!)/rep")
        userRepHandle = repUserRef.observe(.value, with: { (snapshot) -> Void in
            let rep = snapshot.value as! Int
            print("Did my rep change? \(String(rep))")
            self.global.user?.rep = rep
            self.defaults.set(self.global.user?.deconstructUser(), forKey: "User")
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
    
    //MARK: De-initialization  of Firebase handles
    deinit {
        if let refHandle = roomRefHandle {
            roomRef.removeObserver(withHandle: refHandle)
        }
        if let refHandle = joinRefHandle {
            joinRef.removeObserver(withHandle: refHandle)
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
