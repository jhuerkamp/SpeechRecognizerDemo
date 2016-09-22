//
//  ViewController.swift
//  Note & Remind
//
//  Created by Josh Huerkamp on 9/12/16.
//  Copyright © 2016 CapTech. All rights reserved.
//

import UIKit
import Speech

class NotesNRemindDisplayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: Properties

    @IBOutlet weak var reminderTable: UITableView!
    @IBOutlet weak var notesTable: UITableView!
    
    var remindersArray: NSMutableArray = []//UserDefaults.standard.mutableArrayValue(forKey: "Notes")
    var notesArray: NSMutableArray = []//UserDefaults.standard.mutableArrayValue(forKey: "Notes")

    @IBOutlet var recordingLabel : UILabel!
    
    @IBOutlet var recordButton : UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (UserDefaults.standard.object(forKey: "Notes") == nil) {
            UserDefaults.standard.setValue([], forKey: "Notes")
        }
        
        if (UserDefaults.standard.object(forKey: "Reminders") == nil){
            UserDefaults.standard.setValue([], forKey: "Reminders")
        }
        
        notesArray = UserDefaults.standard.mutableArrayValue(forKey: "Notes")
        remindersArray = UserDefaults.standard.mutableArrayValue(forKey: "Reminders")
        notesTable.reloadData()
        reminderTable.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notesTable.register(NoteCell.classForCoder(), forCellReuseIdentifier: "NoteCell")
        reminderTable.register(ReminderCell.classForCoder(), forCellReuseIdentifier: "ReminderCell")
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == reminderTable {
            return remindersArray.count
        } else {
            return notesArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == reminderTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell", for: indexPath) //as! ReminderCell
            cell.textLabel?.text = remindersArray[indexPath.row] as? String
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath) //as! NoteCell
            if let note = notesArray[indexPath.row] as? String {
                print(note)
                cell.textLabel?.text = note
            }
            
            return cell
        }
    }
}

