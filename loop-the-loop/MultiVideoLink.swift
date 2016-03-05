//
//  MultiVideoLink.swift
//  loop-the-loop
//
//  Created by kenta.imai on 2016/03/05.
//  Copyright © 2016年 henteko. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

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
        
        let mixComposition = AVMutableComposition()
        let firstAsset = AVAsset.init(URL: self.videoURLs[0])
        let secondAsset = AVAsset.init(URL: self.videoURLs[1])
        
        let firstTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
            preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
            try firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAsset.duration),
                ofTrack: firstAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                atTime: kCMTimeZero)
        } catch {
            
        }
        
        let secondTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
            preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
            try secondTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, secondAsset.duration),
                ofTrack: secondAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                atTime: firstAsset.duration)
        } catch {
            
        }
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration))
        
        let firstInstruction = videoCompositionInstructionForTrack(firstTrack, asset: firstAsset)
        firstInstruction.setOpacity(0.0, atTime: firstAsset.duration)
        let secondInstruction = videoCompositionInstructionForTrack(secondTrack, asset: secondAsset)
        
        mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(1, 30)
        mainComposition.renderSize = CGSize(width: UIScreen.mainScreen().bounds.width,
            height: UIScreen.mainScreen().bounds.height)
        
        let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter!.outputURL = finishFileURL
        exporter!.outputFileType = AVFileTypeQuickTimeMovie
        exporter!.shouldOptimizeForNetworkUse = true
        exporter!.videoComposition = mainComposition
        
        exporter!.exportAsynchronouslyWithCompletionHandler({ () -> Void in
            completion(linkVideoFileURL: finishFileURL)
        })
    }
    
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        var assetOrientation = UIImageOrientation.Up
        var isPortrait = false
        print(transform.a)
        print(transform.b)
        print(transform.c)
        print(transform.d)
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .Right
            isPortrait = true
            print("right")
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .Left
            isPortrait = true
            print("left")
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .Up
            print("up")
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .Down
            print("down")
        }
        return (assetOrientation, isPortrait)
    }
    
    func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0] 
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform)
        var scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.width
        
        if assetInfo.isPortrait {
            scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
            instruction.setTransform(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor),
                atTime: kCMTimeZero)
        } else {
            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
            var concat = CGAffineTransformConcat(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor), CGAffineTransformMakeTranslation(0, UIScreen.mainScreen().bounds.width / 2))
            if assetInfo.orientation == .Down {
                let fixUpsideDown = CGAffineTransformMakeRotation(CGFloat(M_PI))
                let windowBounds = UIScreen.mainScreen().bounds
                let yFix = assetTrack.naturalSize.height + windowBounds.height
                let centerFix = CGAffineTransformMakeTranslation(assetTrack.naturalSize.width, yFix)
                concat = CGAffineTransformConcat(CGAffineTransformConcat(fixUpsideDown, centerFix), scaleFactor)
            }
            instruction.setTransform(concat, atTime: kCMTimeZero)
        }
        
        return instruction
    }
}