//
//  ActionViewController.swift
//  OIBAction
//
//  Created by tarunon on 2014/09/15.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//

import UIKit
import MobileCoreServices
import Foundation
import CoreData

class ActionViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, NSFetchedResultsControllerDelegate, UIWebViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var manualView: UIScrollView!
    @IBOutlet weak var switchView: UIView!
    @IBOutlet weak var iconView: UIImageView!
    var webView: UIWebView!
    
    var modelManager: BrowserModelManager!
    var fetchedResultsController = NSFetchedResultsController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationStyle = UIModalPresentationStyle.Custom
        if BrowserPreferences.sharedPreferences().disableManual0 {
            manualView.hidden = true
            self.preferredContentSize = CGSizeMake(320, 420)
        } else {
            switchView.hidden = true
        }
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone) {
            collectionView.contentInset = UIEdgeInsetsMake(manualView.frame.size.height + manualView.frame.origin.y, 0, 0, 0)
        }

        // Get the item[s] we're handling from the extension context.
        cancelButton.layer.cornerRadius = 5
        cancelButton.clipsToBounds = true
        cancelButton.hidden = true
        collectionView.hidden = true
        
        modelManager = BrowserModelManager.sharedInstance
        NSNotificationCenter.defaultCenter().addObserverForName(BrowserModelContextDidChangedNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            self.contextDidLoad()
        }
        webView = UIWebView()
        webView.delegate = self
        
        iconView.layer.cornerRadius = 10
        iconView.clipsToBounds = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let context = modelManager.context {
            self.contextDidLoad()
        }
    }
    
    func contextDidLoad() {
        self.fetchedResultsController = self.modelManager.fetchedResultsControllerEnabled()
        self.fetchedResultsController.delegate = self
        self.fetchedResultsController.performFetch(nil)
        self.collectionView.reloadData()
        
        
        //        審査対策用のコード
        if self.fetchedResultsController.sections?.first?.numberOfObjects == 1 {
            if let browser = self.modelManager.selectedBrowser() {
                self.modelManager.getIcon(browser, block: { (image) -> Void in
                    self.iconView.image = image
                })
                self.loadBrowser(browser)
            }
        } else {
            cancelButton.hidden = false
            collectionView.hidden = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cancel() {
        self.extensionContext!.completeRequestReturningItems(nil, completionHandler:nil)
    }
    
    func loadBrowser(browser: BrowserEntity) {
        for item in self.extensionContext!.inputItems as [NSExtensionItem] {
            for provider in item.attachments as [NSItemProvider] {
                if provider.hasItemConformingToTypeIdentifier(String(kUTTypeURL)) {
                    provider.loadItemForTypeIdentifier(String(kUTTypeURL), options: nil, completionHandler: { (result: NSSecureCoding!, error: NSError!) -> Void in
                        if let url = result as? NSURL {
                            let components: NSURLComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)!
                            if components.scheme == "http" {
                                components.scheme = browser.schemeHTTP
                            } else if components.scheme == "https" {
                                components.scheme = browser.schemeHTTPS
                            }
                            self.webView?.loadRequest(NSURLRequest(URL: components.URL!))
                        }
                    })
                }
            }
        }
    }
    
//    collectionview delegate
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if let count = fetchedResultsController.sections?.count {
            return count
        } else {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = fetchedResultsController.sections?[section].numberOfObjects {
            return count
        } else {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BrowserCollectionViewCell", forIndexPath: indexPath) as BrowserCollectionViewCell
        cell.browser = fetchedResultsController.objectAtIndexPath(indexPath) as BrowserEntity
        return cell
    }
    
    /**
    セルをタップした時の挙動。
    中のfor文はExtensionを掘るときの定型文
    webViewにURLスキームを書き換えたリクエストを飛ばす。
    
    :param: collectionView
    :param: indexPath
    */
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as BrowserCollectionViewCell
        cell.hilight = true
        let browser = self.fetchedResultsController.objectAtIndexPath(indexPath) as BrowserEntity
        self.view.userInteractionEnabled = false
        loadBrowser(browser)
    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as BrowserCollectionViewCell
        cell.hilight = true
    }
    
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as BrowserCollectionViewCell
        cell.hilight = false
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(16, 16, 16, 16)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10.0
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.reloadData()
    }
    
    /**
    セルで呼び出したリクエストを受け取る。
    このタイミングでExtentionの完了を通知すると、アプリ遷移と同時にActionViewControllerが閉じる。
    
    :param: webView
    :param: request
    :param: navigationType
    
    :returns: 
    */
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        self.extensionContext!.completeRequestReturningItems([], completionHandler: { (completion: Bool) -> Void in
            self.view.userInteractionEnabled = true
            BrowserPreferences.sharedPreferences().disableManual1 = true
            BrowserPreferences.sharedPreferences().synchronize()
        })
        return true
    }
}
