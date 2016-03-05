//
//  ViewController.swift
//  loop-the-loop
//
//  Created by kenta.imai on 2016/03/05.
//  Copyright © 2016年 henteko. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet var captureView: UIView!
    var videoLayer: AVCaptureVideoPreviewLayer!
    let AlbumTitle = "LoopTheLoop"
    var videoCapture: VideoCapture!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.videoCapture = VideoCapture.init(completion: { (linkVideoFileURL) -> Void in
            let videoLocalSave = VideoLocalSave.init(albumName: self.AlbumTitle)
            videoLocalSave.save(linkVideoFileURL, completion: { (success, error) -> Void in
                if (!success) {
                    print("Error")
                    print(error)
                } else {
                    print("Saved movie!")
                }
            })
        })
        
        // Preview
        self.videoLayer = AVCaptureVideoPreviewLayer.init(session: videoCapture.captureSession)
        self.videoLayer.frame = self.captureView.bounds
        self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.captureView.layer.addSublayer(videoLayer)
        
        self.videoCapture.start()
    }
    
    @IBAction func longPressCaptureView(sender: UILongPressGestureRecognizer!) {
        switch sender.state {
        case .Began:
            // LongPress開始
            self.videoCapture.startRecording()
            break
        case .Cancelled:
            break
        case .Ended:
            // LongPress終了
            self.videoCapture.stopRecording()
            break
        case .Failed:
            break
        default:
            // LongPress中
            break
        }
    }
}

