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

/*
Improvements that could be made:

Have downloads pausable when the representing cell goes off screen
*/

private class JSONPhotoDownload {
    let downloadURL: NSURL
    let cacheURL: NSURL
    let completion: () -> Void
    
    init (fromURL: NSURL, toURL: NSURL, completion: () -> Void) {
        downloadURL = fromURL
        cacheURL = toURL
        self.completion = completion
    }
    
    func download (onCompletion: () -> Void) {
        let download = NSURLSession.sharedSession().dataTaskWithURL (downloadURL) {
            data, response, error
            in
            
            defer {
                onCompletion ()
            }
            
            guard let data = data else {
                return
            }
            
            data.writeToURL (self.cacheURL, atomically: true)
            self.completion ()
        }
        download.resume ()
    }
}

class JSONPhotoDownloadQueue {
    static let sharedQueue = JSONPhotoDownloadQueue ()
    
    private let downloadQueue = dispatch_queue_create ("photo-download-queue", DISPATCH_QUEUE_SERIAL)
    private var downloads = [String:JSONPhotoDownload]()
    private var currentDownload: JSONPhotoDownload?
    
    func addDownload (url: NSURL, toURL: NSURL, completion: () -> Void) {
        dispatch_async (downloadQueue) {
            
            // Only add the download once
            guard self.downloads[url.absoluteString] == nil else {
                return
            }
            
            self.downloads[url.absoluteString] = JSONPhotoDownload (
                fromURL: url,
                toURL: toURL,
                completion: completion
            )
            
            self.startDownload ()
        }
    }
    
    private func startDownload () {
        guard currentDownload == nil else {
            return
        }
        
        currentDownload = downloads.first?.1
        currentDownload?.download {
            [weak self] in
            
            self?.completeDownload ()
        }
    }
    private func completeDownload () {
        guard let download = currentDownload else {
            return
        }
        
        dispatch_async (downloadQueue) {
            self.downloads[download.downloadURL.absoluteString] = nil
            self.currentDownload = nil
            
            self.startDownload ()
        }
    }
}