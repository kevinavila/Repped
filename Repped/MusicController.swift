//
//  MusicController.swift
//  Repped
//
//  Created by Wes Draper on 3/4/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import MediaPlayer
import StoreKit
import Alamofire
import Firebase
import LNPopupController

class MusicController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate{
    
    private var currentRoomRefHandle:FIRDatabaseHandle?
    private var currentRoomRef:FIRDatabaseReference?
    @IBOutlet weak var searchBarLabel: UISearchBar!
    @IBOutlet weak var musicTable: UITableView!
    var global:Global = Global.sharedGlobal
    
    var currentRoom: Room? = nil
    var tableData = [] as? [NSDictionary]
    var previousSongs = [] as [Song]
    
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")

    @IBOutlet weak var recentlyPlayedLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.title = "Title 3"
        
        self.global.isLeader ? setLeader() : setListener()
        
        searchBarLabel.delegate = self
        musicTable.delegate = self
        musicTable.dataSource = self
        
         self.currentRoomRef = FIRDatabase.database().reference().child("rooms/"+(self.global.room?.rid)!)
        observeRooms()
        
        searchBarLabel.placeholder = "Start typing to add tracks to playlist"
    }
    
    private func setLeader(){
        self.searchBarLabel.isHidden = false
        self.recentlyPlayedLabel.isHidden = true
    }
    
    private func setListener(){
        self.searchBarLabel.isHidden = true
        self.recentlyPlayedLabel.isHidden = false
    }
    
    

    @IBAction func playButtonClicked(_ sender: Any) {
        if self.global.queue.isEmpty {
            toast("First add a song to the queue")
            
        } else {
            let song = self.global.queue.remove(at: 0)
            self.global.song = song
            self.global.room?.songID = song.trackId!
            self.global.systemMusicPlayer.setQueueWithStoreIDs([song.trackId!])
            self.global.systemMusicPlayer.play()
            //Need to get it to workl to use the musicplayer controller queue so songs will play in the backgroung
            //if self.global.systemMusicPlayer.nowPlayingItem == nil {
            //    print("trying to play for tyhe first time")
            //    self.global.systemMusicPlayer.play()
            //} else {
            //    print("skipping to next song")
            //     self.global.systemMusicPlayer.skipToNextItem()
            //}
            self.global.idQueue.remove(at: 0)
            self.global.room?.previousPlayed.append(song.trackId!)
            songChange()
            showPop()
        }
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
    
    private func songChange(){
        let roomItem = [
            "name": (self.global.room?.name)!,
            "leader": (self.global.room?.leader)!,
            "songID": (self.global.room?.songID)!,
            "songQueue": (self.global.idQueue),
            "previouslyPlayed": (self.global.room?.previousPlayed)!,
            ] as [String:Any]
        self.roomRef.child((self.global.room?.rid)!).setValue(roomItem)
    }
    
    // Fetch the user's storefront ID
    func appleMusicFetchStorefrontRegion() {
        let serviceController = SKCloudServiceController()
        
        serviceController.requestStorefrontIdentifier(completionHandler: { (storefrontId:String?, err:Error?) in
            guard err == nil else {
                print("An error occured. Handle it here.")
                return
                
            }
            guard let storefrontId = storefrontId, storefrontId.characters.count >= 6 else {
                
                print("Handle the error - the callback didn't contain a valid storefrontID.")
                return
            }
            let start = storefrontId.startIndex
            let end = storefrontId.index(storefrontId.startIndex, offsetBy: 5)
            let indexRange = start..<end
            let trimmedId = storefrontId[indexRange]
            
            print("Success! The user's storefront ID is: \(trimmedId)")
        })
    }
    
    //Search iTunes and display results in table view
    func searchItunes(_ searchTerm: String) {
        let urlstring = "https://itunes.apple.com/search?term=\(searchTerm)&entity=song"
        Alamofire.request(urlstring, method: .get)
            .validate()
            .responseJSON { response in
                switch(response.result) {
                case .success(_):
                    if let responseData = response.result.value as? NSDictionary {
                        if let songResults = responseData.value(forKey: "results") as? [NSDictionary] {
                            self.tableData = songResults
                            self.musicTable!.reloadData()
                        }
                    }
                case .failure(_):
                    self.showAlert("Error", error: response.result.error as! String)
                }
        }
    }
    
    //Only displaying 10 of the search items
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.global.isLeader {
            if (tableData?.count)! < 10 {
                return tableData!.count
            }
            return 10
        } else {
            return  self.previousSongs.count
        }

    }
    
    //Display iTunes search results
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.global.isLeader {
            let cell  = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: nil)
            if let rowData: NSDictionary = self.tableData?[indexPath.row],
                let urlString = rowData["artworkUrl60"] as? String,
                let imgURL = URL(string: urlString),
                let imgData = try? Data(contentsOf: imgURL) {
                cell.imageView?.image = UIImage(data: imgData)
                cell.textLabel?.text = rowData["trackName"] as? String
                cell.detailTextLabel?.text = rowData["artistName"] as? String
            }
            return cell
        } else {
             let cell = tableView.dequeueReusableCell(withIdentifier: "musicViewCell", for: indexPath) as! MusicViewCell
            cell.mainText.text = self.previousSongs[indexPath.row].trackName
            cell.subTitle.text = self.previousSongs[indexPath.row].artistName
            
            if self.reppedSong(trackID: self.previousSongs[indexPath.row].trackId!){
                print("seting img loved")
                cell.repButtonOutlet.imageView?.image = #imageLiteral(resourceName: "loved")
            } else {
                print("seting img lovec")
                cell.repButtonOutlet.imageView?.image = #imageLiteral(resourceName: "lovec")
            }
            
            cell.tapAction = { (cell) in
                print("just tapped the button for ", (indexPath as IndexPath).row)
                if self.reppedSong(trackID: self.previousSongs[indexPath.row].trackId!){
                    print("repped already boy")
                }else {
                    self.clickedRep(cell: (cell as! MusicViewCell))
                    (cell as! MusicViewCell).repButtonOutlet.imageView?.image = #imageLiteral(resourceName: "loved")
                }
               
            }
            return cell
        }
    }
    
    private func clickedRep(cell: MusicViewCell){
            let leaderRepRef = userRef.child((self.global.room?.leader)!).child("rep")
            
            leaderRepRef.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if let curRep = currentData.value as? Int{
                    currentData.value = curRep + 1
                    print("increased rep")
                    self.global.repHistory[(self.global.song?.trackId)!] = self.global.room?.leader
                    //change button icon
                    DispatchQueue.main.async(){
                        print("reload tbale")
                        self.musicTable.reloadData()
                    }
                }
                return FIRTransactionResult.success(withValue: currentData)
            }) { (error, committed, snapshot) in
                if let error = error {
                    print("there was an error adding rep")
                    print(error.localizedDescription)
                }
            }
    }
    
    private func reppedSong(trackID: String) -> Bool {
        return self.global.repHistory[trackID] == self.global.room?.leader
    }

    //Add song to playback queue if user selects a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let indexPath = tableView.indexPathForSelectedRow
         if self.global.isLeader {
        if let rowData: NSDictionary = self.tableData?[indexPath!.row], let urlString = rowData["artworkUrl60"] as? String,
            let imgURL = URL(string: urlString),
            let imgData = try? Data(contentsOf: imgURL)  {
            self.global.idQueue.append(String (describing: rowData["trackId"]!))
            //print("id Queue ",self.global.idQueue)
            //self.global.systemMusicPlayer.setQueueWithStoreIDs(self.global.idQueue)
            self.global.queue.append(Song(artWork: UIImage(data: imgData), trackName: rowData["trackName"] as? String, artistName: rowData["artistName"] as? String, trackId: String (describing: rowData["trackId"]!)))
            toast("Added track!")
            
                       tableView.deselectRow(at: indexPath!, animated: true)
            }
        }
    }



    func toast(_ toast: String){
        //Show alert telling the user the song was added to the playback queue
        let addedTrackAlert = UIAlertController(title: nil, message: toast, preferredStyle: .alert)
        self.present(addedTrackAlert, animated: true, completion: nil)
        let delay = 0.5 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            addedTrackAlert.dismiss(animated: true, completion: nil)
        })

    }
    
    //Dialogue showing error
    func showAlert(_ title: String, error: String) {
        let alertController = UIAlertController(title: title, message: error, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion:nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("wes_ searchBarSearchButtonClicked")
        //Search iTunes with user input
        if searchBar.text != nil {
            print("wes_ searchbar text ", searchBar.text ?? "nothing")
            let search = searchBar.text!.replacingOccurrences(of: " ", with: "+")
            searchItunes(search)
            searchBar.resignFirstResponder()
        }
    }
    
    
    //MARK: Firebase Functions
    private func observeRooms() {
        // Listening for changes to y room for sonf
        currentRoomRefHandle = currentRoomRef?.observe(.value, with: { (snapshot) -> Void in
            
            let roomData = snapshot.value as! Dictionary<String, AnyObject>
            let rid = snapshot.key
            if rid == self.global.room?.rid {
                self.global.room?.leader =  roomData["leader"] as! String
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
                if let _ = roomData["previouslyPlayed"] {
                    let songIDs = roomData["previouslyPlayed"] as! [String]
                    for id in songIDs{
                        self.previousSongs.append(Song(trackId: id){
                            self.musicTable.reloadData()
                        })
                    }
                }
                if self.global.isLeader != (self.global.room?.leader == self.global.user?.uid){
                    self.global.isLeader = (self.global.room?.leader == self.global.user?.uid)
                    self.musicTable.reloadData()
                    self.global.isLeader ? self.setLeader() : self.setListener()
                }
            }
        })
    }

    
    
    func dismissSearchKeyboard() {
        self.view.endEditing(true)
    }
    
    func keyboardWillDisappear(_ notification: Notification){
        self.navigationItem.leftBarButtonItem = nil
    }
}
