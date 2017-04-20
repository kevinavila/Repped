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
    
    var listeners: [User] = []
    private var currentRoomRef:FIRDatabaseReference?
    private var currentRoomRefHandle:FIRDatabaseHandle?
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    private var userRefHandle:FIRDatabaseHandle?
    private lazy var joinRef:FIRDatabaseReference = FIRDatabase.database().reference().child("joinTable")
    private var joinRefHandle:FIRDatabaseHandle?
     
    var popupContentController:MusicPlayerController?
    let systemMusicPlayer = MPMusicPlayerController.systemMusicPlayer()
    
    var global:Global = Global.sharedGlobal
    let sampleData:SampleData = SampleData.sharedSample
    
    var currentRoom:Room!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //cant figure out how to set a title TODO
        //navigationController?.navigationBar.topItem?.title = "Listeners"
        
        
        self.currentRoomRef = FIRDatabase.database().reference().child("rooms/"+(self.global.room?.rid)!)
        
        //Testing Adds Users to a room
        //if self.global.isLeader{
        //    self.sampleData.addUserToMyRoom((self.global.room?.rid)!)
        //}
        
        self.global.systemMusicPlayer.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(songInMusicPlayerChanged),
            name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
            object: nil)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        observeListeners()
        observeRooms()
    }
    
    private func showPop(){
        print("Show Popup Controller")
        popupContentController = storyboard?.instantiateViewController(withIdentifier: "MusicPlayerController") as? MusicPlayerController
        
        popupContentController?.popupItem.accessibilityHint = NSLocalizedString("Double Tap to Expand the Mini Player", comment: "")
        
        tabBarController?.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "")
        
        tabBarController?.presentPopupBar(withContentViewController: popupContentController!, animated: true, completion: nil)
        
        self.navigationController!.view.bringSubview(toFront: self.navigationController!.popupContentView)
        
        tabBarController?.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
    }
    
    private func updatePopup(){
        popupContentController?.songNameLabel.text = (self.global.song?.trackName)!
        popupContentController?.popupItem.title = (self.global.song?.trackName)!
        
        popupContentController?.albumArtImageView.image = (self.global.song?.artWorkLarge)!
        popupContentController?.popupItem.image = (self.global.song?.artWorkSmall)!
        
        popupContentController?.albumNameLabel.text = (self.global.song?.artistName)!
        popupContentController?.popupItem.subtitle = (self.global.song?.artistName)!
    }
    
    //MARK: Table View Functions
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listeners.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "roomViewCell", for: indexPath) as! RoomViewCell
        if let rowData:User = self.listeners[(indexPath as IndexPath).row] {
            cell.listenerLabel.text = rowData.name
            cell.listenerPic.layer.cornerRadius = cell.listenerPic.frame.size.width / 2
            cell.listenerPic.clipsToBounds = true
            cell.listenerPic.image = rowData.profilePicture
            
            if (rowData.uid == self.global.user?.uid) {
                cell.makeLeaderLabel.isHidden = true
                
            } else if (self.global.isLeader) {
                cell.makeLeaderLabel.isHidden = false
                // Make Leader Button
                cell.tapAction = { (cell) in
                    print("just tapped the button for ", (indexPath as IndexPath).row)
                    self.makeLeader(rowData)
                    self.tableView.reloadData()
                }
            } else {
                 cell.makeLeaderLabel.isHidden = true
            }
        }
        
        return cell
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser: User = self.listeners[(indexPath as IndexPath).row]
        
        print("selectedUser", selectedUser.name)
        self.performSegue(withIdentifier: "showProfile", sender: selectedUser)
        
    }
    
    private func makeLeader(_ user: User){
        self.global.isLeader = false
        currentRoomRef?.child("leader").setValue(user.uid)
    }
    
    func songInMusicPlayerChanged() {
        print("SONG CHANGED")
        
        if (self.global.queue.count > 1 ) {
            if (self.global.didSkip) {
                // User skipped to next song
                self.global.didSkip = false
            } else {
                // Song ended, next one is starting.
                let prevSong = self.global.queue.remove(at: 0)
                self.global.idQueue.remove(at: 0)
                self.global.room?.previousPlayed.append(prevSong.trackId!)
                
                let newSong = self.global.queue[0]
                self.global.song = newSong
                self.global.room?.songID = newSong.trackId!
            }
        }
        updateRoom()
        updatePopup()
        // FUTURE: if no more songs in queue, destroy the room.
    }
    
    private func updateRoom() {
        let roomItem = [
            "name": (self.global.room?.name)!,
            "leader": (self.global.room?.leader)!,
            "songID": (self.global.room?.songID)!,
            "songQueue": (self.global.idQueue),
            "previouslyPlayed": (self.global.room?.previousPlayed)!,
            ] as [String:Any]
        self.currentRoomRef?.setValue(roomItem)
    }
    


    //MARK: Firebase Functions
    private func observeListeners() {
        // Observer to update listeners for this room
        joinRefHandle = joinRef.observe(.value, with: { (snapshot) -> Void in
            var updateListeners:[User] = []
            
            for item in snapshot.children {
                let snapshot = item as! FIRDataSnapshot
                let uid = snapshot.key
                let rid = snapshot.value as! String
                if rid == self.global.room?.rid {
                    print("Appending to listeners")
                    print ("uid: " + uid + " rid: " + rid)
                    updateListeners.append(User(uid: uid, name: ""))
                }
            }
            self.listeners = updateListeners
            self.fillOutListeners()
        })
    }
    
    private func observeRooms() {
        // Listening for changes to my room
        currentRoomRefHandle = currentRoomRef?.observe(.value, with: { (snapshot) -> Void in
            
            let roomData = snapshot.value as! Dictionary<String, AnyObject>
            let rid = snapshot.key
            if rid == self.global.room?.rid {
                self.global.room?.leader = roomData["leader"] as! String
                if let _ = roomData["songID"] {
                    if (roomData["songID"] as! String) != self.global.room?.songID {
                        print("Setting new song")
                        self.global.room?.songID = roomData["songID"] as! String
                        let roomQueue = roomData["songQueue"] as! [String]
                        self.global.systemMusicPlayer.setQueueWithStoreIDs(roomQueue)
                        self.global.systemMusicPlayer.play()
                        self.global.song = Song(trackId: (self.global.room?.songID)!){
                            print("completion handler?")
                            self.showPop()
                        }
                    }
                }
                if self.global.isLeader != (self.global.room?.leader == self.global.user?.uid) {
                    self.global.isLeader = (self.global.room?.leader == self.global.user?.uid)
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    private func fillOutListeners() {
        userRefHandle = userRef.observe(.childAdded, with: { (snapshot) -> Void in
            
            let uid = snapshot.key
            let value = snapshot.value
            
            // Need to hanbdle errors for optionals -> if let ...
            let userData = value as! [String:Any]
            
            for curUser in self.listeners {
                if curUser.uid == uid {
                    curUser.name = (userData["name"] as? String)!
                    print("Listner name: \(curUser.name)")
                    curUser.profilePicture = self.returnProfilePic(uid)
                }
            }
            
            self.global.room?.isEmpty = !(self.listeners.count > 1)
            self.tableView.reloadData()
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
