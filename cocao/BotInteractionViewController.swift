//
//  BotInteractionViewController.swift
//  cocao
//
//  Created by Josh Wolff on 2/17/18.
//  Copyright © 2018 jw1. All rights reserved.
//

import Foundation
import UIKit
import Speech
import HoundifySDK
import ROGoogleTranslate

class BotInteractionViewController: UIViewController, UIGestureRecognizerDelegate, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var botGraphic: UIImageView!
    @IBOutlet weak var chatContent : UIView!
    
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var stopRecordingButton: UIButton!
    
    @IBOutlet weak var recordedResponse: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: ChatConstantsAndFunctions.spanishMicrosoft))
    // ADD PICKER AND DELEGATE
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var queryText = ""
    private var translatedText = ""
    
    private var isFinalQuery = false

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.hideResponseUI()
        self.setUpUI()
        self.setUpSpeechRecognition()
        
    }
    
    func setUpSpeechRecognition () {
        
        self.microphoneButton.isEnabled = false  //2
        self.speechRecognizer?.delegate = self  //3
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            if (authStatus == .authorized) {
                isButtonEnabled = true
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
        
    }
    
    func setUpUI () {
        self.recordedResponse.layer.cornerRadius = 5
        self.recordedResponse.layer.masksToBounds = true
    }
    
    func hideResponseUI () {
        self.recordedResponse.isHidden = true
        self.stopRecordingButton.isHidden = true
        self.sendButton.isHidden = true
        self.cancelButton.isHidden = true
        self.chatContent.isHidden = false
    }
    
    func showResponseUI () {
        self.recordedResponse.isHidden = false
        self.chatContent.isHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "segueEmbedChat") {
//            let embeddedChatViewController = segue.destination  as! ChatTableViewController
//            embeddedChatViewController.loadConversation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func startRecording() {
        
        self.isFinalQuery = false
        
        let audioEngine = AVAudioEngine()
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                print("HERE IS THE RESULT")
                print("\(result?.bestTranscription.formattedString)")
                isFinal = (result?.isFinal)!
                
                self.queryText = (result?.bestTranscription.formattedString)!
                self.recordResponse(response: self.queryText)
            }
            // error != nil
            if self.isFinalQuery {
                audioEngine.stop()
                print("didStop")
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.microphoneButton.isEnabled = true
        } else {
            self.microphoneButton.isEnabled = false
        }
    }
    
    func translateQueryToEnglish (text: String) {
//        let error : NSError?
//        let result : String?
//        let urlResponse : URLResponse?
//        print("TRANSLATING QUERY")
//        AzureMicrosoftTranslator.translate(text: text, toLang: "en") { (result, urlResponse, error) in
//            print("completion handler")
//            print("\(String(describing: result))")
//        }
        
        var params = ROGoogleTranslateParams(source: ChatConstantsAndFunctions.spanishMicrosoft,
                                             target: ChatConstantsAndFunctions.englishLanguageMicrosoft,
                                             text:   text)

        let translator = ROGoogleTranslate()
        translator.apiKey = ChatConstantsAndFunctions.GOOGLE_API_KEY
        print("\(params)")
        translator.translate(params: params) { (result) in
            self.queryHoundify(aQuery: result)
            print("WITHIN TRANSLATION FUNCITON")
            print("Translation: \(result)")
            self.translatedText = result
        }
    }
    
//    func recordHoundify () {
//        Houndify.instance().presentListeningViewController(in: self,
//                                                           from: nil,
//                                                           style: nil,
//                                                           requestInfo: [:],
//                                                           responseHandler:
//            { (error: Error?, response: Any?, dictionary: [String : Any]?, requestInfo: [String : Any]?) in
//
//                var responseData : String = ""
//                if  let serverData = response as? HoundDataHoundServer,
//                    let commandResult = serverData.allResults?.firstObject() as? HoundDataCommandResult,
//                    let nativeData = commandResult["NativeData"]
//                {
//                    let myStringDict = nativeData as? [String : AnyObject]
//                    responseData = myStringDict!["FormattedTranscription"]! as! String
//                    print(myStringDict!["FormattedTranscription"]!)
//
//                }
//                self.recordResponse(response: responseData)
//                self.dismissSearch()
//            }
//        )
//    }
    
    func queryHoundify(aQuery: String) {
        HoundTextSearch.instance().search(withQuery: aQuery, requestInfo: nil, completionHandler:
            { (error: Error?, myQuery: String, houndServer: HoundDataHoundServer?, dictionary: [String : Any]?, requestInfo: [String : Any]?) in
                    if houndServer != nil, let dictionary = dictionary, let response = houndServer {
                        if let commandResult = response.allResults?.firstObject() as? HoundDataCommandResult {
                            print(commandResult["SpokenResponse"]!)
                        }
                    
                }
            }
        )
    }
    
    
//  MARK:- IB ACTIONS
    
    @IBAction func recordText () {
        
        self.queryText = ""
        self.isFinalQuery = false
        self.microphoneButton.isHidden = true
        self.stopRecordingButton.isHidden = false
        self.startRecording()
        
    }
    
    @IBAction func stopRecording () {
        self.microphoneButton.isHidden = false
        self.stopRecordingButton.isHidden = true
        self.isFinalQuery = true
        print("TRANSLATION")
        print(self.queryText)
        
        self.stopRecordingButton.isHidden = true
        self.cancelButton.isHidden = false
        self.sendButton.isHidden = false
        
        self.translateQueryToEnglish(text: self.queryText)
    }
    
    fileprivate func dismissSearch() {
        Houndify.instance().dismissListeningViewController(animated: true, completionHandler: nil)
    }
    
    func recordResponse (response: String) {
        self.showResponseUI()
        self.recordedResponse.text = " " + response
    }
    
    @IBAction func cancelResponse () {
        self.hideResponseUI()
        self.recordedResponse.text = ""
    }
    
    @IBAction func sendResponse () {
        let newChat = ChatMessage(_userId: ChatConstantsAndFunctions.userId, _message: self.recordedResponse.text, _chatId: String(describing: ChatMessage.fetchChats().count))
        self.queryHoundify(aQuery: self.translatedText)
        ChatConstantsAndFunctions.newChats.append(newChat)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "loadChats"), object: nil)
        self.hideResponseUI()
    }
    
}
