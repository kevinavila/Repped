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
    
    var senderName: String?
    private var rooms:[Room] = []
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    private var roomRefHandle:FIRDatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let newRoomRef = roomRef.childByAutoId()
        let roomItem = [
            "name": "TestRoom"
        ]
        newRoomRef.setValue(roomItem)
        
        observeRooms()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "homeViewCell", for: indexPath) as! HomeViewCell
        if (indexPath.row < rooms.count) {
            cell.roomName.text = rooms[(indexPath as IndexPath).row].name
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    // Firebase related methods
    
    private func observeRooms() {
        // Use the observe method to listen for new rooms being written to the Firebase DB
        roomRefHandle = roomRef.observe(.childAdded, with: { (snapshot) -> Void in
            let roomData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let name = roomData["name"] as! String!, name.characters.count > 0 {
                self.rooms.append(Room(id: id, name: name))
                self.tableView.reloadData()
            } else {
                print("Error! Could not decode room data")
            }
        })
    }
    
    deinit {
        if let refHandle = roomRefHandle {
            roomRef.removeObserver(withHandle: refHandle)
        }
    }
}
