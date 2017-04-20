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
        tableView.tableHeaderView = searchController?.searchBar
        searchController?.delegate = self
        
        self.tableView.backgroundView = UIView()
        
        self.currentRoomRef = FIRDatabase.database().reference().child("rooms/"+(self.global.room?.rid)!)
    }
    
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
            
            // UI styling for cell
            cell.backgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1.0)
            cell.textLabel?.textColor = UIColor(red:0.29, green:0.67, blue:0.75, alpha:1.0)
            cell.detailTextLabel?.textColor = UIColor(red:0.29, green:0.67, blue:0.75, alpha:1.0)
            
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
            cell.img.image = self.global.previousSongs[indexPath.row].artWorkSmall
            
            if self.reppedSong(trackID: self.global.previousSongs[indexPath.row].trackId!) {
                print("seting img loved")
                cell.repButtonOutlet.setImage(#imageLiteral(resourceName: "loved"), for: .normal)
            } else {
                print("seting img lovec")
                cell.repButtonOutlet.setImage(#imageLiteral(resourceName: "lovec"), for: .normal)
            }
            
            cell.tapAction = { (cell) in
                print("Just tapped the button for ", (indexPath as IndexPath).row)
                if self.reppedSong(trackID: self.global.previousSongs[indexPath.row].trackId!) {
                    self.toast("Already repped the leader for this song.")
                    print("Repped already boy.")
                } else {
                    self.clickedRep(cell: (cell as! RecentlyPlayedCell))
                    (cell as! RecentlyPlayedCell).repButtonOutlet.setImage(#imageLiteral(resourceName: "loved"), for: .normal) 
                }
                
            }
            return cell
            
        } else {
            // User's song queue
            if (self.global.queue.count > 0) {
                let cell  = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: nil)
                
                // UI styling for cell
                cell.backgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1.0)
                cell.textLabel?.textColor = UIColor(red:0.29, green:0.67, blue:0.75, alpha:1.0)
                cell.detailTextLabel?.textColor = UIColor(red:0.29, green:0.67, blue:0.75, alpha:1.0)
                
                let song = self.global.queue[indexPath.row]
                cell.imageView?.image = song.artWorkSmall
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
            let urlStringLarge = rowData["artworkUrl100"] as? String
            let imgURLLarge = URL(string: urlStringLarge!)
            
            do {
                let imgDataSmall = try Data(contentsOf: imgURL!)
                let imgDataLarge = try Data(contentsOf: imgURLLarge!)
                self.global.idQueue.append(String (describing: rowData["trackId"]!))
                //print("id Queue ",self.global.idQueue)
                //self.global.systemMusicPlayer.setQueueWithStoreIDs(self.global.idQueue)
                self.global.queue.append(Song(artWorkSmall: UIImage(data: imgDataSmall),artWorkLarge:  UIImage(data: imgDataLarge), trackName: rowData["trackName"] as? String, artistName: rowData["artistName"] as? String, trackId: String (describing: rowData["trackId"]!)))
                toast("Added track!")
                tableView.deselectRow(at: indexPath, animated: true)
                
                if (self.global.isLeader) {
                    if (!self.global.isSongPlaying()) {
                        // Adding first song. Start playing.
                        let song = self.global.queue[0]
                        self.global.song = song
                        self.global.room?.songID = song.trackId!
                        self.global.systemMusicPlayer.setQueueWithStoreIDs(self.global.idQueue)
                        self.global.systemMusicPlayer.play()
                        //self.global.idQueue.remove(at: 0)
                        //self.global.room?.previousPlayed.append(song.trackId!)
                        updateRoom()
                        showPop()
                    } else {
                        self.global.systemMusicPlayer.setQueueWithStoreIDs(self.global.idQueue)
                        updateRoom()
                    }
                }
            } catch let error {
                print("error occured \(error)")
            }
        } else if (indexPath.section == 0) {
            // Recently played
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else {
            // User's song queue
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.lightGray
        
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
                    print("Increased rep")
                    self.global.repHistory[(self.global.song?.trackId)!] = self.global.room?.leader
                    // Change button icon
                    DispatchQueue.main.async(){
                        self.toast("Repped!")
                        print("Reload table")
                        self.tableView.reloadData()
                    }
                }
                return FIRTransactionResult.success(withValue: currentData)
            }) { (error, committed, snapshot) in
                if let error = error {
                    print("There was an error increasing the rep.")
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
