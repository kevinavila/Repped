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
    internal var artWorkLarge: UIImage?
    internal var artWorkSmall: UIImage?
    internal var trackName: String?
    internal var artistName: String?
    internal let trackId: String?
    
    
    init(artWorkSmall: UIImage?, artWorkLarge: UIImage?, trackName: String?, artistName: String?,trackId: String?) {
        self.artWorkSmall = artWorkSmall
        self.artWorkLarge = artWorkLarge
        self.trackName = trackName
        self.artistName = artistName
        self.trackId = trackId
    }
    
    init(trackId: String,completionHandler: @escaping () -> Void){
        self.trackId = trackId
        let urlstring = "https://itunes.apple.com/lookup?id=\(trackId)"
        Alamofire.request(urlstring, method: .get)
            .validate()
            .responseJSON { response in
                switch(response.result) {
                case .success(_):
                    if let responseData = response.result.value as? NSDictionary {
                        if let songResults = responseData.value(forKey: "results") as? [NSDictionary] {
                            let info =  songResults[0]
                            let urlString = info["artworkUrl60"] as? String
                            let imgURL = URL(string: urlString!)
                            self.artWorkSmall = UIImage(data: try! Data(contentsOf: imgURL!))
                            
                            let urlStringLarge = info["artworkUrl100"] as? String
                            let imgURLLarge = URL(string: urlStringLarge!)
                            self.artWorkLarge = UIImage(data: try! Data(contentsOf: imgURLLarge!))
                            
                            self.trackName = info["trackName"] as! String
                            self.artistName = info["artistName"] as! String
                            
                }
                        completionHandler()
                    }
                case .failure(_):
                    print("Error in finding song info")
                    self.artWorkSmall = #imageLiteral(resourceName: "noprofile")
                    self.trackName = "That song"
                    self.artistName = "Rick Astley"
                }
        }
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
                            let info =  songResults[0]
                            let urlString = info["artworkUrl60"] as? String
                            let imgURL = URL(string: urlString!)
                            self.artWorkSmall = UIImage(data: try! Data(contentsOf: imgURL!))
                            
                            let urlStringLarge = info["artworkUrl100"] as? String
                            let imgURLLarge = URL(string: urlStringLarge!)
                            self.artWorkLarge = UIImage(data: try! Data(contentsOf: imgURLLarge!))
                            
                            self.trackName = info["trackName"] as! String
                            self.artistName = info["artistName"] as! String
                            
                            print("song info in here", self.trackId!, self.artistName!, self.trackName!)
                        }
                    }
                case .failure(_):
                    print("Error in finding song info")
                }
        }
    }


}
