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
    
    static let videoLoopActionSelector:Selector = "videoLoopAction"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player = AVPlayer.init(URL: linkVideoFileURL)
        self.showsPlaybackControls = false
        
        self.player?.play()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: PreviewAVPlayerViewController.videoLoopActionSelector, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func videoLoopAction() {
        self.player?.currentItem?.seekToTime(kCMTimeZero)
        self.player?.play()
    }
}
