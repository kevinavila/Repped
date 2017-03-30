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
import LNPopupController


class RoomController: UITableViewController  {
        
    var user:User!
    var listeners: [User] = []
    private var currentRoomRef:FIRDatabaseReference?
    private var currentRoomRefHandle:FIRDatabaseHandle?
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    private var userRefHandle:FIRDatabaseHandle?
    private lazy var joinRef:FIRDatabaseReference = FIRDatabase.database().reference().child("joinTable")
    private var joinRefHandle:FIRDatabaseHandle?
     
    
    let systemMusicPlayer = MPMusicPlayerController.systemMusicPlayer()
    
    var global:Global = Global.sharedGlobal
    let sampleData:SampleData = SampleData.sharedSample
    
    var currentRoom:Room!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.user = self.global.user
        
        self.currentRoomRef = FIRDatabase.database().reference().child("rooms/"+(self.global.room?.rid)!)
        
        //Testing Adds Users to a room
        //if self.global.isLeader{
        //    self.sampleData.addUserToMyRoom((self.global.room?.rid)!)
        //}
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        observeListeners()
        observeRooms()
        fillOutListeners()
    }
    
    private func showPop(){
        print("Show Popup Controller")
        let popupContentController = storyboard?.instantiateViewController(withIdentifier: "MusicPlayerController") as! MusicPlayerController
        
        popupContentController.popupItem.accessibilityHint = NSLocalizedString("Double Tap to Expand the Mini Player", comment: "")
        
        tabBarController?.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "")
        
        tabBarController?.presentPopupBar(withContentViewController: popupContentController, animated: true, completion: nil)
        
        self.navigationController!.view.bringSubview(toFront: self.navigationController!.popupContentView)
        
        tabBarController?.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
    }
    
//    MARK: Table View Functions
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listeners.count
    }
    
    //when I try to implement the custom cell it brakes. cant figure out why
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("here")
        let cell = tableView.dequeueReusableCell(withIdentifier: "roomViewCell", for: indexPath) as! RoomViewCell
        if let rowData: User = self.listeners[(indexPath as IndexPath).row]{
            cell.listenerLabel.text = rowData.name
        }
        return cell
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser: User = self.listeners[(indexPath as IndexPath).row]
        
        print("selectedUser", selectedUser.name)
        self.performSegue(withIdentifier: "showProfile", sender: selectedUser)
        
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
                if rid == self.global.room?.rid {
                    print("wes_ appending to listeners")
                    print ("wes_  uid: " + uid + " rid: " + rid)
                    updateListener.append(User(uid: uid, name: ""))
                }
            }
            self.listeners = updateListener
        })
    }
    
    //MARK: Firebase Functions
    private func observeRooms() {
        print("wes_ in oserveroom")
        // Listening for changes to y room for sonf
        currentRoomRefHandle = currentRoomRef?.observe(.value, with: { (snapshot) -> Void in
            
            let roomData = snapshot.value as! Dictionary<String, AnyObject>
            let rid = snapshot.key
            if rid == self.global.room?.rid {
                print("wes_ found room")
                self.global.room?.leader =  roomData["leader"] as! String
                //might need to do something if leader changed
                if let _ = roomData["songID"] {
                    if (roomData["songID"] as! String) != self.global.room?.songID {
                        print("wes_ seting new song0")
                        self.global.room?.songID = roomData["songID"] as! String
                    self.global.systemMusicPlayer.setQueueWithStoreIDs([(self.global.room?.songID)!])
                        self.global.systemMusicPlayer.play()
                        self.global.song = Song(trackId: (self.global.room?.songID)!){
                            print("completion handler?")
                            self.showPop()
                        }
                    }
                }

            }
        })
    }
    
    //MARK: Firebase Functions
    private func fillOutListeners() {
        // Listening for changes to y room for sonf
        userRefHandle = userRef.observe(.childAdded, with: { (snapshot) -> Void in
            
            let uid = snapshot.key
            let value = snapshot.value
            
            //need to hanbdle errors for optionals -> if let ...
            let userData = value as! [String:Any]
            let user = [
                "name": userData["name"] as! String,
                "email": userData["email"] as! String,
                "rep": 0,
                "id": userData["id"] as! String
            ] as [String:Any]
            
            //TODO figure out why this doesnt work on the first time
            for curUser in self.listeners {
                if curUser.uid == uid {
                    curUser.name = (user["name"] as? String)!
                    print("listner name_ ", curUser.name)
                    curUser.profilePicture = self.returnProfilePic(uid)
                }
            }
            self.tableView.reloadData()
            self.global.room?.isEmpty = (self.listeners.count > 1)
            print("reload Table")
        })
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
    
//   TODO need deinits
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile"{
            if let nextScene = segue.destination as? ProfileController{
                nextScene.user = sender as! User
                
            }
        }
    }

    
}
