//
//  TextViewController.swift
//  Splash Calc
//
//  Created by Haluk Isik on 7/5/15.
//  Copyright (c) 2015 Haluk Isik. All rights reserved.
//

import UIKit

class TextViewController: UIViewController
{
    @IBOutlet weak var textView: UITextView! {
        didSet {
            textView.text = text
        }
    }

    var text: String = "" {
        didSet {
            textView?.text = text
        }
    }
    
    override var preferredContentSize: CGSize {
        get {
            if textView != nil && presentingViewController != nil {
                return textView.sizeThatFits(presentingViewController!.view.bounds.size)
            } else {
                return super.preferredContentSize
            }
        }
        set { super.preferredContentSize = newValue }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // MARK: - User defaults
        let userDefaults = UserDefaults.standard
        var variables = [String]()
        var expressions = [String]()
        let expressionKeys = ["Exp 1", "Exp 2"]
        
        // Get stored variables from user defaults
        if let storedVariables = userDefaults.object(forKey: "brain.variableValues") as? [String:Double] {
            let sortedByKeyAsc = sorted(storedVariables) { $0.0 < $1.0 }
            for (key, value) in sortedByKeyAsc {
                var newKey = key.replacingOccurrences(of: "$", with: "")
                variables.append("\(newKey) = \(value)")
            }
        }

        // Get stored expressions from user defaults
        for key in expressionKeys {
            if let storedExpressions = userDefaults.array(forKey: "parseStack.\(key)") as? [String] {
                var exp = "".join(storedExpressions)
                exp = exp.replacingOccurrences(of: "$", with: "")
                expressions.append(exp)
            }
        }
        
        // MARK: Styling
        
        //Header font style
        let headerFont = UIFont(name: "HelveticaNeue-Bold", size: 24.0)
        let shadow : NSShadow = NSShadow()
        shadow.shadowOffset = CGSize(width: -2.0, height: -2.0)
        
        let headerAttributes: NSObject = [
            NSFontAttributeName : headerFont ?? UIFont.boldSystemFont(ofSize: 24.0),
            NSUnderlineStyleAttributeName : 1,
            NSForegroundColorAttributeName : UIColor.black,
            NSTextEffectAttributeName : NSTextEffectLetterpressStyle,
            NSShadowAttributeName : shadow]
        
        //Body text font style
        let bodyFont = UIFont(name: "HelveticaNeue-Regular", size: 22.0)
        
        let bodyAttributes: NSObject = [
            NSFontAttributeName : headerFont ?? UIFont.systemFont(ofSize: 22.0),
            NSUnderlineStyleAttributeName : 1,
            NSForegroundColorAttributeName : UIColor.black,
            NSTextEffectAttributeName : NSTextEffectLetterpressStyle]

        // Style headers
        let headers = ["Stored variables", "Stored expressions"]
        var headersAttributed = [NSMutableAttributedString]()
        for element in headers {
            let attributedString = NSMutableAttributedString(string: element)
            let attr = NSMutableAttributedString(string: element, attributes: headerAttributes as? [AnyHashable: Any] as! [String : Any]?)
            attributedString.addAttribute(NSFontAttributeName, value: headerFont ?? UIFont.boldSystemFont(ofSize: 24.0), range: NSRange(location: 0, length: attributedString.length))
            
            headersAttributed.append(attributedString)
        }
        
        // Style expressions
        var expressionsAttributed = [NSMutableAttributedString]()
//        if let expressionsUnwrapped = expressions {
            for element in expressions {
                let attributedString = NSMutableAttributedString(string: element, attributes: bodyAttributes as? [AnyHashable: Any] as! [String : Any]?)
                expressionsAttributed.append(attributedString)
            }
//        }
        
        // Style variables
        var variablesAttributed = [NSMutableAttributedString]()
//        if let variablesUnwrapped = variables {
            for element in variables {
                let attributedString = NSMutableAttributedString(string: element, attributes: bodyAttributes as? [AnyHashable: Any] as! [String : Any]?)
                variablesAttributed.append(attributedString)
            }
//        }
        
        // New line character
        let newLine = NSMutableAttributedString(string: "\\n")
        
        
        // The attributed text
//        text = headersAttributed[0]
//        for variableAttributed in variablesAttributed {
//            text!.appendAttributedString(variableAttributed)
//        }
//        text!.appendAttributedString(headersAttributed[1])
//        for expressionAttributed in expressionsAttributed {
//            text!.appendAttributedString(expressionAttributed)
//        }
        
        
        text = headers[0] + "\n"
        for variable in variables {
            text += variable + "\n"
        }
        text += "\n" + headers[1] + "\n"
        for expression in expressions {
            text += expression + "\n"
        }
    }
    
    
    
}
