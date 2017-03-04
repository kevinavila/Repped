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

class MusicController: UIViewController {
    
    @IBOutlet weak var searchBarLabel: UISearchBar!
    @IBOutlet weak var musicTable: UITableView!
    let systemMusicPlayer = MPMusicPlayerController.systemMusicPlayer()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    

    @IBAction func playButtonClicked(_ sender: Any) {
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
