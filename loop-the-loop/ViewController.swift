//
//  ViewController.swift
//  loop-the-loop
//
//  Created by kenta.imai on 2016/03/05.
//  Copyright © 2016年 henteko. All rights reserved.
//

import UIKit
import AVFoundation
import SVProgressHUD

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
                    self.dispatch_async_global {
                        self.dispatch_async_main {
                            SVProgressHUD.showErrorWithStatus("動画の保存に失敗しました…")
                        }
                    }
                    print("Error")
                    print(error)
                } else {
                    self.dispatch_async_global {
                        self.dispatch_async_main {
                            SVProgressHUD.showSuccessWithStatus("動画を保存しました!")
                        }
                    }
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
            SVProgressHUD.showWithStatus("保存中")
            break
        case .Failed:
            break
        default:
            // LongPress中
            print("default")
            break
        }
    }
    
    func dispatch_async_main(block: () -> ()) {
        dispatch_async(dispatch_get_main_queue(), block)
    }
    
    func dispatch_async_global(block: () -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
    }
}

