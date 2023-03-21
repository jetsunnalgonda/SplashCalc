//
//  ViewController.swift
//  Calculator
//
//  Created by Haluk Isik on 6/12/15.
//  Copyright (c) 2015 Haluk Isik. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion
import NotificationCenter

@objc class CalculatorViewController: UIViewController, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, NCWidgetProviding
{
    // MARK: - Outlets
    @IBOutlet weak var display: UILabel!
    
    @IBOutlet weak var historyView: UITextView!
    
    @IBOutlet weak var history: UILabel! 
    
    @IBOutlet weak var topDisplay: UILabel! {
        didSet {
            topDisplay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CalculatorViewController.popover)))
        }
    }
    
    @IBOutlet weak var historyScrollView: UIScrollView! {
        didSet {
            historyScrollView.contentSize = history.contentSize
        }
    }
//    @IBOutlet weak var extraButtonsContainerWidth: NSLayoutConstraint!
    @IBOutlet weak var historyHorizontalSpace: NSLayoutConstraint!
    @IBOutlet weak var historyCenterX: NSLayoutConstraint!
    
//    @IBOutlet weak var setButton: UIButton!
//    @IBOutlet weak var rpnButton: UIButton!
    @IBOutlet weak var enterButton: UIButton!
    
    
    @IBOutlet weak var ansKey: UIButton!
//    @IBOutlet var parantheses: [UIButton]!
    
//    @IBOutlet var expressions: [UIButton]!
    

    @IBOutlet weak var errorLabel: UILabel!
    
    // MARK: - Properties
    let manager = CMMotionManager()

    var userDefaults = UserDefaults.standard

    var errorText = "" {
        didSet {
            let shouldHide = errorText == "" ? true : false
            if shouldHide {
                errorLabel.text = ""
                errorLabel.isHidden = true
            } else {
                errorLabel.text = " ⚠️ " + errorText
                errorLabel.isHidden = false
            }
        }
    }
    
    fileprivate struct ButtonColumns {
        static let Extra: CGFloat = 5
        static let Regular: CGFloat = 4
    }
    var displayStack: [String] = [] // To be used in non RPN mode
        {
        didSet {
//            topDisplay.text = "".join(self.displayStack)
//            display.text = !freshStart ? "".join(displayStack) : display.text
            println("brain.variableValues = \(brain.variableValues)")
            if displayStack.count > oldValue.count {
                var temp = displayStack
                let lastElement = temp.removeLast()
                brain.parseStack.append(lastElement)
            } else if displayStack.count < oldValue.count {
                brain.parseStack.removeLast()
            }
//            textToParse = display.text!
            println("displayStack = \(displayStack)")
            println("parseStack = \(brain.parseStack)")
        }
    }
    

    
    var number = "" // To check floating points in non RPN mode
                    // Also to be able to use toogleMinus in non RPN mode
        {
        willSet {
            println("number will set")
        }
        didSet {
            println("number did set")
            if setButtonPressed {
                setButtonPressed = true
            }
        }
    }
    var oldDisplayText = "0" // Set button temporarily cleans display.text
                            // and we store its value in this temporary variable
    var freshStart = true   // we have this boolean value so that we can easily implement a placeholder text
                            // in display.text, such as "0"
    
    var enterPressed = false // When we press enter, we display only the result of the expression in display.text
                                // If the user wants to press backspace they will still be able to do so
                                // See "enter" method
        {
        didSet {
            println("enterPressed (did set)= \(enterPressed)")
            if !freshStart && !enterPressed {
                previousDisplay = nil
            }
            if enterPressed {
                enterButton.backgroundColor = UIColor(rgba: "#7f8c8d")
            } else {
                enterButton.backgroundColor = defaultBackgroundEnter
                ansKey.isHidden = true
                history.isHidden = false
            }
        }
    }

    var previousDisplay: String? {
        willSet {
            if newValue == nil && previousDisplay != nil {
                display.text = previousDisplay
            }
        }
    }
    
    var defaultBackground: UIColor? // see viewDidLoad
    var defaultBackgroundEnter: UIColor? // Background color for enter when enterPressed = false
    
    var userIsInTheMiddleOfTypingANumber = false {
        didSet {
            println("userIsInTheMiddleOfTypingANumber = \(userIsInTheMiddleOfTypingANumber)")
            println("freshStart = \(freshStart)")
            println("number = \(number)")
            
            if !userIsInTheMiddleOfTypingANumber && !freshStart {
                if number != "" { displayStack.append(number) }
                number = ""
            }
        }
    }
    var setButtonPressed = false {
        didSet {
            if setButtonPressed {
//                setButton.backgroundColor = UIColor(red: 0.95, green: 0.66, blue: 0.63, alpha: 1.0)
                topDisplay.textAlignment = .left
                topDisplay.text = " Set value = " + variableValue
                println("set button pressed")
                topDisplay.isHidden = false
            }
            else {
                println("setButtonPressed = \(setButtonPressed)")
//                setButton.backgroundColor = defaultBackground
                topDisplay.textAlignment = .right
                topDisplay.text = ""
                
                let sortedByKeyAsc = sorted(brain.variableValues) { $0.0 < $1.0 } // by keys ascending
                //let sortedByValDesc = sorted(brain.variableValues) { $0.1 > $1.1 } // by values descending
                
                for (var key, value) in sortedByKeyAsc {
                    if !rpnMode { key = dropFirst(key) }
                    topDisplay.text = topDisplay.text! + "\(key) =  \(value) "
                }
                topDisplay.isHidden = topDisplay.text == "" ? true : false
            }
        }
    }
    
    var variableValue: String {
        println("enterPressed = \(enterPressed)")
//        println("setButtonPressed = \(setButtonPressed)")

        var value = ""
        if enterPressed && setButtonPressed {
            value = enterPressedValue
        } else {
            if displayStack.count > 0 {
                var temp = displayStack
                let lastElement = temp.removeLast()
                if let lastNumber = NumberFormatter().number(from: lastElement)?.doubleValue {
                    value = lastElement
                }
            }
        }
        println("variableValue = \(value)")
        return value
    }
    var enterPressedValue = ""
    // MARK: 📍RPN Mode
    // Reverse Polish Notation Mode is initially set to false
    var rpnMode = false {
        willSet(newValue) {
            if newValue {
//                rpnButton.backgroundColor = UIColor(red: 0.95, green: 0.66, blue: 0.63, alpha: 1.0)
                for (key, value) in brain.variableValues {
                    var tempKey = key
                    if tempKey[0] == "$" {
                        brain.variableValues[dropFirst(tempKey)] = value
                        brain.variableValues[key] = nil
                    }
                }
//                for paranthesis in parantheses {
//                    paranthesis.enabled = false
//                }
//                for expression in expressions {
//                    expression.enabled = false
//                }
            }
            else {
//                rpnButton.backgroundColor = defaultBackground
                for (key, value) in brain.variableValues {
                    var tempKey = key
                    if tempKey[0] != "$" {
                        brain.variableValues["$" + key] = value
                        brain.variableValues[key] = nil
                    }
                }
//                for paranthesis in parantheses {
//                    paranthesis.enabled = true
//                }
//                for expression in expressions {
//                    expression.enabled = true
//                }
            }
            
        }
    }
    fileprivate var brain = CalculatorBrain()
    
    // MARK: - Calculator Functions

    @IBAction func setButtonAction()
    {
        println("(setButtonAction) number = \(number)")
        playSetKeyClick()
        setButtonPressed = !setButtonPressed
    }
    
    @IBAction func rpnButtonAction()
    {
        playSetKeyClick()
        rpnMode = !rpnMode
        
        clearScreen()
    }
    
    
    @IBAction func appendDigit(_ sender: UIButton)
    {
        playInputClick()
        checkFreshStart()
        enterPressed = false
        let digit = sender.currentTitle!
        
        if rpnMode {
            if userIsInTheMiddleOfTypingANumber {
                display.text = display.text! + digit
                number = number + digit
            } else {
                display.text = digit
                number = digit
                userIsInTheMiddleOfTypingANumber = true
            }
        } else {

            // Check if last element is number,
            // If so don't register the digit as another number,
            // let the user continue typing a number
            if displayStack.count > 0 {
                var temp = displayStack
                let lastElement = temp.removeLast()
                if let lastNumber = NumberFormatter().number(from: lastElement)?.doubleValue {
                    displayStack.removeLast()
                    number = lastElement
                    userIsInTheMiddleOfTypingANumber = true
                }
            }
        
            if userIsInTheMiddleOfTypingANumber {
                display.text = display.text! + digit
                number = number + digit
            } else {
                display.text = display.text! + digit
                number = digit
                userIsInTheMiddleOfTypingANumber = true
            }
            
            execute()
            
        }

    }
    
    @IBAction func appendConstant(_ sender: UIButton)
    {
        playInputClick()
        checkFreshStart()
        
        let constant = sender.currentTitle!

        if userIsInTheMiddleOfTypingANumber {
            execute()
        }
        
        if rpnMode {
            if let result = brain.pushOperand(constant) {
                displayValue = result
            } else {
                displayValue = nil
            }
        } else {
            displayStack.append(constant)
            display.text = "".join(displayStack)
            execute()
        }
        
        enterPressed = false

    }
    
    var storedExpressions = [String:[String]]()
    
    
    // MARK: ❗️Append variable
    @IBAction func appendVariable(_ sender: UIButton)
    {
        playInputClick()
        checkFreshStart()

        println("(appendVariable) number = \(number)")
        
        let variable = sender.currentTitle!

        if rpnMode {
            if setButtonPressed {
                if variable[0] == "E" {
                    userIsInTheMiddleOfTypingANumber = false
                    userDefaults.set(brain.program, forKey: "rpn.program.\(variable)")
                    userDefaults.synchronize()
                    setButtonPressed = !setButtonPressed
                } else {
                    brain.variableValues[variable] = displayValue
                    setButtonPressed = !setButtonPressed
                    displayValue = brain.evaluate()
                    userDefaults.set(brain.variableValues, forKey: "brain.variableValues")
                }
            } else if variable == "→M" {
                brain.variableValues["M"] = displayValue
                displayValue = brain.evaluate()
                setButtonPressed = false
                userDefaults.set(brain.variableValues, forKey: "brain.variableValues")
                //println("second step")
            } else if variable[0] == "E" {
                println(userDefaults.object(forKey: "rpn.program.\(variable)"))
                println(userDefaults.array(forKey: "rpn.program.\(variable)"))
                
                if let program = userDefaults.array(forKey: "rpn.program.\(variable)") as? [String] {
                    println("setting values")
                    brain.program = program as CalculatorBrain.PropertyList
                    displayValue = brain.evaluate()
                }
                
            } else {
                if userIsInTheMiddleOfTypingANumber {
                    execute()
                }
                //println("third step")
                if let result = brain.pushOperand(variable) {
                    displayValue = result
                } else {
                    displayValue = nil
                }
            }
        } else if !rpnMode {
            if setButtonPressed {
                if variable[0] == "E" {
                    userIsInTheMiddleOfTypingANumber = false
                    let stack: [NSString] = displayStack as [NSString]
                    let stack2: [NSString] = brain.parseStack as [NSString]
                    userDefaults.set(stack, forKey: "displayStack.\(variable)")
                    userDefaults.set(stack2, forKey: "parseStack.\(variable)")
                    userDefaults.synchronize()
                    setButtonPressed = !setButtonPressed
                } else {
                    brain.variableValues["$" + variable] = NumberFormatter().number(from: variableValue)?.doubleValue
                    userDefaults.set(brain.variableValues, forKey: "brain.variableValues")
                    userDefaults.synchronize()
                    setButtonPressed = !setButtonPressed
                }
            } else if variable == "→M" {
                brain.variableValues["$M"] = NumberFormatter().number(from: variableValue)?.doubleValue
                userDefaults.set(brain.variableValues, forKey: "brain.variableValues")
                userDefaults.synchronize()
                setButtonPressed = false
            } else if variable[0] == "E" {
                println(userDefaults.object(forKey: "displayStack.\(variable)"))
                println(userDefaults.array(forKey: "displayStack.\(variable)"))
                println(userDefaults.stringArray(forKey: "displayStack.\(variable)"))

                if let stack = userDefaults.array(forKey: "displayStack.\(variable)") as? [String] {
                    println("setting values")
                    displayStack = stack
                    brain.parseStack = userDefaults.array(forKey: "parseStack.\(variable)") as! [String]
                    display.text = "".join(displayStack)
                    execute()
                }
                
            } else {
                if userIsInTheMiddleOfTypingANumber {
                    execute()
                }
                displayStack.append(variable)
                display.text = "".join(displayStack)
                
                brain.parseStack.removeLast()
                brain.parseStack.append("$" + variable)

            }
        }
        
        enterPressed = false
        
    }
    
    
    
    @IBAction func addParanthesis(_ sender: UIButton)
    {
        playInputClick()
        checkFreshStart()
        enterPressed = false
        userIsInTheMiddleOfTypingANumber = false

        let paranthesis = sender.currentTitle!
        
        displayStack.append(paranthesis)
        display.text = "".join(displayStack)
        execute()
//        enter()
        
    }
    
    
    @IBAction func floatingPoint()
    {
        playInputClick()
        checkFreshStart()
        enterPressed = false
        
        println("userIsInTheMiddleOfTypingANumber = \(userIsInTheMiddleOfTypingANumber)")
        println("number = \(number)")
        if userIsInTheMiddleOfTypingANumber {
            if number.range(of: ".") == nil {
                display.text = display.text! + "."
                number += "."
            }
        } else {
            if rpnMode {
                display.text = display.text! + "0."
                number += "0."
                userIsInTheMiddleOfTypingANumber = true
            } else {
                println(displayStack)
                println(displayStack.count)
                // Check if last element is number,
                // If so prevent the user to put another point mark
                if displayStack.count > 0 {
                    var temp = displayStack
                    let lastElement = temp.removeLast()
                    if let lastNumber = NumberFormatter().number(from: lastElement)?.doubleValue {
                        if lastElement.range(of: ".") == nil {
                            displayStack.removeLast()
                            display.text = display.text! + "."
                            number = lastElement + "."
                            userIsInTheMiddleOfTypingANumber = true
                        }
                    } else {
                        display.text = display.text! + "0."
                        number += "0."
                        userIsInTheMiddleOfTypingANumber = true
                    }
                } else {
                    display.text = display.text! + "0."
                    number += "0."
                    userIsInTheMiddleOfTypingANumber = true
                }
            }
        }
    }
    
    @IBAction func plusMinus()
    {
        playInputClick()

        if rpnMode {
            display.text = display.text?.toggleMinus
        } else {
            if displayStack.count > 0 {
                var temp = displayStack
                let lastElement = temp.removeLast()
                if let lastNumber = NumberFormatter().number(from: lastElement)?.doubleValue {
                    displayStack.removeLast()
                    number = lastElement.toggleMinus
                    display.text = "".join(displayStack) + number
                    userIsInTheMiddleOfTypingANumber = true
                }
                execute()
            }
        }
    }
    
    @IBAction func operate(_ sender: UIButton)
    {
        playInputClick()
        checkFreshStart()
        enterPressed = false
        
        let operation = sender.currentTitle!
        
        if userIsInTheMiddleOfTypingANumber {
            execute()
        }

        if rpnMode {
            if let result = brain.performOperation(operation) {
                displayValue = result
            } else {
                displayValue = nil
            }
        } else {
            displayStack.append(operation)
            display.text = "".join(displayStack)
            execute()
        }
        
    }

    @IBOutlet weak var clearButton: UIButton!
    
    @IBAction func clear(_ sender: UIButton)
    {
        playInputClick()

        let title = sender.currentTitle!
        switch title {
            case "C":
                clearScreen()
            case "AC":
                memoryClear()

            default:
                break
        }
    }
    
    func memoryClear()
    {
        brain = CalculatorBrain()
        clearScreen()
        
//        if let appDomain = NSBundle.mainBundle().bundleIdentifier {
//            userDefaults.removePersistentDomainForName(appDomain)
//        }
////////////////////
        
        userDefaults.removeObject(forKey: "brain.variableValues")
        userDefaults.removeObject(forKey: "displayStack.Exp 1")
        userDefaults.removeObject(forKey: "displayStack.Exp 2")
        userDefaults.removeObject(forKey: "parseStack.Exp 1")
        userDefaults.removeObject(forKey: "parseStack.Exp 2")
        userDefaults.removeObject(forKey: "rpn.program.Exp 1")
        userDefaults.removeObject(forKey: "rpn.program.Exp 2")
    }
    func clearScreen()
    {
//        clearButton.setTitle("AC", forState: .Normal)
        freshStart = true
        enterPressed = false
        previousDisplay = nil

        brain.clear()
        setButtonPressed = false
        displayValue = nil
        history.text = " "
        display.text = "0"
        displayStack.removeAll()
        brain.parseStack.removeAll()
//        errorLabel.text = ""
        number = ""
        userIsInTheMiddleOfTypingANumber = false
        errorText = ""
        let oldRpnMode = rpnMode
        rpnMode = oldRpnMode
        adjustScrollViewSize()
        println("number = \(number)")
    }
    
    @IBAction func backSpace()
    {
        playInputClick()
        enterPressed = false
        
        if rpnMode {
            if userIsInTheMiddleOfTypingANumber {
                let displayText = display.text!
                if count(displayText) > 1 {
                    display.text = dropLast(displayText)
                    if display.text == "-0" {
                        displayValue = nil
                    }
                } else {
                    displayValue = nil
                }
            } else {
                if let result = brain.popOperand() {
                    displayValue = result
                }
                else {
                    displayValue = nil
                }
            }
        } else {
            if userIsInTheMiddleOfTypingANumber {
                if count(number) > 1 {
                    number = dropLast(number)
                    display.text = dropLast(display.text!)

                    if number == "-" {
                        number = dropLast(number)
                        display.text = dropLast(display.text!)
                    }
                    if count(number) == 0 {
                        userIsInTheMiddleOfTypingANumber = false
                    }
                } else if count(number) == 1 {
                    number = dropLast(number)
                    display.text = dropLast(display.text!)
                    userIsInTheMiddleOfTypingANumber = false
                }
                execute()
            } else {
                // Check if last element in the stack is a number
                var tempStack = displayStack
                if tempStack.count > 0 {
                    if let number = NumberFormatter().number(from: tempStack.removeLast())?.doubleValue {
                        userIsInTheMiddleOfTypingANumber = true
                        self.number = displayStack.removeLast()
                        backSpace()
                    } else {
                        displayStack.removeLast()
                        display.text = "".join(displayStack)
                        userIsInTheMiddleOfTypingANumber = false
                    }
                    execute()
                } else {
                    clearScreen()
                }
            }
//            if !displayStack.isEmpty && number != "" {
//                execute()
//            }
        }
    }
    
    @IBAction func ansKeyPressed()
    {
        clearScreen()
        checkFreshStart()
        
        number = enterPressedValue
        display.text = enterPressedValue
        
        execute()
    }
    
    
    @IBAction func enter()
    {
        println(userIsInTheMiddleOfTypingANumber)
        playInputClick()
        if !enterPressed {
            enterPressed = true
            execute()
        } else {
            enterPressed = false
        }
        if setButtonPressed {
            setButtonPressed = true
        } else {
            setButtonPressed = false
        }

    }
    
    func execute()
    {
        if rpnMode {
            userIsInTheMiddleOfTypingANumber = false
            
            if displayValue != nil {
                if let result = brain.pushOperand(displayValue!) {
                    displayValue = result
                } else {
                    displayValue = nil
                }
            }
        } else {
            userIsInTheMiddleOfTypingANumber = false
            
            let (result, error) = brain.parseIt()
            if let errorDescription = error?.localizedDescription {
                let temp = error!.localizedDescription
                let tempArray = split(temp, maxSplit: 1, allowEmptySlices: true, isSeparator: { $0 == ":" })
                errorText = tempArray.first ?? ""
            } else {
                errorText = ""
            }
//            if let value = result?.doubleValue {
                displayValue = result?.doubleValue
            println("result?.doubleValue = \(result?.doubleValue)")
            println("displayValue = \(displayValue)")

//            }
            
            adjustScrollViewSize()

        }
    }
    
    // MARK: - ‼️Calculator display related section

    var displayValue: Double? {
        get {
            return NumberFormatter().number(from: display.text!)?.doubleValue

        }
        set {
            if rpnMode {
                if newValue != nil {
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal
                    numberFormatter.maximumFractionDigits = 10
                    //display.text = numberFormatter.stringFromNumber(newValue!)
                    display.text = "\(newValue!)"
                    history.text = brain.description + " = \(newValue!)"
                    adjustScrollViewSize()
                } else {
                    display.text = " "
                    history.text = brain.description
                    //adjustScrollViewSize()
                }
                
                println("brain.evaluateAndReportErrors() = \(brain.evaluateAndReportErrors())")
                if let errorMessage = brain.evaluateAndReportErrors() as? String {
                    println("errorMessage = \(errorMessage)")
                    errorText = errorMessage
                } else {
                    errorText = ""
                }
                userIsInTheMiddleOfTypingANumber = false
                adjustScrollViewSize()

            } else {
                println("displayValue set")
                if newValue != nil {
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal
                    numberFormatter.maximumFractionDigits = 10
                    
                    history.text = display.text! + " = " + "\(newValue!)"
                    
                    if enterPressed {
                        enterPressedValue = "\(newValue!)"
                        previousDisplay = display.text!
                        println("variableValue = \(variableValue)")
                        println("enterPressedValue = \(enterPressedValue)")
                        display.text = "\(newValue!)"
                        
                        ansKey.isHidden = false
                        history.isHidden = true

                    } else {
                        enterPressedValue = ""
                    }

                    adjustScrollViewSize()

                } else {
                    history.text = display.text!
                    adjustScrollViewSize()
                }
            }
        }
    }
    
    // Check if we have just started using the calculator
    // and remove the placeholder text
    func checkFreshStart()
    {
        if freshStart {
            clearButton.setTitle("C", for: UIControlState())
            display.text = ""
            freshStart = false
        }
    }

    // MARK: - Keyboard tap sounds

    fileprivate struct Sounds {
        static let KeyPressed: SystemSoundID = 1104
        static let SetKeyPressed: SystemSoundID = 1057
    }
    func playInputClick()
    {
        //let filePath = NSBundle.mainBundle().pathForResource("Tock", ofType: "caf")
        //let fileURL = NSURL(fileURLWithPath: filePath ?? "")
        //let soundID: SystemSoundID = 1104
        //AudioServicesCreateSystemSoundID(fileURL, &soundID)
        AudioServicesPlaySystemSound(Sounds.KeyPressed)
    }
    func playSetKeyClick()
    {
        AudioServicesPlaySystemSound(Sounds.SetKeyPressed)
    }

    // MARK: - View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        println("viewWillAppear")

//        self.navigationController?.navigationBar.hidden = true
    }
    override func viewDidAppear(_ animated: Bool) {
        println("viewDidAppear")

//        self.navigationController?.navigationBar.hidden = true
        
        // This dirty code is needed so that the view can adjust itself initially
        // Otherwise it insists on adding horizontal insets and setting them zero immediatelly
        // after typing anything. I couldn't figure out the reason for that behavior.
        // It doesn't do that outside the widget.
//        backSpace()

    }
    
//    struct Settings {
//        static let Graph = "defaultGraphSettings"
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("view did load")
//        self.navigationController?.navigationBar.hidden = true
        if !history.isDescendant(of: historyScrollView) {
            println("!history.isDescendantOfView")
            historyScrollView.addSubview(history)
        }

//        defaultBackground = setButton.backgroundColor!
        defaultBackgroundEnter = enterButton.backgroundColor!
        
        if let variables = userDefaults.object(forKey: "brain.variableValues") as? [String:Double] {
            brain.variableValues = variables
        }
        
//        let defaultGraphSettings: [Float] = [20.0, -10.0, 10.0, 0.2, 5.0]
//        
//        if userDefaults.objectForKey(Settings.Graph) == nil {
//            userDefaults.setObject(defaultGraphSettings, forKey: Settings.Graph)
//        }
        
        println("brain.variableValues = \(brain.variableValues)")
                
        // Add new operators and functions to DDMathParser
        brain.addOperatorsAndFunctions()
        
        if let stack = userDefaults.array(forKey: "displayStack.widget") as? [String] {
            println("setting values")
            displayStack = stack
            brain.parseStack = userDefaults.array(forKey: "parseStack.widget") as! [String]
            display.text = "".join(displayStack)
            setButtonPressed = false
            if !brain.parseStack.isEmpty {
                freshStart = false
                execute()
            } else {
                clearScreen()
            }
            println("dislayValue = \(displayValue)")
        } else {
            clearScreen()
        }
        historyHorizontalSpace.constant = 0
//        checkFreshStart()
//        enterPressed = false
//        userIsInTheMiddleOfTypingANumber = false
//        display.text = display.text! + ""

        
        // Use Device Motion Manager to backspace
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 0.02
            manager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { [weak self] (data: CMDeviceMotion!, error: NSError!) -> Void in
                if data.userAcceleration.x < -2.5 {
                    self?.backSpace()
                }
            } as! CMDeviceMotionHandler)
        }
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        println("viewWillDisappear")
        let stack: [NSString] = displayStack as [NSString]
        let stack2: [NSString] = brain.parseStack as [NSString]
        userDefaults.set(stack, forKey: "displayStack.widget")
        userDefaults.set(stack2, forKey: "parseStack.widget")
        userDefaults.synchronize()
        
        println("stack = \(stack)")
        println("stack2 = \(stack2)")

    }
    override func viewWillLayoutSubviews() {
        println("viewWillLayoutSubviews")

//        adjustSize(self.view.frame.size)
        adjustScrollViewSize()

    }
    
//    override func viewWillTransitionToSize(size: CGSize,
//        withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
//    {
//        //println("view will transition to size: \(size)")
//        //self.adjustSize(size)
//        //println("adjusting size in viewWillTransitionToSize: with size \(self.view.frame.size)")
//        //extraButtonsContainerWidth.constant = 100
//
//        coordinator.animateAlongsideTransition({ (context: UIViewControllerTransitionCoordinatorContext!) -> Void in
//            self.adjustSize(size)
//            }, completion: nil)
//    }
    func adjustSize(_ size: CGSize) {
        //adjustScrollViewSize()
        //println("adjust size")
        
        let constant = (ButtonColumns.Extra/(ButtonColumns.Extra+ButtonColumns.Regular))*size.width
        
        //        if UIDevice.currentDevice().orientation.isLandscape {
        if size.width >= size.height {
            //for button in extraButtons { button.hidden = true }
//            extraButtonsContainerWidth.constant = constant
        }
            //        if UIDevice.currentDevice().orientation.isPortrait {
        else {
            //for button in extraButtons { button.hidden = false }
//            extraButtonsContainerWidth.constant = 0
        }
    }
    
    func adjustScrollViewSize()
    {
        historyScrollView.contentSize = history.contentSize
        var offsetX = historyScrollView.contentSize.width - historyScrollView.frame.size.width
        if offsetX < 0 { offsetX = 0 }
        
        if historyScrollView.contentSize.width > historyScrollView.frame.size.width {
            historyHorizontalSpace.constant = -offsetX
            historyCenterX.constant = 0 //-offsetX / 2
            
            historyScrollView.contentOffset.x = max(history.contentSize.width, historyScrollView.frame.size.width) - historyScrollView.frame.size.width
        } else {
            historyHorizontalSpace.constant = 0
        }
        let visibleRect = CGRect(x: historyScrollView.contentOffset.x, y: historyScrollView.contentOffset.y, width: historyScrollView.frame.size.width, height: historyScrollView.frame.size.height)
    }
    
    // MARK: - Prepare Segue to Graph and Memory

    fileprivate struct Segue {
        static let Graph = "Graph"
        static let Memory = "Show Memory"
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        println("preparing for segue")
        var destination: AnyObject = segue.destination
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
        
        if let identifier = segue.identifier {
            switch identifier {

//            case Segue.Memory:
//                if let tvc: TextViewController =  destination as? TextViewController {
//                    if let ppc = tvc.popoverPresentationController {
//                        ppc.delegate = self
//                    }
//                    println("text view controller prepare for segue")
//                }
            default:
                break
            }
        }
        
    }
    
    // MARK: - Segue to Popover
    
    func popover()
    {
        performSegue(withIdentifier: Segue.Memory, sender: self)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController!, traitCollection: UITraitCollection!) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    // MARK: - Scroll View Delegate methods
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
//        println("scroll view did scroll")
        let origin: CGPoint = scrollView.contentOffset
        scrollView.contentOffset = CGPoint(x: origin.x, y: 0.0)
    }
    
    
    // MARK: - Widget Insets
    func widgetMarginInsets
        (forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
            return UIEdgeInsetsMake(0, 16, 16, 16) //Zero
    }

}

