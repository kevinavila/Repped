//
//  RoomCellView.swift
//  Repped
//
//  Created by Wes Draper on 3/1/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import UIKit

class RoomViewCell: UITableViewCell {
    @IBOutlet weak var listenerLabel: UILabel!

    //this might need to be in the room controller
    @IBAction func makeLeaderButton(_ sender: Any) {
        print("tried to make " + listenerLabel.text! + " the leader")
    }


}
