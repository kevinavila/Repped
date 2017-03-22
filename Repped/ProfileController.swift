//
//  ProfileConroller.swift
//  Repped
//
//  Created by Wes Draper on 3/9/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import Firebase

class ProfileController: UIViewController{
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    var global:Global = Global.sharedGlobal
    var user:User? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.nameLabel.text = self.user?.name
        self.roomLabel.text = self.global.room?.name
        self.profileImage.image = self.user?.profilePicture
    }
    
    
}
