//
//  PortraitTabBarController.swift
//  Repped
//
//  Created by Wes Draper on 3/10/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit

class PortraitTabBarController: UITabBarController {
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion > 9 {
            //			tabBar.isTranslucent = false
        }
    }
    
}
