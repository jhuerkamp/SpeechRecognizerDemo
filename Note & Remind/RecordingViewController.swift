//
//  RecordingViewController.swift
//  Note & Remind
//
//  Created by Josh Huerkamp on 9/13/16.
//  Copyright © 2016 CapTech. All rights reserved.
//

import Foundation
import UIKit
import Speech

class RecordingViewController: UIViewController, SFSpeechRecognizerDelegate {
    // MARK: Properties
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    var speechResult = SFSpeechRecognitionResult()
    
    let noteCommands:[String] = [
    "note to ",
    "note "
    ]
    
    let remindCommands:[String] = [
    "remind me to ",
    "remind me ",
    "remind ",
    "reminder to ",
    "reminder "
    ]
    
    @IBOutlet weak var recordedTextLabel: UITextView!
    @IBOutlet weak var isRecordingLabel: UILabel!
    @IBOutlet weak var addNote: UIButton!
    @IBOutlet weak var addReminder: UIButton!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // The callback may not be called on the main thread. Add an
            // operation to the main queue to update the record button's state.
            OperationQueue.main.addOperation {
                var alertTitle = ""
                var alertMsg = ""
                
                switch authStatus {
                case .authorized:
                    do {
                        try self.startRecording()
                    } catch {
                        alertTitle = "Recorder Error"
                        alertMsg = "There was a problem starting the speech recorder"
                    }
                    
                case .denied:
                    alertTitle = "Speech recognizer not allowed"
                    alertMsg = "You enable the recgnizer in Settings"
                
                case .restricted, .notDetermined:
                    alertTitle = "Could not start the speech recognizer"
                    alertMsg = "Check your internect connection and try again"
                    
                }
                if alertTitle != "" {
                    let alert = UIAlertController(title: alertTitle, message: alertMsg, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                        self.dismiss(animated: true, completion: nil)
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func startRecording() throws {
        if !audioEngine.isRunning {
            let timer = Timer(timeInterval: 5.0, target: self, selector: #selector(RecordingViewController.timerEnded), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: .commonModes)
            
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let inputNode = audioEngine.inputNode else { fatalError("There was a problem with the audio engine") }
            guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create the recognition request") }
            
            // Configure request so that results are returned before audio recording is finished
            recognitionRequest.shouldReportPartialResults = true
            
            // A recognition task is used for speech recognition sessions
            // A reference for the task is saved so it can be cancelled
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                
                if let result = result {
                    print("result: \(result.isFinal)")
                    isFinal = result.isFinal
                    
                    self.speechResult = result
                    self.recordedTextLabel.text = result.bestTranscription.formattedString

                }
                
                if error != nil || isFinal {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
                
                self.addNote.isEnabled = self.recordedTextLabel.text != ""
                self.addReminder.isEnabled = self.recordedTextLabel.text != ""
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                self.recognitionRequest?.append(buffer)
            }
            
            print("Begin recording")
            audioEngine.prepare()
            try audioEngine.start()
            
            isRecordingLabel.text = "Recording"
        }
        
    }
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        print("Recognizer availability changed: \(available)")
        
        if !available {
            let alert = UIAlertController(title: "There was a problem accessing the recognizer", message: "Please try again later", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
            }))
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    func checkForActionPhrases() {
        var addNote = false
        var addReminder = false
        
        for segment in speechResult.bestTranscription.segments {
            // Don't search until the transcription size is at least 
            // the size of the shortest phrase
            if segment.substringRange.location >= 5 {
                // Separate segments to single words
                let best = speechResult.bestTranscription.formattedString
                let indexTo = best.index(best.startIndex, offsetBy: segment.substringRange.location)
                let substring = best.substring(to: indexTo)
                
                // Search for phrases
                addNote = substring.lowercased().contains("note ")
                addReminder = substring.lowercased().contains("remind")
            }
        }
        
        if addNote {
            recordedTextLabel.text = remove(commands: noteCommands, from: recordedTextLabel.text)
            addNoteTapped(nil)
        } else if addReminder {
            recordedTextLabel.text = remove(commands: remindCommands, from: recordedTextLabel.text)
            addReminderTapped(nil)
        }
    }
    
    // MARK: Buttons
    
    @IBAction func addNoteTapped(_ sender: UIButton?) {
        if audioEngine.isRunning {
            stopRecording()
        }
        
        let notesArray = NSMutableArray()
            
        if let currentNotes = UserDefaults.standard.array(forKey: "Notes") {
            notesArray.addObjects(from: currentNotes)
        }
        
        saveListEntry(entry: notesArray, listType: "Notes")
    }
    
    @IBAction func addReminderTapped(_ sender: UIButton?) {
        if audioEngine.isRunning {
            stopRecording()
        }
        let remindersArray = NSMutableArray()
        
        if let currentReminders = UserDefaults.standard.array(forKey: "Reminders") {
            remindersArray.addObjects(from: currentReminders)
        }
        
        saveListEntry(entry: remindersArray, listType: "Reminders")
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func saveListEntry(entry: NSMutableArray, listType: String) {
        entry.add(recordedTextLabel.text)
        
        UserDefaults.standard.setValue(entry, forKey: listType)
        
        isRecordingLabel.text = ""
        
        showSuccessAlert()
    }
    
    func transcripteAudioFile(audioFileURL: URL) {
        let fileURL = URL(fileURLWithPath: Bundle.main.path(forResource: "audio", ofType: ".mp3")!)
        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!

        
        let _ : SFSpeechRecognitionTask = recognizer.recognitionTask(with: request, resultHandler: { (result, error)   in
            if let error = error {
                print("There was an problem: \(error)")
            } else {
                print (result?.bestTranscription.formattedString)
            }
        })
    }
    
    func timerEnded() {
        // If the audio recording engine is running stop it and remove the SFSpeechRecognitionTask
        if audioEngine.isRunning {
            stopRecording()
            checkForActionPhrases()
        }
    }
    
    func remove(commands: [String], from recordedText: String) -> String {
        var tempText = recordedText
        
        // Search array of command strings and remove if found
        for command in commands {
            if let commandRange = tempText.lowercased().range(of: command) {
                // Find range from start of recorded text to the end of command found
                let range = Range.init(uncheckedBounds: (lower: tempText.startIndex, upper: commandRange.upperBound))
                // Remove the found range
                tempText.removeSubrange(range)
                print("Updated text: \(tempText)")
            }
        }
        
        return tempText
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        // Cancel the previous task if it's running
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
    }
    
    func showSuccessAlert() {
        if let savedText = recordedTextLabel.text {
            let alert = UIAlertController(title: "Note Added", message: "\(savedText) added.  Add another?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { (action) in
                do {
                    try self.startRecording()
                } catch {
                    print("There was a problem starting the speech recorder")
                    let alert = UIAlertController(title: "Recorder Error", message: "There was a problem starting the speech recorder", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                }
            }))
            alert.addAction(UIAlertAction(title: "NO", style: .default, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
            }))
            
            present(alert, animated: true, completion: nil)
        }
    }
}
