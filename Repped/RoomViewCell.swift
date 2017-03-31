//
//  roomViewCell.swift
//  Repped
//
//  Created by Wes Draper on 3/4/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit

class RoomViewCell: UITableViewCell {
    @IBOutlet weak var listenerLabel: UILabel!
    @IBOutlet weak var makeLeaderLabel: UIButton!
    
    var tapAction: ((UITableViewCell) -> Void)?
    
    @IBAction func makeLeader(_ sender: Any) {
        tapAction?(self)
    }
    
}
