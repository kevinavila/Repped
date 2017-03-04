//
//  RoomController.swift
//  Repped
//
//  Created by Wes Draper on 3/4/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import Firebase


class RoomController: UITableViewController  {
        
    var user:User!
    var listeners: [User] = []
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    private lazy var joinRef:FIRDatabaseReference = FIRDatabase.database().reference().child("joinTable")
    private var joinRefHandle:FIRDatabaseHandle?

    
    
    override func viewDidLoad() {
        print("wes_   in RoomController viewDidLoad")
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        observeListeners()
        print(listeners)
    }
    
//    MARK: Table View Functions
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listeners.count
    }
    
    //when I try to implement the custom cell it brakes. cant figure out why
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = RoomViewCell()
        if (indexPath.row < listeners.count) {
            print("wes_ try")
//            cell.listenerLabel.text = listeners[(indexPath as IndexPath).row].name
            print("wes_ name of listener", listeners[(indexPath as IndexPath).row].name)
            
        }
        return cell
    }




//        MARK: Firebase Functions
    private func observeListeners() {
        print("wes_   in RoomController observeListeners")
        // Observe for any changes made to the rooms in the Firebase DB
        joinRefHandle = joinRef.observe(.value, with: { (snapshot) -> Void in
            var updateListener:[User] = []
            print ("wes_  observing")
            
            for item in snapshot.children {
                let snapshot = item as! FIRDataSnapshot
                let uid = snapshot.key
                let rid = snapshot.value as! String
                print ("wes_  uid: " + uid + " rid: " + rid)
                if rid == "-KeKxweex6TnUeKYtqEb" {
                    print("wes_ appending to listeners")
                    updateListener.append(User(uid: uid, name: uid))
                }
            }
            self.listeners = updateListener
            print ("wes_ lestners ", self.listeners.description)
            self.tableView.reloadData()
        })
    }
    
    deinit {
        if let refHandle = joinRefHandle {
            joinRef.removeObserver(withHandle: refHandle)
        }
    }


}
