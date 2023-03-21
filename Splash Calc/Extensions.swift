//
//  Extensions.swift
//  Calculator
//
//  Created by Haluk Isik on 6/17/15.
//  Copyright (c) 2015 Haluk Isik. All rights reserved.
//

import UIKit

extension Array {
    func pairs(_ block: (Element, Element?)->()) {
        if count == 0 { return }
        if count == 1 { block(self.first!, nil) }
        
        var last = self[0]
        for i in self[1..<count] {
            block(last, i)
            last = i
        }
    }
}

extension String
{
    var toggleMinus: String {
        if self.hasPrefix("-") {
            return dropFirst(self)
        }
        else {
            return "-" + self
        }
    }
    subscript (i: Int) -> Character {
        return self[advance(self.startIndex, i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substring(with: (advance(startIndex, r.lowerBound) ..< advance(startIndex, r.upperBound)))
    }
}

extension UILabel
{
    var contentSize: CGSize
    {
        let label: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: super.frame.size.width, height: super.frame.size.height))
        label.numberOfLines = 1
        label.lineBreakMode = NSLineBreakMode.byTruncatingHead
        label.font = self.font
        label.text = self.text ?? " "
        label.textAlignment = NSTextAlignment.right
        
//        let label = self
        
        label.sizeToFit()
        
        return label.frame.size
    }
    
    func rightAlignWithContentSize () -> CGRect
    {
        let extraWidth = self.contentSize.width - self.frame.size.width
        let frame = CGRect(x: self.frame.origin.x - extraWidth, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.width)
        
        return frame
    }
    func makeItTemporarilyBig () -> CGRect
    {
        let extraWidth = self.frame.size.width
        let frame = CGRect(x: self.frame.origin.x - extraWidth, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.width)
        
        return frame
    }
}
extension UIColor
{
    convenience init(rgba: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        if rgba.hasPrefix("#") {
            let index   = advance(rgba.startIndex, 1)
            let hex     = rgba.substring(from: index)
            let scanner = Scanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexInt64(&hexValue) {
                switch (count(hex)) {
                case 3:
                    red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                    green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                    blue  = CGFloat(hexValue & 0x00F)              / 15.0
                case 4:
                    red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                    green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                    blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                    alpha = CGFloat(hexValue & 0x000F)             / 15.0
                case 6:
                    red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
                case 8:
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                default:
                    print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8")
                }
            } else {
                println("Scan hex error")
            }
        } else {
            print("Invalid RGB string, missing '#' as prefix")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}

extension UIView {
    
    func show(_ duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, damping: CFloat = 0.5, velocity: CGFloat = 1.0, completion: ((Bool) -> Void) = {(finished: Bool) -> Void in })
    {
        let width = self.frame.size.width
        let height = self.frame.size.height
        let origin = self.frame.origin
        
        let size = self.frame.size
        self.frame.size = CGSize.zero
        
        //self.frame = CGRectMake(origin.x, origin.y + height / 2, width, 0.0)

        UIView.animateWithDuration(duration, delay: delay, usingSpringWithDamping: 0.9, initialSpringVelocity: velocity, options: nil, animations: {
            //self.frame = CGRectMake(origin.x, origin.y, width, height)
            self.frame.size = size
        }, completion: completion)
        
    
    }
    

    
}
