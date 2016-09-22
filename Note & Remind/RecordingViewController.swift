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
                    try! self.startRecording()
                    
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
    
    private func startRecording() throws {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            // Cancel the previous task if it's running
            if let recognitionTask = recognitionTask {
                recognitionTask.cancel()
                self.recognitionTask = nil
            }
        } else {
            
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
                    // Log best results and segment inof
                    print("Best Transcription: \(result.bestTranscription.formattedString)")
                    for segment in result.bestTranscription.segments {
                        print("Timestamp: \(segment.timestamp)")
                        print("Confidence: \(segment.confidence)")
                        print("Duration: \(segment.duration)")
                    }
                    
                    // Log alternate results and segment info
                    for altTranscription in result.transcriptions {
                        print("Alternate transcription: \(altTranscription.formattedString)")
                        for segment in altTranscription.segments {
                            print("Timestamp: \(segment.timestamp)")
                            print("Confidence: \(segment.confidence)")
                            print("Duration: \(segment.duration)")
                        }
                    }
                    self.recordedTextLabel.text = result.bestTranscription.formattedString
                    isFinal = result.isFinal
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
    
    // MARK: Buttons
    
    @IBAction func addNoteTapped(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            // Cancel the previous task if it's running
            if let recognitionTask = recognitionTask {
                recognitionTask.cancel()
                self.recognitionTask = nil
            }
        }
        
        var notesArray = UserDefaults.standard.mutableArrayValue(forKey: "Notes")
        
        if notesArray.count == 0 {
            notesArray = []
        }
        
        saveListEntry(entry: notesArray, listType: "Notes")
    }
    
    @IBAction func addReminderTapped(_ sender: UIButton) {
        var remindersArray = UserDefaults.standard.mutableArrayValue(forKey: "Reminders")
        
        if remindersArray.count == 0 {
            remindersArray = []
        }
        
        saveListEntry(entry: remindersArray, listType: "Reminders")
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func saveListEntry(entry: NSMutableArray, listType: String) {
        entry.add(recordedTextLabel.text)
        
        UserDefaults.standard.setValue(entry, forKey: listType)
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            isRecordingLabel.text = ""
        }
        
        dismiss(animated: true, completion: nil)
    }
}
