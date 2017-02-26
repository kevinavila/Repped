//
//  ViewController.swift
//  RadioStation
//
//  Created by Keith Martin on 6/16/16.
//  Copyright © 2016 Keith Martin. All rights reserved.
//

/* 
 * This class uses the iTunes search API to pull up songs the user searches for
 * User then touches cell to add to playback queue
 * The "Go DJ playlist button" segues the user to their radio station
 */

import UIKit
import MediaPlayer
import PubNub
import Alamofire
import StoreKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


protocol AddSongDelegate: class {
    func addSongToQueue()
}

struct SongData {
    var artWork: UIImage?
    var trackName: String?
    var artistName: String?
    var trackId: String?
}

class CreateQueueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, PNObjectEventListener {
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var leftBarButtonItem : UIBarButtonItem!
    var tableData = [] as? [NSDictionary]
    var queue: [SongData] = []
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    //Create station name and segue to radio station if playback queue isn't empty
    @IBAction func takeInputAndSegue(_ sender: AnyObject) {
        
        let alert = UIAlertController(title: "Name your radio station!", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            if !self.queue.isEmpty {
                let radioStationName = alert.textFields![0] as UITextField
                if !radioStationName.text!.isEmpty && radioStationName.text?.characters.count <= 60 {
                    let stationName = radioStationName.text!
                    //Adds a timestamp to the station name to make it a unique channel name
                    let channelName = self.createValidPNChannel(stationName)
                    //Publish station to a channel holding all stations created
                    self.appDelegate.client.publish(["stationName" : stationName, "channelName" : channelName], toChannel: "All_Stations", withCompletion: { (status) in
                        if status.isError {
                            self.showAlert("Error", error: "Network error")
                        }
                        self.appDelegate.client.subscribe(toChannels: [channelName], withPresence: true)
                        DispatchQueue.main.async(execute: {
                            //Segue to the radio station
                            let musicPlayerVC = self.storyboard?.instantiateViewController(withIdentifier: "MusicPlayerViewController") as! MusicPlayerViewController
                            musicPlayerVC.queue = self.queue
                            musicPlayerVC.channelName = channelName
                            self.navigationController?.pushViewController(musicPlayerVC, animated: true)
                        })
                    })
                } else {
                    DispatchQueue.main.async(execute: {
                        self.showAlert("Try again", error: "Radio station name can't be empty or more than 60 characters")
                    })
                }
            } else {
                DispatchQueue.main.async(execute: {
                    self.showAlert("Try again", error: "Playlist cannot be empty")
                })
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.placeholder = "Start typing to add tracks to playlist"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        queue = []
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        leftBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(dismissSearchKeyboard))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //Search iTunes with user input
        if searchBar.text != nil {
            let search = searchBar.text!.replacingOccurrences(of: " ", with: "+")
            searchItunes(search)
            searchBar.resignFirstResponder()
        }
    }
    
    func dismissSearchKeyboard() {
        self.view.endEditing(true)
    }
    
    func keyboardWillAppear(_ notification: Notification){
        self.navigationItem.leftBarButtonItem = self.leftBarButtonItem
    }
    
    func keyboardWillDisappear(_ notification: Notification){
        self.navigationItem.leftBarButtonItem = nil
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
                            self.tableView!.reloadData()
                        }
                    }
                case .failure(_):
                    self.showAlert("Error", error: response.result.error as! String)
                }
        }
    }
    
    
    //Only displaying 10 of the search items
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableData?.count < 10 {
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
            queue.append(SongData(artWork: UIImage(data: imgData), trackName: rowData["trackName"] as? String, artistName: rowData["artistName"] as? String, trackId: String (describing: rowData["trackId"]!)))
            
            //Show alert telling the user the song was added to the playback queue
            let addedTrackAlert = UIAlertController(title: nil, message: "Added track!", preferredStyle: .alert)
            self.present(addedTrackAlert, animated: true, completion: nil)
            let delay = 0.5 * Double(NSEC_PER_SEC)
            let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                addedTrackAlert.dismiss(animated: true, completion: nil)
            })
            tableView.deselectRow(at: indexPath!, animated: true)
        }
    }
    
    //Create unique PubNub channel by concatenating the current timestamp to the name of the radio station
    func createValidPNChannel(_ channelName: String) -> String {
        let regex = try? NSRegularExpression(pattern: "[\\W]", options: .caseInsensitive)
        var validChannelName = regex!.stringByReplacingMatches(in: channelName, options: [], range: NSRange(0..<channelName.characters.count), withTemplate: "")
        validChannelName += "\(Date().timeIntervalSince1970)"
        validChannelName = validChannelName.replacingOccurrences(of: ".", with: "")
        return validChannelName
    }
    
    //Dialogue showing error
    func showAlert(_ title: String, error: String) {
        let alertController = UIAlertController(title: title, message: error, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion:nil)
    }
}

