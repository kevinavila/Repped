//
//  StationListViewController.swift
//  RadioStation
//
//  Created by Keith Martin on 6/22/16.
//  Copyright © 2016 Keith Martin. All rights reserved.
//

/*
 * This class displays all radio stations created 
 * A user can touch a cell to segue to that radio station
 */

import UIKit
import PubNub

class StationListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var stationNames: [String] = []
    var channelNames: [String] = []
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        stationNames.removeAll()
        channelNames.removeAll()
        //Go through the history of the channel holding all stations created
        //Update table view with history list
        appDelegate.client.history(forChannel: "All_Stations") { (result, status) in
            for message  in (result?.data.messages)! {
                let messageDict = message as! NSDictionary
                if let stationName = messageDict["stationName"] as? String{
                    if let channelName = messageDict["channelName"] as? String{
                        self.stationNames.append(stationName)
                        self.channelNames.append(channelName)
                    }
                }
            }
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Store the PubNub channelName in the detailTextLabel
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: nil)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = stationNames[stationNames.startIndex.advanced(by: indexPath.row)]
        cell.detailTextLabel?.text = channelNames[channelNames.startIndex.advanced(by: indexPath.row)]
        cell.detailTextLabel?.isHidden = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelNames.count
    }
    
    //Segue to that radio station and pass the channel name and station name
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let stationVC = self.storyboard?.instantiateViewController(withIdentifier: "StationViewController") as! StationViewController
        stationVC.channelName = (cell?.detailTextLabel?.text)!
        stationVC.stationName = (cell?.textLabel?.text)!
        self.navigationController?.pushViewController(stationVC, animated: true)
    }
    
    //Dialogue showing error
    func showAlert(_ title: String, error: String) {
        let alertController = UIAlertController(title: title, message: error, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion:nil)
    }
    
}
