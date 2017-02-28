//
//  AppDelegate.swift
//  Repped
//
//  Created by Kevin Avila on 2/8/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import StoreKit
import MediaPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FIRApp.configure()
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        requestAppleMusicPermission() // should this also be called in ApplicationDidBecomeActive?
        
        // Uncomment to allow app to remember login info
        let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
        
        if let window = self.window {
            if (FBSDKAccessToken.current() != nil) {
                // User has already been authenticated
                let homeNavController = homeStoryboard.instantiateViewController(withIdentifier: "homeNavController")
                window.rootViewController = homeNavController
                
            } else {
                // User must login
                let loginController = loginStoryboard.instantiateViewController(withIdentifier: "loginController")
                window.rootViewController = loginController
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // Request Apple Music Permission
    func requestAppleMusicPermission() {
        switch SKCloudServiceController.authorizationStatus() {
            
        case .authorized:
            print("The user's already authorized - we don't need to do anything more here, so we'll exit early.")
            self.checkIfUserHasAppleMusic()
            return
            
        case .denied:
            print("The user has selected 'Don't Allow' in the past - so we're going to show them a different dialog to push them through to their Settings page and change their mind, and exit the function early.")
            // Show an alert to guide users into the Settings
            return
            
        case .notDetermined:
            print("The user hasn't decided yet - so we'll break out of the switch and ask them.")
            break
            
        case .restricted:
            print("User may be restricted; for example, if the device is in Education mode, it limits external Apple Music usage. This is similar behaviour to Denied.")
            return
        }
        
        SKCloudServiceController.requestAuthorization { (status:SKCloudServiceAuthorizationStatus) in
            switch status {
                
            case .authorized:
                print("All good - the user tapped 'OK'.")
                self.checkIfUserHasAppleMusic()
                
            case .denied:
                print("The user tapped 'Don't allow'.")
                
            case .notDetermined:
                print("The user hasn't decided or it's not clear whether they've confirmed or denied.")
                
            default: break
                
            }
            
        }
        
    }

    // Check if user has Apple Music membership
    func checkIfUserHasAppleMusic() {
        let serviceController = SKCloudServiceController()
        serviceController.requestCapabilities(completionHandler: { (capability:SKCloudServiceCapability, err:Error?) in
            if (err != nil) {
                print(err!.localizedDescription)
                print("An error occured when trying to validate Apple Music membership.")
            }
            
            if (capability.rawValue >= SKCloudServiceCapability.addToCloudMusicLibrary.rawValue) {
                print("The user has an Apple Music subscription, can playback music AND can add to the Cloud Music Library")
            } else if (capability.rawValue == SKCloudServiceCapability.musicCatalogPlayback.rawValue) {
                print("The user has an Apple Music subscription and can playback music!")
            } else {
                print("The user doesn't have an Apple Music subscription available. Now would be a good time to prompt them to buy one?")
            }
            
        })
        
    }

}

