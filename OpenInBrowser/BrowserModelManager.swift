//
//  BrowserModelManager.swift
//  OpenInBrowser
//
//  Created by tarunon on 2014/09/15.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//


import UIKit

let BrowserModelContextDidChangedNotification = "BrowserModelContextDidChangedNotification"
let BrowserServerAddress = "https://openinbrowser.appspot.com/browserlist"

class BrowserModelManager: NSObject, TNStoreManagerDelegate {
    var storeManager: TNStoreManager!
    var context: NSManagedObjectContext!
    var _faviconDirectoryURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.tarunon.openin")!.URLByAppendingPathComponent("Icon")
    class var sharedInstance: BrowserModelManager {
        struct Static {
            static let instance: BrowserModelManager = BrowserModelManager()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        NSFileManager.defaultManager().createDirectoryAtURL(_faviconDirectoryURL, withIntermediateDirectories: true, attributes: nil, error: nil)
        println(NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.tarunon.openin"))
        storeManager = TNStoreManager(delegate: self, objectModel: NSManagedObjectModel(contentsOfURL: NSBundle.mainBundle().URLForResource("BrowserModel", withExtension: "momd")!), localStoreURL: NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.tarunon.openin")!.URLByAppendingPathComponent("Browser.sqlite"), ubiquityStoreURL: nil, contentName: nil)
    }
    
    func manager(manager: TNStoreManager!, createdObjectContext context: NSManagedObjectContext!) {
        self.context = context
        NSNotificationCenter.defaultCenter().postNotificationName("BrowserModelContextDidChangedNotification", object: self)
    }
    
    func save() {
        storeManager.save()
    }
    
    func fetchedResultsController() -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: "BrowserEntity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func fetchedResultsControllerEnabled() -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: "BrowserEntity")
        fetchRequest.predicate = NSPredicate(format: "enable == %@", NSNumber(bool: true))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func selectedBrowser() -> BrowserEntity? {
        let fetchRequest = NSFetchRequest(entityName: "BrowserEntity")
        fetchRequest.predicate = NSPredicate(format: "enable == %@", NSNumber(bool: true))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        return context.executeFetchRequest(fetchRequest, error: nil)?.first as BrowserEntity?
    }
    
    func refresh(offset: Int, completion: () -> Void) {
        let request = NSURLRequest(URL: NSURL(string: BrowserServerAddress + "?offset=\(offset)")!)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            if let data = data {
                let ary = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: nil) as? [NSDictionary]
                var idx = offset
                for dict in ary! {
                    let browser = NSEntityDescription.insertNewObjectForEntityForName("BrowserEntity", inManagedObjectContext: self.context) as BrowserEntity
                    browser.setValuesForKeysWithDictionary(dict as NSDictionary)
                    browser.index = idx++
                }
            }
            completion()
        }
    }
    
    func getIcon(browser: BrowserEntity, block: (image: UIImage?) -> Void) {
        let originalURL = NSURL(string: browser.iconURL)
        let cachedURL = _faviconDirectoryURL.URLByAppendingPathComponent("\(browser.iconURL.hash).png")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            var imageData: NSData!
            if NSFileManager.defaultManager().fileExistsAtPath(cachedURL.path!) {
                imageData = NSURLConnection.sendSynchronousRequest(NSURLRequest(URL: cachedURL), returningResponse: nil, error: nil)
            } else {
                var response: NSURLResponse?
                imageData = NSURLConnection.sendSynchronousRequest(NSURLRequest(URL: originalURL!), returningResponse: &response, error: nil)
                if ((response!.MIMEType?.hasPrefix("image")) != nil) {
                    imageData.writeToURL(cachedURL, atomically: true)
                } else {
                    imageData = nil
                }
            }
            let image = UIImage(data: imageData)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                block(image: image)
            })
        })
    }
}