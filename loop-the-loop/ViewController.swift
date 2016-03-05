//
//  ViewController.swift
//  loop-the-loop
//
//  Created by kenta.imai on 2016/03/05.
//  Copyright © 2016年 henteko. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {

    @IBOutlet var captureView: UIView!
    var videoLayer: AVCaptureVideoPreviewLayer!
    let fileOutput = AVCaptureMovieFileOutput()
    let AlbumTitle = "LoopTheLoop"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let captureSession = AVCaptureSession()
        let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let videoInput: AVCaptureInput!
        do {
            videoInput = try AVCaptureDeviceInput.init(device: videoDevice)
        }catch {
            videoInput = nil
        }
        captureSession.addInput(videoInput)
        captureSession.addOutput(self.fileOutput)
        
        // Preview
        self.videoLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
        self.videoLayer.frame = self.captureView.bounds
        self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.captureView.layer.addSublayer(videoLayer)
        
        captureSession.startRunning()
    }
    
    func startRecording() {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String? = "\(documentsDirectory)/temp.mp4"
        let fileURL : NSURL = NSURL(fileURLWithPath: filePath!)
        self.fileOutput.startRecordingToOutputFileURL(fileURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        self.fileOutput.stopRecording()
    }
    
    @IBAction func longPressCaptureView(sender: UILongPressGestureRecognizer!) {
        switch sender.state {
        case .Began:
            // LongPress開始
            startRecording()
            break
        case .Cancelled:
            break
        case .Ended:
            // LongPress終了
            stopRecording()
            break
        case .Failed:
            break
        default:
            // LongPress中
            break
        }
    }
    
    func createAlbum(outputFileURL: NSURL!) {
        let options: PHFetchOptions = PHFetchOptions()
        options.predicate = NSPredicate.init(format: "localizedTitle == %@", AlbumTitle)
        let albums = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.Any, options: options)
        
        if (albums.count > 0) {
            // albumがすでに存在してる
            self.saveMovie(outputFileURL, album: albums[0] as! PHAssetCollection)
        }else {
            // albumがないので作成する
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(self.AlbumTitle)
            }, completionHandler: { (success, error) -> Void in
                if (!success) {
                    print("Error creating AssetCollection")
                } else {
                    let albums = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.Any, options: options)
                    self.saveMovie(outputFileURL, album: albums[0] as! PHAssetCollection)
                }
            })
        }
    }
    
    func saveMovie(outputFileURL: NSURL!, album: PHAssetCollection) {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
            let result = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(outputFileURL)
            let assetPlaceholder = result!.placeholderForCreatedAsset
            let albumChangeRequset = PHAssetCollectionChangeRequest(forAssetCollection: album)
            albumChangeRequset!.addAssets([assetPlaceholder!])
        }, completionHandler: { (success, error) -> Void in
                if (!success) {
                    print("Error save movie")
                } else {
                    print("Saved movie!")
                }
        })
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL originalFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        let reverseVideo = ReverseVideo.init(originalVideoFileURL: originalFileURL)
        reverseVideo.convert { (reverseVideoFileURL) -> Void in
            let videoURLs = [originalFileURL, reverseVideoFileURL]
            
            let multiVideoLink = MultiVideoLink.init(videoURLs: videoURLs)
            multiVideoLink.link({ (linkVideoFileURL) -> Void in
                self.createAlbum(linkVideoFileURL)
            })
        }
    }
}

