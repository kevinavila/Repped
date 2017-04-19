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

class MusicController: UITableViewController, UISearchControllerDelegate, UISearchResultsUpdating {
    
    private var currentRoomRefHandle:FIRDatabaseHandle?
    private var currentRoomRef:FIRDatabaseReference?
    var global:Global = Global.sharedGlobal
    var searchController:UISearchController?
    
    var currentRoom: Room? = nil
    var songResults = [] as [NSDictionary]
    
    
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //navigationController?.navigationBar.topItem?.title = "Title 3"
        
        searchController = UISearchController(searchResultsController: nil)
        //searchController?.searchBar.delegate = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.searchResultsUpdater = self
        //definesPresentationContext = true
        tableView.tableHeaderView = searchController?.searchBar
        searchController?.delegate = self
        
        self.currentRoomRef = FIRDatabase.database().reference().child("rooms/"+(self.global.room?.rid)!)
        observeRooms()
    }

//    @IBAction func playButtonClicked(_ sender: Any) {
//        if self.global.queue.isEmpty {
//            toast("First add a song to the queue")
//            
//        } else {
//            let song = self.global.queue.remove(at: 0)
//            self.global.song = song
//            self.global.room?.songID = song.trackId!
//            self.global.systemMusicPlayer.setQueueWithStoreIDs([song.trackId!])
//            self.global.systemMusicPlayer.play()
//            //Need to get it to workl to use the musicplayer controller queue so songs will play in the backgroung
//            //if self.global.systemMusicPlayer.nowPlayingItem == nil {
//            //    print("trying to play for tyhe first time")
//            //    self.global.systemMusicPlayer.play()
//            //} else {
//            //    print("skipping to next song")
//            //     self.global.systemMusicPlayer.skipToNextItem()
//            //}
//            self.global.idQueue.remove(at: 0)
//            self.global.room?.previousPlayed.append(song.trackId!)
//            songChange()
//            showPop()
//        }
//    }
    
    //MARK: Tableview functions
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ((searchController?.isActive)! && searchController?.searchBar.text != "") {
            // Limiting to 10 results for now
            if (songResults.count < 10) {
                return songResults.count
            }
            return 10
        } else if (section == 0) {
            // Recently played: limit this to 5
            if (self.global.previousSongs.count < 5) {
                return self.global.previousSongs.count
            }
            return 5
        } else {
            // User's song queue
            return self.global.queue.count
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let currentlySearching = (searchController?.isActive)! && (searchController?.searchBar.text != "")
        if (!currentlySearching) {
            if section == 0 {
                return "Recently Played"
            } else {
                return "My Jams"
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if ((searchController?.isActive)! && searchController?.searchBar.text != "") {
            // Currently searching
            let cell  = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: nil)
            if let rowData: NSDictionary = self.songResults[indexPath.row],
                let urlString = rowData["artworkUrl60"] as? String,
                let imgURL = URL(string: urlString),
                let imgData = try? Data(contentsOf: imgURL) {
                cell.imageView?.image = UIImage(data: imgData)
                cell.textLabel?.text = rowData["trackName"] as? String
                cell.detailTextLabel?.text = rowData["artistName"] as? String
            }
            return cell
        } else if (indexPath.section == 0) {
            // Recently played
            let cell = tableView.dequeueReusableCell(withIdentifier: "recentlyPlayedCell", for: indexPath) as! RecentlyPlayedCell
            cell.mainText.text = self.global.previousSongs[indexPath.row].trackName
            cell.subTitle.text = self.global.previousSongs[indexPath.row].artistName
            cell.img.image = self.global.previousSongs[indexPath.row].artWork
            
            if self.reppedSong(trackID: self.global.previousSongs[indexPath.row].trackId!) {
                print("seting img loved")
                cell.repButtonOutlet.imageView?.image = #imageLiteral(resourceName: "loved")
            } else {
                print("seting img lovec")
                cell.repButtonOutlet.imageView?.image = #imageLiteral(resourceName: "lovec")
            }
            
            cell.tapAction = { (cell) in
                print("Just tapped the button for ", (indexPath as IndexPath).row)
                if self.reppedSong(trackID: self.global.previousSongs[indexPath.row].trackId!) {
                    print("Repped already boy.")
                } else {
                    self.clickedRep(cell: (cell as! RecentlyPlayedCell))
                    (cell as! RecentlyPlayedCell).repButtonOutlet.imageView?.image = #imageLiteral(resourceName: "loved")
                }
                
            }
            return cell
            
        } else {
            // User's song queue
            if (self.global.queue.count > 0) {
                print ("DISPLAYING USER's QUEUE")
                let cell  = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: nil)
                let song = self.global.queue[indexPath.row]
                cell.imageView?.image = song.artWork
                cell.textLabel?.text = song.trackName
                cell.detailTextLabel?.text = song.artistName
                return cell
            }
            
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if ((searchController?.isActive)! && searchController?.searchBar.text != "") {
            let rowData = self.songResults[indexPath.row] as NSDictionary
            let urlString = rowData["artworkUrl60"] as? String
            let imgURL = URL(string: urlString!)
            
            do {
                let imgData = try Data(contentsOf: imgURL!)
                self.global.idQueue.append(String (describing: rowData["trackId"]!))
                //print("id Queue ",self.global.idQueue)
                //self.global.systemMusicPlayer.setQueueWithStoreIDs(self.global.idQueue)
                self.global.queue.append(Song(artWork: UIImage(data: imgData), trackName: rowData["trackName"] as? String, artistName: rowData["artistName"] as? String, trackId: String (describing: rowData["trackId"]!)))
                toast("Added track!")
                tableView.deselectRow(at: indexPath, animated: true)
                
                if (self.global.isLeader) {
                    if (self.global.queue.count < 2) {
                        // Adding first song. Start playing.
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
                        updateRoom()
                        showPop()
                    } else {
                        updateRoom()
                    }
                }
            } catch let error {
                print("error occured \(error)")
            }
        } else if (indexPath.section == 0) {
            // Recently played
            
        } else {
            // User's song queue
        }
        
        //        let indexPath = tableView.indexPathForSelectedRow
        //         if self.global.isLeader {
        //        if let rowData: NSDictionary = self.tableData?[indexPath!.row], let urlString = rowData["artworkUrl60"] as? String,
        //            let imgURL = URL(string: urlString),
        //            let imgData = try? Data(contentsOf: imgURL)  {
        //            self.global.idQueue.append(String (describing: rowData["trackId"]!))
        //            //print("id Queue ",self.global.idQueue)
        //            //self.global.systemMusicPlayer.setQueueWithStoreIDs(self.global.idQueue)
        //            self.global.queue.append(Song(artWork: UIImage(data: imgData), trackName: rowData["trackName"] as? String, artistName: rowData["artistName"] as? String, trackId: String (describing: rowData["trackId"]!)))
        //            toast("Added track!")
        //
        //                       tableView.deselectRow(at: indexPath!, animated: true)
        //            }
        //        }
    }
    
    private func updateRoom() {
        let roomItem = [
            "name": (self.global.room?.name)!,
            "leader": (self.global.room?.leader)!,
            "songID": (self.global.room?.songID)!,
            "songQueue": (self.global.idQueue),
            "previouslyPlayed": (self.global.room?.previousPlayed)!,
            ] as [String:Any]
        self.roomRef.child((self.global.room?.rid)!).setValue(roomItem)
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

    //MARK: Rep functions
    private func clickedRep(cell: RecentlyPlayedCell) {
            let leaderRepRef = userRef.child((self.global.room?.leader)!).child("rep")
            
            leaderRepRef.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if let curRep = currentData.value as? Int{
                    currentData.value = curRep + 1
                    print("increased rep")
                    self.global.repHistory[(self.global.song?.trackId)!] = self.global.room?.leader
                    //change button icon
                    DispatchQueue.main.async(){
                        print("reload table")
                        self.tableView.reloadData()
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
    
    
    //MARK: Search bar and display controller functions
    func updateSearchResults(for searchController: UISearchController) {
        // In the future, maybe display results as the user types via a background thread.
        if (searchController.searchBar.text != nil) {
            let searchString = searchController.searchBar.text!.replacingOccurrences(of: " ", with: "+")
            searchItunes(searchString)
        }
    }
    
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        if (searchBar.text != nil) {
//            let searchString = searchBar.text!.replacingOccurrences(of: " ", with: "+")
//            searchItunes(searchString)
//        }
//    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        self.navigationController?.navigationBar.isTranslucent = false
    }
    
    // Search iTunes and display results in table view
    func searchItunes(_ searchTerm: String) {
        let urlstring = "https://itunes.apple.com/search?term=\(searchTerm)&entity=song"
        Alamofire.request(urlstring, method: .get)
            .validate()
            .responseJSON { response in
                switch(response.result) {
                case .success(_):
                    if let responseData = response.result.value as? NSDictionary {
                        if let songResults = responseData.value(forKey: "results") as? [NSDictionary] {
                            self.songResults = songResults
                            self.tableView.reloadData()
                        }
                    }
                case .failure(_):
                    self.showAlert("Error", error: response.result.error as! String)
                }
        }
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
    
    
    //MARK: Firebase Functions
    private func observeRooms() {
        // Listening for changes in current room
        currentRoomRefHandle = currentRoomRef?.observe(.value, with: { (snapshot) -> Void in
            
            let roomData = snapshot.value as! Dictionary<String, AnyObject>
            let rid = snapshot.key
            if rid == self.global.room?.rid {
                self.global.room?.leader = roomData["leader"] as! String
                if let _ = roomData["songID"] {
                    if (roomData["songID"] as! String) != self.global.room?.songID {
                        print("Setting new song")
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
                    for id in songIDs {
                        self.global.previousSongs.append(Song(trackId: id){
                            self.tableView.reloadData()
                        })
                    }
                }
                if self.global.isLeader != (self.global.room?.leader == self.global.user?.uid) {
                    self.global.isLeader = (self.global.room?.leader == self.global.user?.uid)
                    self.tableView.reloadData()
                }
            }
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        searchController?.isActive = false
        searchController?.dismiss(animated: false, completion: nil)
    }
    
    func dismissSearchKeyboard() {
        self.view.endEditing(true)
    }
    
    func keyboardWillDisappear(_ notification: Notification){
        self.navigationItem.leftBarButtonItem = nil
    }
}
