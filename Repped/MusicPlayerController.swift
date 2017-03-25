//
//  MusicPlayerController.swift
//  Repped
//
//  Created by Wes Draper on 3/10/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import LNPopupController

class MusicPlayerController: UIViewController {
    
    
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumArtImageView: UIImageView!
    
    @IBOutlet weak var progressView: UISlider!
    
    let global:Global = Global.sharedGlobal
    
    let accessibilityDateComponentsFormatter = DateComponentsFormatter()
    
    var timer : Timer?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        songNameLabel.text = (self.global.song?.trackName)!
        albumArtImageView.image = (self.global.song?.artWork)!
        albumNameLabel.text = (self.global.song?.artistName)!
        
        popupItem.image = (self.global.song?.artWork)!
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //Need to check for if user is the leader -> show different Controls TODO
        let pause = UIBarButtonItem(image: UIImage(named: "pause"), style: .plain, target: nil, action: nil)
        pause.accessibilityLabel = NSLocalizedString("Pause", comment: "")
        let next = UIBarButtonItem(image: UIImage(named: "nextFwd"), style: .plain, target: nil, action: nil)
        next.accessibilityLabel = NSLocalizedString("Next Track", comment: "")
        
        self.popupItem.leftBarButtonItems = [ pause ]
        self.popupItem.rightBarButtonItems = [ next ]
        
        accessibilityDateComponentsFormatter.unitsStyle = .spellOut
        
    }
        
   }
