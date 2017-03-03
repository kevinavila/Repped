//
//  RoomController.swift
//  Repped
//
//  Created by Wes Draper on 3/1/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import Firebase

class RoomController: UITableViewController{
   
    @IBOutlet weak var listenerTable: UITableView!


    var user:User!
    var listeners: [User] = []
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    private var roomRefHandle:FIRDatabaseHandle?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.listenerTable.delegate = self
        self.listenerTable.dataSource = self
        
        // Initialize user info
        let currentUser = FIRAuth.auth()?.currentUser
        let uid = currentUser?.uid
        let name = currentUser?.displayName
        self.user = User(uid: uid!, name: name!)
        print(listeners)
        
        
        observeListeners()
        print(listeners)
    }
    
    
    
    //MARK: Table View Functions
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listeners.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "roomViewCell", for: indexPath) as! RoomViewCell
        if (indexPath.row < listeners.count) {
            cell.listenerLabel.text = listeners[(indexPath as IndexPath).row].name
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedListener = listeners[(indexPath as IndexPath).row]
    }

    
    
    
    
    
//    MARK: Firebase Functions
    private func observeListeners() {
        // Observe for any changes made to the rooms in the Firebase DB
        roomRefHandle = roomRef.observe(.value, with: { (snapshot) -> Void in
            var updatedRooms:[Room] = []
            var updateListener:[User] = []
            
            for item in snapshot.children {
                let snapshot = item as! FIRDataSnapshot
                let roomData = snapshot.value as! Dictionary<String, AnyObject>
                let rid = snapshot.key
                let roomListeners = roomData["listeners"] as! [String:String]
                if let myUser = roomListeners[self.user.uid] {
                    for (listenerUID, listenerName) in roomListeners {
                        updateListener.append(User(uid: listenerUID, name: listenerName))
                    }
                }
            }
            self.listeners = updateListener
            self.tableView.reloadData()
        })
    }
    
    deinit {
        if let refHandle = roomRefHandle {
            roomRef.removeObserver(withHandle: refHandle)
        }
    }



}
