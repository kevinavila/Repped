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

class HomeController: UITableViewController {
    
    //MARK: Properties
    private var rooms:[Room] = []
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    private lazy var joinRef:FIRDatabaseReference = FIRDatabase.database().reference().child("joinTable")
    private var roomRefHandle:FIRDatabaseHandle?
    
    var global:Global = Global.sharedGlobal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // Initialize user info
        let currentUser = FIRAuth.auth()?.currentUser
        let uid = currentUser?.uid
        let name = currentUser?.displayName
        self.global.user = User(uid: uid!, name: name!)
        
        fillInUser()
        
        observeRooms()
    }
    
        private func fillInUser(){
                // gonna need to check if i already exist to not override rep score TODO
                if((FBSDKAccessToken.current()) != nil){
                    FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email"]).start(completionHandler: { (connection, result, error) -> Void in
                        let fBData = result as! [String:Any]
                        if (error == nil){
                            print(result)
                            let user = [
                                "name": fBData["name"],
                                "email": fBData["email"],
                                "rep": 0,
                                "id": fBData["id"]
                                ] as [String:Any]
                            self.userRef.child(fBData["id"] as! String).setValue(user)
                            self.global.user = User(uid: fBData["id"] as! String, name: fBData["name"] as! String)
                            self.global.user?.email =  fBData["email"] as! String
                            self.global.user?.profilePicture = self.returnProfilePic(fBData["id"] as! String)
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
    
    
    //MARK: Segue
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//       print("wes_ prepareing for showroom seque user ->%@ id %@ destination %@", self.global.user, segue.identifier ?? "tits", segue.destination)
//        if segue.identifier == "showRoom", let nextScene = segue.destination as? UITabBarController{
//            if let roomVC = nextScene.viewControllers?.first as? RoomController {
//                print("wont get here befiore viewdidload")
//                roomVC.user = self.global.user
//                print("wes_ added user to show room segue %@ user-> ", nextScene, self.global.user)
//            }
//            else {
//                
//            }
//            
//        }
//        else {
//            
//        }
//
//    }
}
