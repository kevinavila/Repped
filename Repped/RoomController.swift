//
//  RoomController.swift
//  Repped
//
//  Created by Wes Draper on 3/4/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import Firebase
import MediaPlayer


class RoomController: UITableViewController  {
        
    var user:User!
    var listeners: [User] = []
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    private var roomRefHandle:FIRDatabaseHandle?
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    private lazy var joinRef:FIRDatabaseReference = FIRDatabase.database().reference().child("joinTable")
    private var joinRefHandle:FIRDatabaseHandle?
    let systemMusicPlayer = MPMusicPlayerController.systemMusicPlayer()
    
    var currentRoom: Room = Room(rid: "-KeKxweex6TnUeKYtqEb", name: "ghhj", leader: "P47ZSoFZF3OSonLUKgIn9e0kXEV2") //this needs to get passed in through segue
    

    
    
    override func viewDidLoad() {
        print("wes_   in RoomController viewDidLoad")
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        observeListeners()
        observeRooms()
    }
    
//    MARK: Table View Functions
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listeners.count
    }
    
    //when I try to implement the custom cell it brakes. cant figure out why
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: nil)
        if let rowData: User = self.listeners[(indexPath as IndexPath).row]{
            cell.textLabel?.text = rowData.name
            cell.detailTextLabel?.text = rowData.uid
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
                    updateListener.append(User(uid: uid, name: uid)) //self.getUserName(uid)
                }
            }
            self.listeners = updateListener
            print ("wes_ listeners ", self.listeners.description)
            self.tableView.reloadData()
        })
    }
    
    //MARK: Firebase Functions
    private func observeRooms() {
        print("wes_ in oserveroom")
        // Listening for changes to y room for sonf
        roomRefHandle = roomRef.observe(.childAdded, with: { (snapshot) -> Void in
            
            let roomData = snapshot.value as! Dictionary<String, AnyObject>
            let rid = snapshot.key
            if rid == self.currentRoom.rid {
                print("wes_ found room")
                self.currentRoom.leader =  roomData["leader"] as! String
                //might need to do something if leader changed
                
                if (roomData["songID"] as! String) != self.currentRoom.songID {
                    print("wes_ seting new song")
                    self.currentRoom.songID = roomData["songID"] as! String
                    self.systemMusicPlayer.setQueueWithStoreIDs([self.currentRoom.songID])
                    self.systemMusicPlayer.play()
                }

            }
        })
    }
    
//    private func getUserName(_ uid: String) -> String{
//        let name = userRef.value(forKey: uid) as? String
//        return name!
//    }


}
