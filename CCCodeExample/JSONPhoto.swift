/*
The MIT License (MIT)

Copyright (c) 2015 CawBox

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import Foundation
import UIKit

enum JSONPhotoCacheResult {
    case Photo (UIImage, Int)
    case Error
}

struct JSONPhoto {
    let id: Int
    let album: Int
    
    let title: String
    let sourceURL: NSURL?
    let thumbnailURL: NSURL?
    
    init (id: Int, album: Int, title: String, sourceURL: String, thumbnailURL: String) {
        self.id = id
        self.album = album
        self.title = title
        self.sourceURL = NSURL (string: sourceURL)
        self.thumbnailURL = NSURL (string: thumbnailURL)
    }
}

typealias JSONPhotoBlock = (JSONPhotoCacheResult) -> Void

extension JSONPhoto {
    func cachePhoto (result: JSONPhotoBlock) {
        if hasLocalCache {
            loadCacheFromLocal (result)
        } else {
            loadCacheFromRemote (result)
        }
    }
    
    private func loadCacheFromLocal (result: JSONPhotoBlock) {
        guard hasLocalCache else {
            result (.Error)
            return
        }
        
        guard let cache = localCacheURL,
            let data = NSData (contentsOfURL: cache),
            let image = UIImage (data: data) else {
                result (.Error)
                return
        }
        
        result (.Photo (image, id))
    }
    private func loadCacheFromRemote (result: JSONPhotoBlock) {
        guard let toURL = localCacheURL,
            url = sourceURL else {
                result (.Error)
                return
        }
        
        JSONPhotoDownloadQueue.sharedQueue.addDownload (url, toURL: toURL) {
            self.loadCacheFromLocal (result)
        }
    }
    
    var hasLocalCache: Bool {
        guard let cacheURL = localCacheURL else {
            return false
        }
        
        guard let values = try? cacheURL.resourceValuesForKeys ([NSURLNameKey]) else {
            return false
        }
        
        return values[NSURLNameKey] != nil
    }
    var localCacheURL: NSURL? {
        guard let cacheURL = NSFileManager.defaultManager().URLsForDirectory (
            .CachesDirectory,
            inDomains: .UserDomainMask
            ).first else {
                return nil
        }
        
        return cacheURL.URLByAppendingPathComponent ("\(hashValue).cache")
    }
}

extension JSONPhoto: Hashable {
    var hashValue: Int {
        return "\(id)-\(album)".hashValue
    }
}

func ==(lhs: JSONPhoto, rhs: JSONPhoto) -> Bool {
    return lhs.id == rhs.id
}