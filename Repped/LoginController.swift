//
//  ViewController.swift
//  Repped
//
//  Created by Kevin Avila on 2/8/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FBSDKLoginKit

class LoginController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet weak var facebookLoginButton: FBSDKLoginButton!
    var global:Global = Global.sharedGlobal
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        facebookLoginButton.delegate = self
        facebookLoginButton.readPermissions = ["public_profile", "email", "user_friends"]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if (error != nil) {
            print(error!.localizedDescription)
            return
        } else if (result.isCancelled) {
            // User canceled login: do something
        } else {
            print("User logged into Facebook.")
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                if let error = error {
                    print(error)
                    return
                }
                print("User authenticated with Firebase.")
                self.fillInUser()
                
                // Go to home screen
                self.performSegue(withIdentifier: "homeSegue", sender: self)
            }
        }
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        return true
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        try! FIRAuth.auth()!.signOut()
        FBSDKAccessToken.setCurrent(nil)
        print("User logged out of Facebook and Firebase.")
    }
    
    private func fillInUser(){
        print("fillin uer in login controller")
        print(((FBSDKAccessToken.current()) != nil))
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email"]).start(completionHandler: { (connection, result, error) -> Void in
                let fBData = result as! [String:Any]
                if (error == nil){
                    //Set user info locally
                    self.global.user = User(uid: fBData["id"] as! String, name: fBData["name"] as! String)
                    self.global.user?.email =  fBData["email"] as! String
                    self.global.user?.profilePicture = self.returnProfilePic(fBData["id"] as! String)
                    
                    //set user info in firebase
                    let user = [
                        "name": fBData["name"]!,
                        "email": fBData["email"]!,
                        "rep": 0,
                        "id": fBData["id"]!,
                        ] as [String:Any]
                    self.userRef.child(fBData["id"] as! String).setValue(user)
                    
                }
            })
        }
    }
    
    private func returnProfilePic(_ id:String) -> UIImage{
        let facebookProfileUrl = NSURL(string: "http://graph.facebook.com/\(id)/picture?type=large")
        
        let image:UIImage
        if let data = NSData(contentsOf: facebookProfileUrl as! URL) {
            image = UIImage(data: data as Data)!
        } else {
            image = #imageLiteral(resourceName: "noprofile")
        }
        return image
    }
}

