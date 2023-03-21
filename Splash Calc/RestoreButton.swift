//
//  RestoreButton.swift
//  Splash Calc
//
//  Created by Haluk Isik on 7/6/15.
//  Copyright (c) 2015 Haluk Isik. All rights reserved.
//

import UIKit

class RestoreButton: UIView {

    // Our custom view from the XIB file
    var view: UIView!
    
    @IBOutlet weak var restore: UIButton! {
        didSet {
//            restore.setTitle("Button Title", forState: UIControlState.Normal)
            println("button set")
            println(restore)
//            restore.addTarget(self, action: "restoreToDefaults", forControlEvents: UIControlEvents.TouchUpInside)
        }
    }
    
    class func instanceFromNib() -> RestoreButton {
        return UINib(nibName: "RestoreButton", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! RestoreButton
    }
//    func restoreToDefaults()
//    {
//        println("restore to defaults")
//    }
//    func xibSetup() {
//        view = loadViewFromNib()
//        
//        // use bounds not frame or it'll be offset
//        view.frame = bounds
//        
//        // Make the view stretch with containing view
//        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
//        
//        // Adding custom subview on top of our view (over any custom drawing > see note below)
//        addSubview(view)
//    }
    
//    func loadViewFromNib() -> UIView {
//        let bundle = NSBundle(forClass: self.dynamicType)
//        let nib = UINib(nibName: "RestoreButton", bundle: bundle)
//        
//        // Assumes UIView is top level and only object in CustomView.xib file
//        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
//        return view
//    }
//    
//    override init(frame: CGRect) {
//        // 1. setup any properties here
//        
//        // 2. call super.init(frame:)
//        super.init(frame: frame)
//        
//        // 3. Setup view from .xib file
//        xibSetup()
//        println("init button done")
//    }
//    
//    required init(coder aDecoder: NSCoder) {
//        // 1. setup any properties here
//        
//        // 2. call super.init(coder:)
//        super.init(coder: aDecoder)
//        
//        // 3. Setup view from .xib file
//        xibSetup()
//    }


}
