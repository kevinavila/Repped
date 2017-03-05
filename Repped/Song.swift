//
//  Song.swift
//  Repped
//
//  Created by Wes Draper on 3/4/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//
import UIKit


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

}
