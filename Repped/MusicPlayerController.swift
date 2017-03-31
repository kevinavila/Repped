//
//  MusicPlayerController.swift
//  Repped
//
//  Created by Wes Draper on 3/10/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import LNPopupController
import MediaPlayer

class MusicPlayerController: UIViewController {
    
    
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumArtImageView: UIImageView!
    
    @IBOutlet weak var songProgress: UIProgressView!
    @IBOutlet weak var progressView: UISlider!
    
    let global:Global = Global.sharedGlobal
    
    let accessibilityDateComponentsFormatter = DateComponentsFormatter()
    
    var timer : Timer?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        songNameLabel.text = (self.global.song?.trackName)!
        popupItem.title = (self.global.song?.trackName)!
        
        albumArtImageView.image = (self.global.song?.artWork)!
        popupItem.image = (self.global.song?.artWork)!
        
        albumNameLabel.text = (self.global.song?.artistName)!
        popupItem.subtitle = (self.global.song?.artistName)!
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerFired(_:)), userInfo: nil, repeats: true)
        self.timer?.tolerance = 0.1
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //Need to check for if user is the leader -> show different Controls TODO
        let pause = UIBarButtonItem(image: UIImage(named: "pause"), style: .plain, target: nil, action: nil)
        pause.accessibilityLabel = NSLocalizedString("Pause", comment: "")
        let next = UIBarButtonItem(image: UIImage(named: "nextFwd"), style: .plain, target: nil, action: nil)
        next.accessibilityLabel = NSLocalizedString("Next Track", comment: "")
        
        let rep = UIBarButtonItem(image: UIImage(named: "lovec"), style: .plain, target: nil, action: nil)
        rep.accessibilityLabel = NSLocalizedString("Give Rep", comment: "")
        
        let mute = UIBarButtonItem(image: UIImage(named: "volDown"), style: .plain, target: nil, action: nil)
        mute.accessibilityLabel = NSLocalizedString("Give Rep", comment: "")
        
        
        if global.isLeader{
            self.popupItem.leftBarButtonItems = [ pause ]
            self.popupItem.rightBarButtonItems = [ next ]
        } else {
            self.popupItem.leftBarButtonItems = [ rep ]
            self.popupItem.rightBarButtonItems = [ mute ]
        }
        
        accessibilityDateComponentsFormatter.unitsStyle = .spellOut
        
    }
    
    private func clickNext()
    {
        
    }
    
    
    //Function to pull track info and update labels
    func timerFired(_:AnyObject) {
        
        //Ensure the track exists before pulling the info
        if let currentTrack = MPMusicPlayerController.systemMusicPlayer().nowPlayingItem {
            
            let trackDuration = currentTrack.playbackDuration
            

            //Find elapsed time by pulling currentPlaybackTime
            let trackElapsed = self.global.systemMusicPlayer.currentPlaybackTime
            
            // avoid crash
            if trackElapsed.isNaN
            {
                return
            }
            
           //changes slider to as song progresses
            songProgress.setProgress(Float(trackElapsed/trackDuration), animated: true)
        }
        
    }
        
   }
