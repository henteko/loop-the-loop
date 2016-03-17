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
    var currentRate: Float = 1.0
    let maxRate: Float = 1.9
    
    static let videoLoopActionSelector:Selector = "videoLoopAction"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player = AVPlayer.init(URL: linkVideoFileURL)
        self.showsPlaybackControls = false
        
        self.player?.play()
        self.player!.rate = currentRate
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: PreviewAVPlayerViewController.videoLoopActionSelector, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func videoLoopAction() {
        self.player?.currentItem?.seekToTime(kCMTimeZero)
        self.player?.play()
        self.player!.rate = currentRate
    }
    
    func speedUp() -> Float {
        if currentRate >= maxRate {
            return currentRate
        }
        
        currentRate += 0.1
        self.player!.rate = currentRate
        
        return currentRate
    }
    
    func speedDown() -> Float {
        if currentRate <= 0.1 {
            return currentRate
        }
        
        currentRate -= 0.1
        if currentRate < 0.1 {
            currentRate = 0.1
        }
        self.player!.rate = currentRate
        
        return currentRate
    }
}
