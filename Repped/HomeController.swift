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
    var userName:String?
    private var rooms:[Room] = []
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    private var roomRefHandle:FIRDatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let user = FIRAuth.auth()?.currentUser
        userName = user?.displayName
        
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
        self.performSegue(withIdentifier: "showRoom", sender: room)
    }
    
    //MARK: Create New Room
    @IBAction func createNewRoom(_ sender: Any) {
        let alertController = UIAlertController(title: "New Room", message: "Please enter a name for your room.", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Create", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                // store room in database
                let name = field.text
                let listeners = [self.userName]
                let newRoomRef = self.roomRef.childByAutoId()
                let roomItem = [
                    "name": name!,
                    "leader": self.userName!,
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
                let room = Room(id: id, name: name)
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
