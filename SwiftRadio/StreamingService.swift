//
//  StreamingService.swift
//  Maxi80
//
//  Created by Stormacq, Sebastien on 07/11/2018.
//  Copyright © 2018 stormacq.com. All rights reserved.
//

import Foundation
import MediaPlayer

// our main class to handle the streaming
class StreamingService : NSObject {

    private var radioPlayer : AVPlayer?
    private var playerItem : AVPlayerItem?

    let LOG = Logger.createOSLog(module: "Streaming Service")

    //*****************************************************************
    // MARK: - Service initialisation
    //*****************************************************************

    func start() {
        
        let app = UIApplication.shared.delegate as! AppDelegate
        
        playerItem = AVPlayerItem(url: URL(string: app.station.streamUrl)!)
        
        // add observer for meta data
        playerItem!.addObserver(self,
                                forKeyPath: #keyPath(AVPlayerItem.timedMetadata), //"timedMetadata",
                                options: NSKeyValueObservingOptions(),
                                context: nil)
        
        // add observer for the player item's status property
        playerItem!.addObserver(self,
                                forKeyPath: #keyPath(AVPlayerItem.status),
                                options: [.old, .new],
                                context: nil)
        
        // Notification for AVAudioSession Interruption (e.g. Phone call)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterrupted),
                                               name: AVAudioSession.interruptionNotification,
                                               object: AVAudioSession.sharedInstance())
        
        radioPlayer = AVPlayer(playerItem: playerItem)
        radioPlayer!.play()
    }
    
    func stop() {
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.interruptionNotification,
                                                  object: AVAudioSession.sharedInstance())

        radioPlayer?.pause()
        playerItem?.removeObserver(self,
                                   forKeyPath: #keyPath(AVPlayerItem.timedMetadata))
        playerItem?.removeObserver(self,
                                   forKeyPath: #keyPath(AVPlayerItem.status))
        radioPlayer = nil
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
  
        let app = UIApplication.shared.delegate as! AppDelegate

        if keyPath == #keyPath(AVPlayerItem.status) {
            let playerItem = of as! AVPlayerItem
            let status: AVPlayerItem.Status
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over the status
            switch status {
                case .readyToPlay:
                    // Player item is ready to play.
                    os_log_debug(LOG,"Player is ready to play")
                    app.isPlaying = true
                
                case .failed:
                    // Player item failed. See error.
                    os_log_debug(LOG,"Player failed. \(String(describing: playerItem.error))")
                    stop()
                
                case .unknown:
                    // Player item is not yet ready.
                    os_log_debug(LOG,"Player status unknown.")
                    stop()
            }
            
        } else if keyPath == #keyPath(AVPlayerItem.timedMetadata) {
            let playerItem = of as! AVPlayerItem
            let firstMeta = playerItem.timedMetadata?.first
            let metaData = firstMeta?.value as! String
            
            // let the app known
            app.handleiCyMetaData(metadata: metaData)
        }
    }
    
    //*****************************************************************
    // MARK: - AVAudio Sesssion Interrupted
    //*****************************************************************
    
    // Example code on handling AVAudio interruptions (e.g. Phone calls)
    @objc func sessionInterrupted(notification: NSNotification) {
        if let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber{
            if let type = AVAudioSession.InterruptionType(rawValue: typeValue.uintValue){
                if type == .began {
                    os_log_debug(LOG, "AVAudio Interruption: began")
                    // Add your code here
                    
                    // TODO isPlaying = false ?
                } else{
                    os_log_debug(LOG, "AVAudio Interruption: ended")
                    
                    // Add your code here
                }
            }
        }
    }
}
