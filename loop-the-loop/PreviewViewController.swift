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
import PermissionScope

class PreviewViewController: UIViewController {
    
    let AlbumTitle = "LoopTheLoop"
    var linkVideoFileURL: NSURL!
    var previewAVPlayerViewController: PreviewAVPlayerViewController!
    @IBOutlet weak var rateLabel: UILabel!
    let pscope = PermissionScope()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pscope.viewControllerForAlerts = self
        pscope.onAuthChange = { [unowned self] (finished, results) in
            if results[0].status == .Authorized {
                self.save()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "playerViewControllerSegue") {
            previewAVPlayerViewController = (segue.destinationViewController as? PreviewAVPlayerViewController)!
            previewAVPlayerViewController.linkVideoFileURL = self.linkVideoFileURL
        }
    }
    
    @IBAction func localSave(sender: AnyObject) {
        permissionRequest()
    }
    
    func save() {
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
    
    func permissionRequest() {
        switch pscope.statusPhotos() {
        case .Authorized:
            save()
            break
        case .Unknown, .Unauthorized, .Disabled:
            pscope.requestPhotos()
            break
        }
    }
    
    @IBAction func swipeUpAction(gestureRecognizer: UIGestureRecognizer!) {
        showAnimationLabel(String(previewAVPlayerViewController.speedUp()))
    }
    
    @IBAction func swipeDownAction(sender: AnyObject) {
        showAnimationLabel(String(previewAVPlayerViewController.speedDown()))
    }
    
    func showAnimationLabel(text: String) {
        let animationDuration: Double = 0.5
        rateLabel.text = text
        UIView.animateWithDuration(animationDuration, animations: {() -> Void in
            self.rateLabel.alpha = 1.0
            }, completion: {(Bool) -> Void in
                UIView.animateWithDuration(animationDuration, animations: {() -> Void in
                    self.rateLabel.alpha = 0.0
                    }, completion: {(Bool) -> Void in
                })
        })
    }
    
    func dispatch_async_main(block: () -> ()) {
        dispatch_async(dispatch_get_main_queue(), block)
    }
    
    func dispatch_async_global(block: () -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
    }
}
