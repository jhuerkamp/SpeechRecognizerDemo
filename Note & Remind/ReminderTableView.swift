//
//  RemindListTableViewController.swift
//  Note & Remind
//
//  Created by Josh Huerkamp on 9/12/16.
//  Copyright © 2016 CapTech. All rights reserved.
//

import UIKit

class ReminderTableView : UITableView, UITableViewDelegate, UITableViewDataSource {
    
    var remindersArray: NSMutableArray = []//UserDefaults.standard.mutableArrayValue(forKey: "Notes")
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return remindersArray.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell") as! ReminderCell
        cell.reminderLabel.text = remindersArray[indexPath.row] as? String
        
        return cell
    }
    
}
