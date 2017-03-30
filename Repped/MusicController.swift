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
    
    @IBOutlet weak var searchBarLabel: UISearchBar!
    @IBOutlet weak var musicTable: UITableView!
    var global:Global = Global.sharedGlobal
    
    var currentRoom: Room? = nil
    var tableData = [] as? [NSDictionary]
    
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBarLabel.delegate = self
        musicTable.delegate = self
        musicTable.dataSource = self
        
        searchBarLabel.placeholder = "Start typing to add tracks to playlist"
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
            "songID": (self.global.room?.songID)!
            ] as [String:String]
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
        let urlstring = "https://itunes.apple.com/lookup?id=\(searchTerm)"
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
        if (tableData?.count)! < 10 {
            return tableData!.count
        }
        return 10
    }
    
    //Display iTunes search results
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: nil)
        if let rowData: NSDictionary = self.tableData?[indexPath.row],
            let urlString = rowData["artworkUrl60"] as? String,
            let imgURL = URL(string: urlString),
            let imgData = try? Data(contentsOf: imgURL) {
            cell.imageView?.image = UIImage(data: imgData)
            cell.textLabel?.text = rowData["trackName"] as? String
            cell.detailTextLabel?.text = rowData["artistName"] as? String
        }
        return cell
    }
    
    //Add song to playback queue if user selects a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let indexPath = tableView.indexPathForSelectedRow
        if let rowData: NSDictionary = self.tableData?[indexPath!.row], let urlString = rowData["artworkUrl60"] as? String,
            let imgURL = URL(string: urlString),
            let imgData = try? Data(contentsOf: imgURL)  {
            self.global.queue.append(Song(artWork: UIImage(data: imgData), trackName: rowData["trackName"] as? String, artistName: rowData["artistName"] as? String, trackId: String (describing: rowData["trackId"]!)))
            toast("Added track!")
            
                       tableView.deselectRow(at: indexPath!, animated: true)
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
    
    func dismissSearchKeyboard() {
        self.view.endEditing(true)
    }
    
    func keyboardWillDisappear(_ notification: Notification){
        self.navigationItem.leftBarButtonItem = nil
    }
}
