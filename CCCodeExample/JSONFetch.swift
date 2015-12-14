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

enum JSONFetchError: ErrorType {
    case NoError
    case InvalidData
    case InvalidFormatting
}

class JSONFetch {
    private let jsonURL = NSURL (string: "http://jsonplaceholder.typicode.com/photos")!
    
    static let PhotosDidChangeNotification = "com.cawbox.notification.photosdidchange"
    
    init () {
        loadJSONFromCache {
            error in
            
            print ("complete")
        }
    }
    
    private var photos = [JSONPhoto]() {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName (
                JSONFetch.PhotosDidChangeNotification,
                object: nil
            )
        }
    }
    var allPhotos: [JSONPhoto] {
        return photos
    }
}

extension JSONFetch {
    var cacheURL: NSURL? {
        guard let cacheURL = NSFileManager.defaultManager().URLsForDirectory (
            .CachesDirectory,
            inDomains: .UserDomainMask
            ).first else {
                return nil
        }
        
        return cacheURL.URLByAppendingPathComponent ("json.cache")
    }
    
    private func loadJSONFromCache (completion: (JSONFetchError) -> Void) {
        guard let cacheURL = cacheURL,
            let cachedData = NSData (contentsOfURL: cacheURL) else {
                loadJSONFromURL (completion)
            return
        }
        
        guard let jsonData = try? NSJSONSerialization.JSONObjectWithData (cachedData, options: []) else {
            completion (.InvalidData)
            return
        }
        
        guard let json = jsonData as? [[String: AnyObject]] else {
            completion (.InvalidFormatting)
            return
        }
        
        loadJSON (json, completion: completion)
    }
    private func loadJSONFromURL (completion: (JSONFetchError) -> Void) {
        let fetch = NSURLSession.sharedSession().dataTaskWithURL (jsonURL) {
            data, response, error in
            
            guard let data = data else {
                completion (.InvalidData)
                return
            }
            
            // Write the JSON to a cache, to be used on next launch
            if let cacheURL = self.cacheURL {
                data.writeToURL (cacheURL, atomically: true)
            }
            
            guard let jsonData = try? NSJSONSerialization.JSONObjectWithData (data, options: []) else {
                completion (.InvalidData)
                return
            }
            
            guard let json = jsonData as? [[String: AnyObject]] else {
                completion (.InvalidFormatting)
                return
            }
            
            self.loadJSON (json, completion: completion)
        }
        fetch.resume ()
    }
    
    private func loadJSON (json: [[String: AnyObject]], completion: (JSONFetchError) -> Void) {
        var fetchedPhotos = [JSONPhoto]()
        for photoJson in json {
            guard let albumId = photoJson["albumId"] as? Int,
                let id = photoJson["id"] as? Int,
                let title = photoJson["title"] as? String,
                let sourceURL = photoJson["url"] as? String,
                let thumbnailURL = photoJson["thumbnailUrl"] as? String else {
                    continue
            }
            
            fetchedPhotos.append (JSONPhoto (
                id: id,
                album: albumId,
                title: title,
                sourceURL: sourceURL,
                thumbnailURL: thumbnailURL
                )
            )
            
            if fetchedPhotos.count > 250 {
                break
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.photos = fetchedPhotos
            
            completion (.NoError)
        }
    }
}