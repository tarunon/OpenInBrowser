//
//  ViewController.swift
//  OpenInBrowser
//
//  Created by tarunon on 2014/09/15.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//

import UIKit

class ViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var modelManager: BrowserModelManager!
    var fetchedResultsController = NSFetchedResultsController()

    override func viewDidLoad() {
        super.viewDidLoad()
        modelManager = BrowserModelManager.sharedInstance
        if BrowserPreferences.sharedPreferences().disableManual1 {
            self.tableView.tableHeaderView?.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 0)
            self.tableView.tableHeaderView?.hidden = true
        } else {
            self.tableView.tableHeaderView?.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 230)
        }
        NSNotificationCenter.defaultCenter().addObserverForName(BrowserModelContextDidChangedNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            self.fetchedResultsController = self.modelManager.fetchedResultsController()
            self.fetchedResultsController.delegate = self
            self.fetchedResultsController.performFetch(nil)
            self.tableView.reloadData()
            if let sections = self.fetchedResultsController.sections {
                if sections.count == 0 || sections[0].numberOfObjects == 0 {
                    self.refresh()
                }
            } else {
                self.refresh()
            }
            self.refreshControl = UIRefreshControl()
            self.refreshControl?.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)
        }
//        self.editing = true
//        self.tableView.allowsSelectionDuringEditing = true
//        self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addButtonPressed(sender: AnyObject) {
        let alert = UIAlertController(title: "ブラウザのリクエスト", message: "追加したいブラウザのリクエストを送信します。テーブルを引っ張って更新すると、追加されたブラウザが表示されます。追加には時間がかかることがあります。追加したいブラウザの、AppStoreのURLを貼り付けて送信して下さい。", preferredStyle: UIAlertControllerStyle.Alert)
        var textField: UITextField!
        alert.addTextFieldWithConfigurationHandler { (_textField: UITextField!) -> Void in
            textField = _textField
        }
        alert.addAction(UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.Cancel, handler:nil))
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
            if let text = textField.text {
                if text.componentsSeparatedByString("http").count == 2 {
                    var request = NSMutableURLRequest(URL: NSURL(string: "https://openinbrowser.appspot.com/userrequest?appstoreURL=" + text.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)!)
                    request.HTTPMethod = "POST"
                    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                        if let data = data {
                            if let success = (NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as Dictionary<String, Bool>)["success"] {
                                let alert = UIAlertController(title: "送信完了", message: "リクエストありがとうございます。反映まで今しばらくお待ちください。", preferredStyle: UIAlertControllerStyle.Alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler:nil))
                                self.presentViewController(alert, animated: true, completion: nil)
                                return
                            }
                        }
                        let alert = UIAlertController(title: "エラー", message: "申し訳ありません。しばらく時間を置いてお試し下さい。", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler:nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    })
                    return
                }
            }
            let alert = UIAlertController(title: "エラー", message: "申し訳ありません。しばらく時間を置いてお試し下さい。", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler:nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    var refreshed = false;
    
    func refresh() {
        if refreshed == true {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                NSThread.sleepForTimeInterval(2)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.refreshControl?.endRefreshing()
                    return
                })
            })
            return
        }
        if let count = fetchedResultsController.sections?[0].numberOfObjects {
            modelManager.refresh(count, completion: {
                self.refreshControl?.endRefreshing()
                return
            })
        } else {
            modelManager.refresh(0, completion: {
                self.refreshControl?.endRefreshing()
                return
            })
        }
    }
    
//    tableView delegate

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let count = fetchedResultsController.sections?.count {
            return count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = fetchedResultsController.sections?[section].numberOfObjects {
            return count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 66.0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BrowserTableViewCell", forIndexPath: indexPath) as BrowserTableViewCell
        cell.browser = fetchedResultsController.objectAtIndexPath(indexPath) as BrowserEntity
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if cell?.selectionStyle == UITableViewCellSelectionStyle.None {
            return
        }
        for browser in fetchedResultsController.fetchedObjects as [BrowserEntity] {
            browser.enable = NSNumber(bool: false)
        }
        let browser = fetchedResultsController.objectAtIndexPath(indexPath) as BrowserEntity
        browser.enable = NSNumber(bool: true)
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }
    
    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        var array = (fetchedResultsController.sections as [NSFetchedResultsSectionInfo])[sourceIndexPath.section].objects as [BrowserEntity]
        let movedObject = array.removeAtIndex(sourceIndexPath.row)
        array.insert(movedObject, atIndex: destinationIndexPath.row)
        for idx in 0..<array.count {
            array[idx].index = idx
        }
        fetchedResultsController.performFetch(nil)
    }
    
//    fetchedResultsController delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        case .Delete:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        case .Move:
            self.tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        case .Update:
            self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            BrowserPreferences.sharedPreferences().disableManual0 = true
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
}

