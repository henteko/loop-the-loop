//
//  VideoCapture.swift
//  loop-the-loop
//
//  Created by kenta.imai on 2016/03/05.
//  Copyright © 2016年 henteko. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary

class VideoCapture:NSObject, AVCaptureFileOutputRecordingDelegate {
    
    let fileOutput = AVCaptureMovieFileOutput()
    let captureSession = AVCaptureSession()
    let completion: (linkVideoFileURL: NSURL)->Void
    
    init(completion: (linkVideoFileURL: NSURL)->Void) {
        self.completion = completion
        let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let videoInput: AVCaptureInput!
        do {
            videoInput = try AVCaptureDeviceInput.init(device: videoDevice)
        }catch {
            videoInput = nil
        }
        captureSession.addInput(videoInput)
        captureSession.addOutput(self.fileOutput)
    }
    
    func start() {
        captureSession.startRunning()
    }
    
    func startRecording() {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0] as String
        let movieFileName = "\(FileNameUtil.randomStringWithLength(20))_temp.mp4"
        let filePath : String? = "\(documentsDirectory)/\(movieFileName)"
        let fileURL : NSURL = NSURL(fileURLWithPath: filePath!)
        self.fileOutput.startRecordingToOutputFileURL(fileURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        self.fileOutput.stopRecording()
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL originalFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        let reverseVideo = ReverseVideo.init(originalVideoFileURL: originalFileURL)
        reverseVideo.convert { (reverseVideoFileURL) -> Void in
            let videoURLs = [originalFileURL, reverseVideoFileURL]
            
            let multiVideoLink = MultiVideoLink.init(videoURLs: videoURLs)
            multiVideoLink.link({ (linkVideoFileURL) -> Void in
                self.completion(linkVideoFileURL: linkVideoFileURL)
            })
        }
    }
}