//
//  GalleryBrowsePhotoViewController.swift
//  AsyncPhotoBrowser
//
//  Created by Sihao Lu on 12/5/14.
//  Copyright (c) 2014 DJ.Ben. All rights reserved.
//

import UIKit
import Cartography
import Alamofire
import RealmSwift
import SwiftyJSON

@objc protocol GalleryBrowserDataSource {
    func imageEntityForPage(page: Int, inGalleyBrowser galleryBrowser: GalleryBrowsePhotoViewController) -> FNImage?
    func numberOfImagesForGalleryBrowser(browser: GalleryBrowsePhotoViewController) -> Int
}

public class GalleryBrowsePhotoViewController: UIViewController, UIScrollViewDelegate {
    
    var dataSource: GalleryBrowserDataSource?
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: self.view.bounds)
        //scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.indicatorStyle = .White
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = false
        scrollView.alwaysBounceVertical = false
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.whiteColor()
        return scrollView
    }()
    
    
 /*このcurrentPageを正しく操作してGarallyViewControllerと同様にすればGalleryBrowsePageViewのページをリロードで無限に読めるようになるはず。*/
    var currentPage: Int {
        let pageHeight = scrollView.frame.size.height
        let page = Int(floor((scrollView.contentOffset.y * 2.0 + pageHeight) / (pageHeight * 2.0)))
        //let pageWidth = scrollView.frame.size.width
        //let page = Int(floor((scrollView.contentOffset.x * 2.0 + pageWidth) / (pageWidth * 2.0)))
        return page
    }
    
    var currentImageEntity: FNImage? {
        return dataSource?.imageEntityForPage(currentPage, inGalleyBrowser: self)
    }
    
    private var layedOutScrollView = false
    
    var startPage: Int = 0
    private var imageCount: Int = 0
    private var pageViews = [GalleryBrowserPageView?]()
    
    init(startPage: Int) {
        self.startPage = startPage
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        commonSetup()
        
        
        //https://api.instagram.com/v1/tags/a/media/recent
        //"scope":"public_content"
        //https://api.instagram.com/v1/self/media/recent
        //1801390729、786016361
        //["access_token":"1801390729.fd90046.0d81b56e3e984fc9b59448111943fd12","count":5]
        
        /*let parameters :Dictionary = [
        "access_token"         : "2307093343.46334ac.4f6800a20edb463e8b6f1af1baad3591",
        "count"        : "5"
        ]
        Alamofire.request(.GET,"https://api.instagram.com/v1/users/1801390729/media/recent", parameters:parameters).responseJSON { response in
        //print(response.request)  // original URL request
        print(response.response) // URL response
        print(response.data)     // server data
        print(response.result)   // result of response serialization
        
        if let JSON = response.result.value {
        print("JSON: \(JSON)")
        }
        }*/
        
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !layedOutScrollView {
            // Size scroll view contents
            if dataSource == nil {
                fatalError("Unable to load browser: data source is nil.")
            }
            
            imageCount = dataSource!.numberOfImagesForGalleryBrowser(self)
            navigationItem.title = "\(startPage + 1) / \(imageCount)"
            
            for _ in 0..<imageCount {
                pageViews.append(nil)
            }
            scrollView.contentSize = CGSize(width: scrollView.bounds.width, height: CGFloat(imageCount) * scrollView.bounds.height)
            //(width: CGFloat(imageCount) * scrollView.bounds.width, height: scrollView.bounds.height)
            layedOutScrollView = true
            
            // Modify start page
            scrollView.contentOffset = CGPoint(x: 0, y: CGFloat(startPage) * scrollView.bounds.height)  //(x: CGFloat(startPage) * scrollView.bounds.width, y: 0)
            loadVisiblePages()
        }
    }
    
    private func commonSetup() {
        automaticallyAdjustsScrollViewInsets = false
        navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationController!.navigationBar.shadowImage = UIImage()
        navigationController!.navigationBar.translucent = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "doneButtonTapped:")
        let attributeDict = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationController!.navigationBar.titleTextAttributes = attributeDict
        view.addSubview(scrollView)
        constrain(scrollView) { v in
            v.left == v.superview!.left
            v.right == v.superview!.right
            v.top == v.superview!.top
            v.bottom == v.superview!.bottom
        }
        
    }
    
    func doneButtonTapped(sender: UIBarButtonItem) {
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // This solution comes from "How To Use UIScrollView to Scroll and Zoom Content in Swift" written by Michael Briscoe on RayWenderlich
    func loadPage(page: Int) {
        if page < 0 || page >= imageCount {
            // If it's outside the range of what you have to display, then do nothing
            return
        }
        
        if pageViews[page] != nil {
            // Do nothing. The view is already loaded.
            print("ろおどど\(page)")
        } else {
            print("ろおどぉ\(page)")
            var frame = scrollView.bounds
            frame.origin.x = 0.0 //frame.size.width * CGFloat(page)
            frame.origin.y = frame.size.height * CGFloat(page)   //0.0
            
            // Loading source image if not exists
            let imageEntity = dataSource!.imageEntityForPage(page, inGalleyBrowser: self)!
            imageEntity.page = page
            if imageEntity.sourceImageState == .NotLoaded {
                imageEntity.loadSourceImageWithCompletion({ (error) -> Void in
                    if let pageView = self.pageViews[imageEntity.page!] {
                        if error == nil {
                            print("ロード完了 \(page)")
                            pageView.image = imageEntity.sourceImage
                        } else {
                            print("ロード失敗 \(page), error \(error)")
                        }
                    }
                })
            } else if imageEntity.sourceImageState == .Paused {
                
                imageEntity.resumeLoadingSource()
                print("ロード完了2 \(page)")
            }
            
            let newPageView = GalleryBrowserPageView(frame: frame)
            newPageView.imageEntity = imageEntity
            newPageView.image = imageEntity.sourceImage ?? imageEntity.thumbnail
            
            let pagee = String(page)

            let realmManager = RealmManager()
            let realmHasData = realmManager.checkIfRealmHasData(pagee)
            
            if(realmHasData==false){  //初めての場合

                //コメントといいね数をAlamoで取得
                let photoId = realmManager.getPhotoId()
            
                let apiRequestInPods = ApiRequestInPods(photoId: photoId as String)
                
                let photoCommentsList = apiRequestInPods.getPhotoCommentsList()
                
                let photoFavoritesNum = apiRequestInPods.getPhotoFavoritesNum()
                
                //投稿者自身の画像を非同期で取得
                let photoOwnerUrl = realmManager.getPhotoOwnerUrl()
                let url = NSURL(string:"\(photoOwnerUrl)")
                let req = NSURLRequest(URL:url!)
                NSURLConnection.sendAsynchronousRequest(req, queue:NSOperationQueue.mainQueue()){(res, data, err) in
                    
                    //以下、viewに表示
                    let photoOwnerImage = UIImage(data:data!)
                    newPageView.profimg = photoOwnerImage
                   
                    let imgdata:NSData = UIImagePNGRepresentation(photoOwnerImage!)!
                    
                    let photoOwnerName = realmManager.getPhotoOwnerName()
                    newPageView.profname = photoOwnerName as String
                    
                    newPageView.likestring =  "いいね数:" + photoFavoritesNum.stringValue
                    
                    self.showComments(photoCommentsList.names,commenterMessageArray: photoCommentsList.messages,newPageView: newPageView)
                    
                    //以下、DBに保存
                    realmManager.savePhotoCommentsAndOwnerImg(photoCommentsList.names, messages: photoCommentsList.messages, imgdata: imgdata, pagee: pagee)
            
                    realmManager.savePhotoFavoritesNum(pagee,favorites: photoFavoritesNum.intValue)
                }
                
            }else{  //2回目以降はRealmから表示
                
                newPageView.profimg = realmManager.getPhotoOwnerImage()
                
                let photoOwnerName = realmManager.getPhotoOwnerName()
                newPageView.profname = photoOwnerName as String
            
                newPageView.likestring =  "いいね数:" + String(realmManager.getPhotoFavoritesNum())
                
                let commenterNameArray = realmManager.getPhotoCommenterName()
                let commenterMessageArray = realmManager.getPhotoCommenterMessage()
                
                self.showComments(commenterNameArray,commenterMessageArray: commenterMessageArray,newPageView: newPageView)
            }
            
            imageEntity.delegate = newPageView
            newPageView.setActivityAccordingToImageState(imageEntity.sourceImageState)
            //imageEntity2.delegate = newPageView
            //newPageView.setActivityAccordingToImageState(imageEntity2.sourceImageState)
            scrollView.addSubview(newPageView)
            pageViews[page] = newPageView
        }
    }
    
    func showComments(commenterNameArray:NSMutableArray,commenterMessageArray:NSMutableArray,newPageView:GalleryBrowserPageView){
        
        if(commenterNameArray.count==1){
            
            var comment1:String = (commenterNameArray[0] as! String) + " : " + (commenterMessageArray[0] as! String)
            newPageView.comment1 = comment1
            
        }else if(commenterNameArray.count==2){
            
            var comment1:String = (commenterNameArray[0] as! String) + " : " + (commenterMessageArray[0] as! String)
            newPageView.comment1 = comment1
            
            var comment2:String = (commenterNameArray[1] as! String) + " : " + (commenterMessageArray[1] as! String)
            newPageView.comment2 = comment2
        }else if(commenterNameArray.count==3){
            
            var comment1:String = (commenterNameArray[0] as! String) + " : " + (commenterMessageArray[0] as! String)
            newPageView.comment1 = comment1
            
            var comment2:String = (commenterNameArray[1] as! String) + " : " + (commenterMessageArray[1] as! String)
            newPageView.comment2 = comment2
            
            var comment3:String = (commenterNameArray[2] as! String) + " : " + (commenterMessageArray[2] as! String)
            newPageView.comment3 = comment3
        }
    }
    
    func purgePage(page: Int) {
        
        if page < 0 || page >= imageCount {
            // If it's outside the range of what you have to display, then do nothing
            return
        }
        
        // Remove a page from the scroll view and reset the container array
        if let pageView = pageViews[page] {
            
            let pageView = pageViews[page]  //[page]
            
            pageView!.removeFromSuperview()
            pageViews[page] = nil
            
            // Suspend any loading request
            let imageEntity = dataSource!.imageEntityForPage(page, inGalleyBrowser: self)
            imageEntity?.pauseLoadingSource()
            
            //print("completeee \(page)")
            //}
        }
    }
   
    func loadVisiblePages() {
        // Work out which pages you want to load
        let firstPage = currentPage - 1
        let lastPage = currentPage + 1
        
        print("コンプ")
        
        // Purge anything before the first page
        for var index = 0; index < firstPage; ++index {
            purgePage(index)
        }
        
        // Load pages in our range(前中後3ページ)
        for var index = firstPage; index <= lastPage; ++index {
            loadPage(index)
        }
        
        // Purge anything after the last page
        for var index = lastPage+1; index < imageCount; ++index {
            purgePage(index)
        }
    }
    
    // MARK: Scroll View Delegate
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        //scrollView.directionalLockEnabled = true;
        loadVisiblePages()
        
        navigationItem.title = "\(currentPage + 1) / \(imageCount)"
        if scrollView.contentOffset.x>0 {
            scrollView.contentOffset.x = 0
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        //resetPageZooming(currentPage - 1)
        //resetPageZooming(currentPage + 1)
    }
    
}
