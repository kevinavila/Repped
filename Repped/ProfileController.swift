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
    private var otherUserRef:FIRDatabaseReference?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var repLabel: UILabel!
    @IBOutlet weak var liveSymbol: UIView!
    @IBOutlet weak var liveLabel: UILabel!
    
    var otherUserID:String = ""
    var otherName:String?
    var otherProfileImage:UIImageView?
    
    var user:User? = nil
    
    var global:Global = Global.sharedGlobal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (user != nil) {
            // Load our profile
            self.profileImage.image = self.user?.profilePicture
            self.nameLabel.text = self.user?.name
            self.repLabel.text = String(describing: (self.user?.rep)!)
        } else {
            // Loadother user's profile
            self.profileImage.image = self.otherProfileImage?.image
            self.nameLabel.text = self.otherName
            
            // Still need to retrieve rep
            otherUserRef = FIRDatabase.database().reference().child("users/\(otherUserID)")
            otherUserRef?.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
                let results = snapshot.value as! Dictionary<String, AnyObject>
                let rep = results["rep"] as! Int
                print("OTHER USER REP: \(rep)")
                self.repLabel.text = String(rep)
                
            })
        }
        
        self.profileImage.layer.cornerRadius = self.profileImage.frame.size.width / 2
        self.profileImage.clipsToBounds = true
        self.profileImage.layer.borderWidth = 3.0
        self.profileImage.layer.borderColor = UIColor(red:0.29, green:0.67, blue:0.75, alpha:1.0).cgColor
        
        isUserLive()
    }
    
    private func isUserLive() {
        self.liveSymbol.layer.cornerRadius = self.liveSymbol.frame.size.width / 2
        self.liveSymbol.clipsToBounds = true
        self.liveSymbol.layer.borderWidth = 2.0
        self.liveSymbol.layer.borderColor = UIColor(red:0.29, green:0.67, blue:0.75, alpha:1.0).cgColor
        self.liveSymbol.backgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1.0)
        
        self.joinRef.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
            var lookupID = ""
            if (self.user != nil) {
                lookupID = (self.user?.uid)!
            } else {
                lookupID = self.otherUserID
            }

            if (snapshot.hasChild(lookupID)) {
                // User is online
                self.liveSymbol.backgroundColor = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
            }
        })
    }
    
    
}
