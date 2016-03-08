//
//  PreviewViewController.swift
//  loop-the-loop
//
//  Created by kenta.imai on 2016/03/08.
//  Copyright © 2016年 henteko. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import SVProgressHUD

class PreviewViewController: UIViewController {
    
    let AlbumTitle = "LoopTheLoop"
    var linkVideoFileURL: NSURL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "playerViewControllerSegue") {
            let previewAVPlayerViewController: PreviewAVPlayerViewController = (segue.destinationViewController as? PreviewAVPlayerViewController)!
            previewAVPlayerViewController.linkVideoFileURL = self.linkVideoFileURL
        }
    }
    
    @IBAction func localSave(sender: AnyObject) {
        SVProgressHUD.showWithStatus("保存中")
        
        let videoLocalSave = VideoLocalSave.init(albumName: self.AlbumTitle)
        videoLocalSave.save(self.linkVideoFileURL, completion: { (success, error) -> Void in
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
        
    }
    
    func dispatch_async_main(block: () -> ()) {
        dispatch_async(dispatch_get_main_queue(), block)
    }
    
    func dispatch_async_global(block: () -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
    }
}