//
//  FNImage.swift
//  AsyncPhotoBrowser
//
//  Created by Sihao Lu on 11/30/14.
//  Copyright (c) 2014 DJ.Ben. All rights reserved.
//

import UIKit
import FastImageCache
import Alamofire

let FNImageImageFormatFamily = "FICDPhotoImageFormatFamily"
let FNImageSquareImage32BitBGRAFormatName = "edu.jhu.djben.AsyncPhotoBrowser.FICDPhotoSquareImage32BitBGRAFormatName"

func ==(left: FNImage, right: FNImage) -> Bool {
    return left.URL == right.URL
}

protocol FNImageDelegate {
    func sourceImageStateChangedForImageEntity(imageEntity: FNImage, oldState: FNImage.FNImageSourceImageState, newState: FNImage.FNImageSourceImageState)
}

public class FNImage: NSObject, FICEntity {
    
    enum FNImageSourceImageState {
        case NotLoaded
        case Loading
        case Paused
        case Ready
        case Failed
    }
    
    private var _UUID: String!
    var URL: NSURL
    var indexPath: NSIndexPath?
    var page: Int?
    var sourceImage: UIImage?
    var thumbnail: UIImage?
    var thumbnail2: UIImage?
    var delegate: FNImageDelegate?
    
    private var reloadRequest: Request?
    
    override public var hashValue: Int {
        return self.URL.hashValue
    }
    
    public var UUID: String {
        get {
            if _UUID == nil {
                let UUIDBytes = FICUUIDBytesFromMD5HashOfString(self.URL.absoluteString)
                _UUID = FICStringWithUUIDBytes(UUIDBytes)
            }
            return _UUID
        }
    }
    
    public var sourceImageUUID: String {
        get {
            return self.UUID
        }
    }
    
    var isReady: Bool {
        return thumbnail != nil && indexPath != nil
    }
    
    var sourceImageState: FNImageSourceImageState = .NotLoaded {
        willSet {
            self.delegate?.sourceImageStateChangedForImageEntity(self, oldState: self.sourceImageState, newState: newValue)
        }
    }
    
    init(URL: NSURL, indexPath: NSIndexPath? = nil) {
        self.URL = URL
        self.indexPath = indexPath
        super.init()
    }
    
    public func sourceImageURLWithFormatName(formatName: String!) -> NSURL! {
        return URL
    }
    
    public func drawingBlockForImage(image: UIImage!, withFormatName formatName: String!) -> FICEntityImageDrawingBlock! {
        let drawingBlock: FICEntityImageDrawingBlock = { context, contextSize in
            let contextBounds = CGRect(origin: CGPointZero, size: contextSize)
            CGContextClearRect(context, contextBounds)
            if formatName != FNImageSquareImage32BitBGRAFormatName {
                // Fill with white for image formats that are opaque
                CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
                CGContextFillRect(context, contextBounds)
            }
            let squareImage = image.squareImage()
            
            UIGraphicsPushContext(context)
            squareImage.drawInRect(contextBounds)
            UIGraphicsPopContext()
        }
        return drawingBlock
    }
    
    func loadSourceImageWithCompletion(completion: ((error: NSError?) -> Void)?) {
        if reloadRequest != nil {
            resumeLoadingSource()
            return
        }
        sourceImageState = .Loading
        
        guard self.URL.scheme != "file" else {
            self.sourceImage = UIImage(contentsOfFile: URL.path!)
            self.sourceImageState = .Ready
            completion?(error: nil)
            return
        }
        
        reloadRequest = request(.GET, self.URL).response { (_, _, data, error) in
            self.reloadRequest = nil
            if error != nil {
                completion?(error: error! as NSError)
                self.sourceImageState = .Failed
                return
            }
            if let imageData = data {
                if let image = UIImage(data: imageData) {
                    self.sourceImage = image
                    self.sourceImageState = .Ready
                    completion?(error: nil)
                    return
                }
            }
            self.sourceImageState = .Failed
            completion?(error: NSError(domain: "FNImageErrorDomain", code: 0, userInfo: nil))
        }
    }
    
    func pauseLoadingSource() {
        if reloadRequest != nil {
            print("pause loading \(page)")
            reloadRequest!.suspend()
            sourceImageState = .Paused
        }
    }
    
    func resumeLoadingSource() {
        if reloadRequest != nil {
            print("resume loading \(page)")
            reloadRequest!.resume()
            sourceImageState = .Loading
        }
    }
}

extension UIImage {
    
    /** 
        Generate a square thumbnail of current image.
    
        See https://github.com/path/FastImageCache/blob/master/FastImageCacheDemo/Classes/FICDPhoto.m for the original version.
    
        - returns: a square version of the current image.
    */
    func squareImage() -> UIImage {
        var squareImage: UIImage!
        let imageSize = self.size
    
        if (imageSize.width == imageSize.height) {
            squareImage = self
        } else {
            // Compute square crop rect
            let smallerDimension: CGFloat = min(imageSize.width, imageSize.height)
            var cropRect = CGRectMake(0, 0, smallerDimension, smallerDimension)
    
            // Center the crop rect either vertically or horizontally, depending on which dimension is smaller
            if (imageSize.width <= imageSize.height) {
                cropRect.origin = CGPoint(x: 0, y: rint((imageSize.height - smallerDimension) / 2.0))
            } else {
                cropRect.origin = CGPoint(x: rint((imageSize.width - smallerDimension) / 2.0), y: 0)
            }
            let croppedImageRef: CGImageRef = CGImageCreateWithImageInRect(self.CGImage, cropRect)!
            squareImage = UIImage(CGImage:croppedImageRef)
        }
        return squareImage;
    }
}

extension UILabel {
   func squareImage() -> UILabel {
    var squareImage: UILabel!
    return squareImage
    }
}


