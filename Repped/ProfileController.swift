//
//  ProfileConroller.swift
//  Repped
//
//  Created by Wes Draper on 3/9/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import Firebase

class ProfileController: UIViewController {
    
    private lazy var joinRef:FIRDatabaseReference = FIRDatabase.database().reference().child("joinTable")
    
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
        
        //TODO: move returnProfilePic function to user class so it's dynamic for all users.
        self.profileImage.image = self.user?.profilePicture
        self.profileImage.layer.cornerRadius = self.profileImage.frame.size.width / 2
        self.profileImage.clipsToBounds = true
        self.profileImage.layer.borderWidth = 3.0
        
        self.nameLabel.text = self.user?.name
        self.repLabel.text = String(describing: (self.user?.rep)!)
        
        isUserLive()
        
    }
    
    private func isUserLive() {
        self.liveSymbol.layer.cornerRadius = self.liveSymbol.frame.size.width / 2
        self.liveSymbol.clipsToBounds = true
        self.liveSymbol.layer.borderWidth = 2.0
        self.liveSymbol.backgroundColor = UIColor.white
        
        self.joinRef.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
            if (snapshot.hasChild((self.user?.uid)!)) {
                // User is online
                self.liveSymbol.backgroundColor = UIColor.green
            }
        })
    }
    
    
}
