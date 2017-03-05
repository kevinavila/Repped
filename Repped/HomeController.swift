//
//  HomeController.swift
//  Repped
//
//  Created by Kevin Avila on 2/17/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import Firebase

class HomeController: UITableViewController {
    
    //MARK: Properties
    var user:User!
    private var rooms:[Room] = []
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    private lazy var joinRef:FIRDatabaseReference = FIRDatabase.database().reference().child("joinTable")
    private var roomRefHandle:FIRDatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // Initialize user info
        let currentUser = FIRAuth.auth()?.currentUser
        let uid = currentUser?.uid
        let name = currentUser?.displayName
        self.user = User(uid: uid!, name: name!)
        
//        postUser()
        
        observeRooms()
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
        
        if (self.user.currentRoom != nil) {
            if (self.user.currentRoom?.rid != room.rid) {
                // User is attempting to joining a new room
                if (self.user.currentRoom?.leader != self.user.uid) {
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
        
        if (self.user.currentRoom == nil) {
            createRoomHelper()
            // Segue to room
        } else if (self.user.currentRoom?.leader != self.user.uid) {
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
                    "leader": self.user.uid
                    ] as [String:Any]
                newRoomRef.setValue(roomItem)
                
                if (self.user.currentRoom != nil) {
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
            if (leader == self.user.uid) {
                self.userJoiningRoom(room: room)
            }
            
            self.rooms.append(room)
            self.tableView.reloadData()
        })
    }
    
    private func userJoiningRoom(room: Room) {
        self.user.currentRoom = room
        self.joinRef.child(self.user.uid).setValue(room.rid)
    }
    
    private func userLeavingRoom() {
        self.joinRef.child(self.user.uid).removeValue()
    }
    
    deinit {
        if let refHandle = roomRefHandle {
            roomRef.removeObserver(withHandle: refHandle)
        }
    }
    
    
    private func postUser(){
        let userEntry = ["name": self.user.name] //, "rep": String(self.user.rep)
        self.roomRef.child(self.user.uid).setValue(userEntry)
    }
    
    //MARK: Segue
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//       print("wes_ prepareing for showroom seque")
//        if segue.identifier == "showRoom", let nextScene = segue.destination as? RoomController{
//            nextScene.user = self.user
//            print("wes_ added user to show room segue")
//        }
//
//    }
}
