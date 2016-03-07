//
//  PreviewAVPlayerViewController.swift
//  loop-the-loop
//
//  Created by kenta.imai on 2016/03/07.
//  Copyright © 2016年 henteko. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class PreviewAVPlayerViewController: AVPlayerViewController {
    
    let AlbumTitle = "LoopTheLoop"
    var linkVideoFileURL: NSURL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player = AVPlayer.init(URL: linkVideoFileURL)
        self.showsPlaybackControls = false
        
        self.player?.play()
        
        let notificationCenter: NSNotificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: nil, queue: nil) { (notification: NSNotification) -> Void in
            self.player?.currentItem?.seekToTime(kCMTimeZero)
            self.player?.play()
        }
    }
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
