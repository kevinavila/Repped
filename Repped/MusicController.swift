//
//  RoomController.swift
//  Repped
//
//  Created by Kevin Avila on 2/25/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import MediaPlayer
import StoreKit

class MusicController: UITableViewController {
    
    @IBOutlet weak var musicTableView: UITableView!
    @IBOutlet weak var searchBarLabel: UISearchBar!
    
    let systemMusicPlayer = MPMusicPlayerController.systemMusicPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.musicTableView.delegate = self
        self.musicTableView.dataSource = self

    }
    
    
    @IBAction func playNav(_ sender: Any) {
        systemMusicPlayer.setQueueWithStoreIDs(["1207859520"])
        systemMusicPlayer.play()
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
    
}
