//
//  MusicViewCell.swift
//  Repped
//
//  Created by Wes Draper on 4/2/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit

class MusicViewCell: UITableViewCell {
    
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var mainText: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var repButtonOutlet: UIButton!
    
    var tapAction: ((UITableViewCell) -> Void)?
    
    @IBAction func repButton(_ sender: Any) {
        print("clicked Rep")
        tapAction?(self)
    }
    
}
