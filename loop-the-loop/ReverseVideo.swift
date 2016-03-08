//
//  ReverseVideo.swift
//  loop-the-loop
//
//  Created by kenta.imai on 2016/03/05.
//  Copyright © 2016年 henteko. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class ReverseVideo:NSObject {
    
    let originalVideoFileURL: NSURL!
    init(originalVideoFileURL: NSURL) {
        self.originalVideoFileURL = originalVideoFileURL
    }
    
    func convert(completion: (reverseVideoFileURL: NSURL)->Void) {
        let movieFileName = "\(FileNameUtil.randomStringWithLength(20))_reverse.mp4"
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String? = "\(documentsDirectory)/\(movieFileName)"
        let reverseFileURL : NSURL = NSURL(fileURLWithPath: filePath!)
        
        // 動画からsamplesへ画像の変換
        let asset: AVAsset = AVAsset(URL: self.originalVideoFileURL)
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

        // 書き込みの準備
        var writer: AVAssetWriter!
        do {
            writer = try AVAssetWriter(URL: reverseFileURL, fileType: AVFileTypeMPEG4)
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
        
        // 逆再生を縦表示にするライフハック
        writerInput.transform = videoTrack.preferredTransform
        
        // なんか書き込みのやつ?
        let pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        writer.addInput(writerInput)
        writer.startWriting()
        writer.startSessionAtSourceTime(CMSampleBufferGetPresentationTimeStamp((samples[0])))
        
        // いろいろ頑張る
        for var i = 0; i < samples.count; i++ {
            let presentationTime: CMTime = CMSampleBufferGetPresentationTimeStamp((samples[i]))
            let imageBufferRef: CVPixelBufferRef = CMSampleBufferGetImageBuffer((samples[samples.count - i - 1]))! // ここで逆に再生している
            while !writerInput.readyForMoreMediaData {
                NSThread.sleepForTimeInterval(0.1)
            }
            pixelBufferAdaptor.appendPixelBuffer(imageBufferRef, withPresentationTime: presentationTime)
        }
        writer.finishWritingWithCompletionHandler { () -> Void in
            // 書き込み終了
            completion(reverseVideoFileURL: reverseFileURL)
        }
    }
}