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
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        let movieFileName = "\(randomStringWithLength(20))_temp.mp4"
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String? = "\(documentsDirectory)/\(movieFileName)_temp.mp4"
        let finishOutputURL : NSURL = NSURL(fileURLWithPath: filePath!)
        
        // 動画からsamplesへ画像の変換
        let asset: AVAsset = AVAsset(URL: outputFileURL)
        var reader: AVAssetReader!
        do {
            reader = try AVAssetReader.init(asset: asset)
        } catch {
            reader = nil
        }
        let videoTrack: AVAssetTrack = asset.tracksWithMediaType(AVMediaTypeVideo).last!
        let readerOutputSettings: [String : AnyObject] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        let readerOutput: AVAssetReaderTrackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        reader.addOutput(readerOutput)
        reader.startReading()
        
        var samples: [CMSampleBufferRef] = [CMSampleBufferRef]()
        while let sample = readerOutput.copyNextSampleBuffer() {
            samples.append((sample as CMSampleBufferRef))
        }
        
        print(samples.count)
        
        // 書き込みの準備
        var writer: AVAssetWriter!
        do {
            writer = try AVAssetWriter(URL: finishOutputURL, fileType: AVFileTypeMPEG4)
        } catch {
            writer = nil
        }
        let videoCompressionProps: [NSObject : AnyObject] = [
            AVVideoAverageBitRateKey : videoTrack.estimatedDataRate
        ]
        
        let writerOutputSettings: [String : AnyObject] = [
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoWidthKey : Int(videoTrack.naturalSize.width),
            AVVideoHeightKey : Int(videoTrack.naturalSize.height),
            AVVideoCompressionPropertiesKey : videoCompressionProps
        ]
        
        let writerInput: AVAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: writerOutputSettings, sourceFormatHint: (videoTrack.formatDescriptions.last as! CMFormatDescriptionRef))
        writerInput.expectsMediaDataInRealTime = false
        
        // なんか書き込みのやつ?
        let pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        writer.addInput(writerInput)
        writer.startWriting()
        writer.startSessionAtSourceTime(CMSampleBufferGetPresentationTimeStamp((samples[0])))
        
        // いろいろ頑張る
        for var i = 0; i < samples.count; i++ {
            let presentationTime: CMTime = CMSampleBufferGetPresentationTimeStamp((samples[i]))
            let imageBufferRef: CVPixelBufferRef = CMSampleBufferGetImageBuffer((samples[samples.count - i - 1]))!
            while !writerInput.readyForMoreMediaData {
                NSThread.sleepForTimeInterval(0.1)
            }
            pixelBufferAdaptor.appendPixelBuffer(imageBufferRef, withPresentationTime: presentationTime)
        }
        writer.finishWritingWithCompletionHandler { () -> Void in
            // 書き込み終了
            self.createAlbum(finishOutputURL)
        }
    }
    
    //ランダム文字列生成
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
}

