//
//  MultiVideoLink.swift
//  loop-the-loop
//
//  Created by kenta.imai on 2016/03/05.
//  Copyright © 2016年 henteko. All rights reserved.
//

import Foundation
import AVFoundation

class MultiVideoLink:NSObject {
    
    let videoURLs: [NSURL!]
    init(videoURLs: [NSURL!]) {
        self.videoURLs = videoURLs
    }
    
    func link(completion: (linkVideoFileURL: NSURL)->Void) {
        let movieFileName = "\(FileNameUtil.randomStringWithLength(20))_link.mp4"
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String? = "\(documentsDirectory)/\(movieFileName)"
        let finishFileURL : NSURL = NSURL(fileURLWithPath: filePath!)
        
        let composition = AVMutableComposition()
        let compositionVideoTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        var startTime = kCMTimeZero
        for videoURL: NSURL in self.videoURLs {
            let asset = AVAsset.init(URL: videoURL)
            let videoTrack = asset.tracksWithMediaType(AVMediaTypeVideo).last
            
            do {
                try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), ofTrack: videoTrack!, atTime: startTime)
            } catch {
            }
            startTime = CMTimeAdd(startTime, asset.duration)
        }
        let exporter = AVAssetExportSession.init(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputFileType = AVFileTypeQuickTimeMovie
        exporter?.outputURL = finishFileURL
        
        exporter?.exportAsynchronouslyWithCompletionHandler({ () -> Void in
            completion(linkVideoFileURL: finishFileURL)
        })
    }
}