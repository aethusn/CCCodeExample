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

import UIKit

/*
Improvements that could be made:

Pre-generate drop shadow
Store a queue of off screen cells as to not need to re-create new ones
*/

class PhotosViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView?
    
    var photosNotification: AnyObject?
    var photos: JSONFetch?
    var arrangedPhotos = [JSONPhoto]()
    
    deinit {
        if let notification = photosNotification {
            NSNotificationCenter.defaultCenter().removeObserver (notification)
        }
    }
}

extension PhotosViewController {
    override func viewWillAppear (animated: Bool) {
        photosNotification = NSNotificationCenter.defaultCenter().addObserverForName (JSONFetch.PhotosDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) {
            [weak self]
            notification in
            
            dispatch_async(dispatch_get_main_queue()) {
                self?.arrangedPhotos.appendContentsOf (self?.photos?.allPhotos ?? [])
                self?.collectionView?.reloadData ()
            }
        }
        
        photos = JSONFetch ()
    }
    
    @IBAction func reArrangePhotos (sender: AnyObject) {
        arrangedPhotos = recursiveReorder (arrangedPhotos)
        collectionView?.reloadData ()
    }
}

extension PhotosViewController: UICollectionViewDataSource {
    func collectionView (
        collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
            return arrangedPhotos.count
    }
    
    func collectionView (
        collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier ("photoCell", forIndexPath: indexPath) as! ShadowCollectionViewCell
            
            let photo = arrangedPhotos[indexPath.row]
            cell.titleLabel?.text = photo.title
            
            let photoNeedsUpdate = cell.photoID != photo.id
            cell.photoID = photo.id
            
            if photoNeedsUpdate {
                if !photo.hasLocalCache {
                    cell.imageView?.image = nil
                }
                
                photo.cachePhoto {
                    result in
                    
                    dispatch_async (dispatch_get_main_queue()) {
                        if case .Photo (let cachedPhoto, let cacheID) = result {
                            
                            // Don't show the image if this cell doesn't match the ID anymore
                            guard cell.photoID == cacheID else {
                                return
                            }
                            
                            cell.imageView?.image = cachedPhoto
                        }
                    }
                }
            }
            
            return cell
    }
}

