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
    var videoCapture: VideoCapture!
    var defaultTintColor: UIColor!
    var linkVideoFileURL: NSURL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defaultTintColor = self.navigationController?.navigationBar.barTintColor
        
        self.videoCapture = VideoCapture.init(completion: { (linkVideoFileURL) -> Void in
            self.dispatch_async_global {
                self.dispatch_async_main {
                    SVProgressHUD.dismiss()
                    self.linkVideoFileURL = linkVideoFileURL
                    self.performSegueWithIdentifier("PreviewSegue", sender: nil)
                }
            }
        })
        
        // Preview
        self.videoLayer = AVCaptureVideoPreviewLayer.init(session: videoCapture.captureSession)
        self.videoLayer.frame = self.captureView.bounds
        self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.captureView.layer.addSublayer(videoLayer)
        
        self.videoCapture.start()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "PreviewSegue") {
            let previewAVPlayerViewController: PreviewAVPlayerViewController = (segue.destinationViewController as? PreviewAVPlayerViewController)!
            previewAVPlayerViewController.linkVideoFileURL = self.linkVideoFileURL
        }
    }
    
    @IBAction func longPressCaptureView(sender: UILongPressGestureRecognizer!) {
        switch sender.state {
        case .Began:
            // LongPress開始
            self.videoCapture.startRecording()
            self.navigationController?.navigationBar.barTintColor = UIColor.redColor()
            break
        case .Cancelled:
            break
        case .Ended:
            // LongPress終了
            self.videoCapture.stopRecording()
            self.navigationController?.navigationBar.barTintColor = self.defaultTintColor
            SVProgressHUD.showWithStatus("動画作成中")
            break
        case .Failed:
            break
        default:
            // LongPress中
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

