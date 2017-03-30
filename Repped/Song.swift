//
//  Song.swift
//  Repped
//
//  Created by Wes Draper on 3/4/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//
import UIKit
import Alamofire


internal class Song {
    internal let artWork: UIImage?
    internal let trackName: String?
    internal let artistName: String?
    internal let trackId: String?
    
    
    init(artWork: UIImage?, trackName: String?, artistName: String?,trackId: String?) {
        self.artWork = artWork
        self.trackName = trackName
        self.artistName = artistName
        self.trackId = trackId
    }
    
    init(trackId: String){
        self.artWork = #imageLiteral(resourceName: "noprofile")
        self.trackName = "That song"
        self.artistName = "Rick Astley"
        self.trackId = trackId
        searchItunes(trackId)
    }
    
    func searchItunes(_ trackID: String){
        let urlstring = "https://itunes.apple.com/lookup?id=\(trackID)"
        Alamofire.request(urlstring, method: .get)
            .validate()
            .responseJSON { response in
                switch(response.result) {
                case .success(_):
                    if let responseData = response.result.value as? NSDictionary {
                        if let songResults = responseData.value(forKey: "results") as? [NSDictionary] {
                            print("Song Results", songResults)
                        }
                    }
                case .failure(_):
                    print("Error in finding song info")
                }
        }
    }


}
