//
//  CoolView.swift
//  Good Crop
//
//  Created by Haluk Isik on 7/27/15.
//  Copyright (c) 2015 Haluk Isik. All rights reserved.
//

import UIKit

/// A really cool button
//@IBDesignable
class BorderedButton: UIButton {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    var cornerRadius: CGFloat = 0.0
    var borderColor: UIColor = UIColor(rgba: "#444")
    var borderWidth: CGFloat = 1.0
//    @IBInspectable var shadowColor: UIColor = UIColor.grayColor()
//    @IBInspectable var shadowRadius: CGFloat = 1.0
//    @IBInspectable var shadowOpacity: Float = 0.7
//    @IBInspectable var shadowOffset: CGSize = CGSizeMake(0, 0)
    
//    override func layoutSubviews() {
//        setupLayer()
//    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayer()
    }
    
    func setupLayer()
    {
        layer.cornerRadius = cornerRadius
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
//        layer.shadowOpacity = shadowOpacity
//        layer.shadowRadius = shadowRadius
//        layer.shadowColor = shadowColor.CGColor
//        layer.shadowOffset = shadowOffset
    }
}
