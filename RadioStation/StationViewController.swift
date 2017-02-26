//
//  StationViewController.swift
//  RadioStation
//
//  Created by Keith Martin on 6/22/16.
//  Copyright © 2016 Keith Martin. All rights reserved.
//

/*
 * This class receives messages from the radio station the user is subscribed to
 * A user can upvote and downvote the song that is playing
 */

import UIKit
import PubNub
import MediaPlayer

class StationViewController: UIViewController, PNObjectEventListener {
    
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var channelName: String!
    var stationName: String!
    
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var thumbsUpButton: UIButton!
    @IBOutlet weak var thumbsDownButton: UIButton!
    let controller = MPMusicPlayerController.applicationMusicPlayer()
    
    
    //Publish a upvote to the subscribed channel
    @IBAction func thumbsUp(_ sender: AnyObject) {
        appDelegate.client.publish(["action" : "thumbsUp"], toChannel: channelName) { (status) in
            if !status.isError {
                self.thumbsDownButton.backgroundColor = UIColor.clear
                self.thumbsUpButton.backgroundColor = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1.0)
            } else {
                self.showAlert("Error", error: "Network error")
            }
        }
    }
    
    //Publish a downvote to the subscribed channel
    @IBAction func thumbsDown(_ sender: AnyObject) {
        appDelegate.client.publish(["action" : "thumbsDown"], toChannel: channelName) { (status) in
            if !status.isError {
                self.thumbsUpButton.backgroundColor = UIColor.clear
                self.thumbsDownButton.backgroundColor = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1.0)
            } else {
                self.showAlert("Error", error: "Network error")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        appDelegate.client.add(self)
        appDelegate.client.subscribe(toChannels: [channelName], withPresence: true)
        self.title = "Radio station - \(stationName)"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Recieve song data to play
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        let messageDict = message.data.message as! NSDictionary
        if let trackId = messageDict["trackId"] as? String, let currentPlaybackTime = messageDict["currentPlaybackTime"] as? Double, let trackName = messageDict["trackName"] as? String, let artistName = messageDict["artistName"] as? String {
            controller.setQueueWithStoreIDs([trackId])
            controller.play()
            controller.currentPlaybackTime = currentPlaybackTime
            self.trackName.text = trackName
            self.artistName.text = artistName
            thumbsDownButton.backgroundColor = UIColor.clear
            thumbsUpButton.backgroundColor = UIColor.clear
        }
    }
    
    //Unsubscribe from the radio station when they leave this view
    //The song that is currently playing will keep playing until finished unless the user joins a different station
    override func viewDidDisappear(_ animated: Bool) {
        appDelegate.client.unsubscribe(fromChannels: [channelName], withPresence: true)
    }
    
    //Dialogue showing error
    func showAlert(_ title: String, error: String) {
        let alertController = UIAlertController(title: title, message: error, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion:nil)
    }
}
