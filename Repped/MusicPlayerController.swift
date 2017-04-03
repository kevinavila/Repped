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
import Firebase

class MusicPlayerController: UIViewController {
    
    
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumArtImageView: UIImageView!
    
    @IBOutlet weak var songProgress: UIProgressView!
    @IBOutlet weak var progressView: UISlider!
    
    @IBOutlet weak var playPauseOutlet: UIButton!
    @IBOutlet weak var skipRepOutlet: UIButton!
    

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
        let pause = UIBarButtonItem(image: UIImage(named: "pause"), style: .plain, target: self, action: #selector(pause(sender:)))
        pause.accessibilityLabel = NSLocalizedString("Pause", comment: "")
        
        let next = UIBarButtonItem(image: UIImage(named: "nextFwd"), style: .plain, target: self, action: #selector(next(sender:)))
        next.accessibilityLabel = NSLocalizedString("Next Track", comment: "")
        
        let rep = UIBarButtonItem(image: (reppedSong() ? UIImage(named: "loved") : UIImage(named: "lovec")), style: .plain, target: self, action: #selector(rep(sender:)))
        rep.accessibilityLabel = NSLocalizedString("Give Rep", comment: "")
        
        let mute = UIBarButtonItem(image: UIImage(named: "volDown"), style: .plain, target: self, action: #selector(mute(sender:)))
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
    
    @IBAction func playPauseButton(_ sender: Any) {
         print("mute")
        print("play")
    }
    
    @IBAction func skipRepButton(_ sender: Any) {
        if self.global.isLeader {
            //button hould show skipped and function as skip
        } else {
            if self.reppedSong() {
                print("Already Repped Song")
            } else {
            let leaderRepRef = userRef.child((self.global.room?.leader)!).child("rep")

            leaderRepRef.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if let curRep = currentData.value as? Int{
                    currentData.value = curRep + 1
                    print("increased rep")
                    self.global.repHistory[(self.global.song?.trackId)!] = self.global.room?.leader
                    //change button icon
                    DispatchQueue.main.async(){
                        self.popupItem.leftBarButtonItems = [UIBarButtonItem(image:UIImage(named: "loved"), style: .plain, target: nil, action: nil)]
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
        }
         print("add rep")
        print("go next")
    }
    
    func next(sender: UIBarButtonItem)
    {
        skipRepButton(sender)
    }
    
    func pause(sender: UIBarButtonItem)
    {
       playPauseButton(sender)
    }
    
    func rep(sender: UIBarButtonItem)
    {
        skipRepButton(sender)
    }
    
    func mute(sender: UIBarButtonItem)
    {
        playPauseButton(sender)
    }
    
    private func reppedSong() -> Bool {
        return self.global.repHistory[(self.global.song?.trackId)!] == self.global.room?.leader
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
