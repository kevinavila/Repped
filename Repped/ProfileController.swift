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
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var repLabel: UILabel!
    @IBOutlet weak var liveSymbol: UIView!
    @IBOutlet weak var liveLabel: UILabel!
    @IBOutlet weak var addFriendButton: UIButton!
    
    var global:Global = Global.sharedGlobal
    var user:User? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.profileImage.image = self.user?.profilePicture
        self.profileImage.layer.cornerRadius = self.profileImage.frame.size.width / 2
        self.profileImage.clipsToBounds = true
        self.profileImage.layer.borderWidth = 3.0
        
        self.nameLabel.text = self.user?.name
        self.repLabel.text = String(describing: (self.user?.rep)!)
        
    }
    
    
}
