//
//  BrowserCollectionViewCell.swift
//  OpenInBrowser
//
//  Created by tarunon on 2014/09/15.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//

import UIKit

var roundView: UIImageView!

class BrowserCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var hilightView: UIView!
    
    override class func initialize() {
        roundView = UIImageView()
        roundView.layer.cornerRadius = 10
        roundView.clipsToBounds = true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        hilightView.hidden = true
        hilightView.layer.cornerRadius = 10
        hilightView.clipsToBounds = true
    }
    
    var browser: BrowserEntity! {
        didSet {
            let newValue = browser
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
            nameLabel.text = self.browser.appName + "\nで開く"
        }
    }
    
    var hilight: Bool! {
        didSet {
            hilightView.hidden = (hilight == false)
        }
    }
}