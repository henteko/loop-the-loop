//
//  VideoLocalSave.swift
//  loop-the-loop
//
//  Created by kenta.imai on 2016/03/05.
//  Copyright © 2016年 henteko. All rights reserved.
//

import Foundation
import Photos

class VideoLocalSave {
    
    let albumName: String!
    init(albumName: String) {
        self.albumName = albumName
    }
    
    func save(outputFileURL: NSURL!, completion: (success: Bool, error: NSError?)->Void) {
        let options: PHFetchOptions = PHFetchOptions()
        options.predicate = NSPredicate.init(format: "localizedTitle == %@", self.albumName)
        let albums = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.Any, options: options)
        
        if (albums.count > 0) {
            // albumがすでに存在してる
            self.saveMovie(outputFileURL, album: albums[0] as! PHAssetCollection, completion: { (success, error) -> Void in
                completion(success: success, error: error)
            })
        }else {
            // albumがないので作成する
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(self.albumName)
                }, completionHandler: { (success, error) -> Void in
                    if (!success) {
                        print("Error creating AssetCollection")
                    } else {
                        let albums = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.Any, options: options)
                        self.saveMovie(outputFileURL, album: albums[0] as! PHAssetCollection, completion: { (success, error) -> Void in
                            completion(success: success, error: error)
                        })
                    }
            })
        }
    }
    
    func saveMovie(outputFileURL: NSURL!, album: PHAssetCollection, completion: (success: Bool, error: NSError?)->Void) {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
            let result = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(outputFileURL)
            let assetPlaceholder = result!.placeholderForCreatedAsset
            let albumChangeRequset = PHAssetCollectionChangeRequest(forAssetCollection: album)
            albumChangeRequset!.addAssets([assetPlaceholder!])
            }, completionHandler: { (success, error) -> Void in
                completion(success: success, error: error)
        })
    }
}