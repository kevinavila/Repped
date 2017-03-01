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
            if (self.user.currentRoom?.id != room.id) { // user is joining a new room
                
                var oldRoomListeners = self.user.currentRoom?.listeners
                oldRoomListeners!.removeValue(forKey: self.user.uid)
                self.roomRef.child((self.user.currentRoom?.id)!+"/listeners").setValue(oldRoomListeners)
                
                //If there are no longer listeners in the room, destroy the room. Otherwise, app crashes in observe method
                
                self.user.currentRoom = room
                room.listeners.updateValue(self.user.name, forKey: self.user.uid)
                self.roomRef.child(room.id+"/listeners").setValue(room.listeners)
            }
        } else { // user is joining a room for first time
            self.user.currentRoom = room
            room.listeners.updateValue(self.user.name, forKey: self.user.uid)
            self.roomRef.child(room.id+"/listeners").setValue(room.listeners)
        }
        
        self.performSegue(withIdentifier: "showRoom", sender: room)
    }
    
    //MARK: Create New Room
    @IBAction func createNewRoom(_ sender: Any) {
        
        if (self.user.currentRoom == nil) {
            createRoomHelper()
        } else if (self.user.currentRoom?.leader != self.user.uid) {
            createRoomHelper()
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
                let listeners:[String:String] = [self.user.uid : self.user.name]
                let newRoomRef = self.roomRef.childByAutoId()
                let roomItem = [
                    "name": name!,
                    "leader": self.user.uid,
                    "listeners": listeners
                    ] as [String:Any]
                newRoomRef.setValue(roomItem)
                
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
        roomRefHandle = roomRef.observe(.value, with: { (snapshot) -> Void in
            var updatedRooms:[Room] = []
            
            for item in snapshot.children {
                let snapshot = item as! FIRDataSnapshot
                let roomData = snapshot.value as! Dictionary<String, AnyObject>
                let id = snapshot.key
                let name = roomData["name"] as! String
                let leader = roomData["leader"] as! String
                let listeners = roomData["listeners"] as! [String:String]
                let room = Room(id: id, name: name, leader: leader, listeners: listeners)
                if (leader == self.user.uid) { //BAD: leader's current room will be assigned during segue to room screen
                    self.user.currentRoom = room
                }
                updatedRooms.append(room)
            }
            
            self.rooms = updatedRooms
            self.tableView.reloadData()
        })
    }
    
    deinit {
        if let refHandle = roomRefHandle {
            roomRef.removeObserver(withHandle: refHandle)
        }
    }
}
