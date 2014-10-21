//
//  BrowserTableViewCell.swift
//  OpenInBrowser
//
//  Created by tarunon on 2014/09/15.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//


import UIKit

var roundView: UIImageView!

class BrowserTableViewCell: UITableViewCell {
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var downloadButton: UIButton!
    
    
    override class func initialize() {
        roundView = UIImageView()
        roundView.layer.cornerRadius = 4;
        roundView.clipsToBounds = true;
    }
    
    var browser: BrowserEntity! {
        didSet {
            let newValue = self.browser
            iconView.image = nil
            BrowserModelManager.sharedInstance.getIcon(self.browser, block: { (image) -> Void in
                if self.browser == newValue {
                    roundView.frame = self.iconView.frame
                    roundView.image = image;
                    UIGraphicsBeginImageContextWithOptions(self.iconView.frame.size, false, 2)
                    roundView.layer.renderInContext(UIGraphicsGetCurrentContext())
                    let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    self.iconView.image = roundedImage
                }
            })
            nameLabel.text = self.browser.appName
            enableSwitch.hidden = true
            if (UIApplication.sharedApplication().canOpenURL(NSURL(string: self.browser.schemeHTTP + "://")!)) {
                self.selectionStyle = UITableViewCellSelectionStyle.Default
                downloadButton.hidden = true
            } else {
                self.selectionStyle = UITableViewCellSelectionStyle.None
                downloadButton.hidden = false
            }
            if let enable = self.browser.enable {
                self.accessoryType = enable.boolValue ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
                enableSwitch.on = enable.boolValue
            } else {
                self.accessoryType = UITableViewCellAccessoryType.None
                enableSwitch.on = false
            }
        }
    }

    @IBAction func enableSwitchChanged(sender: AnyObject) {
        browser.enable = enableSwitch.on
    }
    
    @IBAction func downloadButtonPressed(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: browser.appstoreURL!)!)
    }
}