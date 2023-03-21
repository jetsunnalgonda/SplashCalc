//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Haluk Isik on 6/13/15.
//  Copyright (c) 2015 Haluk Isik. All rights reserved.
//

import Foundation


class CalculatorBrain {
    
    // To initialize from the Objective-C class (GraphViewController)
//    init(){}
//    class func alloc() -> CalculatorBrain {return CalculatorBrain()}

    class func newInstance() -> CalculatorBrain {
        return CalculatorBrain()
    }
    
    fileprivate enum Op: CustomStringConvertible {
        case operand(Double)
        case variable(String)
        case constant(String, Double)
        //case NullaryOperation(String, Double)
        case unaryOperation(String, (Double) -> Double, ((Double) -> String?)?)
        case binaryOperation(String, Int, (Double, Double) -> Double, ((Double, Double) -> String?)?)
        case paranthesis(String)
        
        var precedence: Int {
            get {
                switch self {
                case .binaryOperation(_, let precedence, _, _):
                    return precedence
                default:
                    return Int.max
                }
            }
        }
        
        var description: String {
            get {
                switch self {
                case .operand(let operand):
                    return "\(operand)"
                case .variable(let symbol):
                    return symbol
                case .constant(let symbol, _):
                    return symbol
                case .unaryOperation(let symbol, _, _):
                    return symbol
                case .binaryOperation(let symbol, _, _, _):
                    return symbol
                case .paranthesis(let paranthesis):
                    return paranthesis
                    
                }
            }
        }
    }
    
    fileprivate var opStack = [Op]()
    
    fileprivate var knownOps = [String:Op]()
    
    fileprivate var knownConstants = [String:Op]()
    
    var variableValues = [String:Double]()
    
    var error: String?
    
    fileprivate struct OpErrors {
        static let Variable = "Variable not set"
        static let Operand = "Not enough operands"
        static let Division = "Division by zero"
        static let SquareRoot = "Square root of negative number"
        static let Domain = "Number out of domain"
    }
    
    init() {
        func learnOp(_ op: Op) {
            knownOps[op.description] = op
        }
        func learnConstant(_ op: Op) {
            knownConstants[op.description] = op
        }
        learnOp(.binaryOperation("×", 2, *, nil))
        learnOp(Op.binaryOperation("÷", 2, { $1 / $0 },
            { divisor, _ in return divisor == 0 ? OpErrors.Division : nil }))
        learnOp(Op.binaryOperation("+", 1, +, nil))
        learnOp(Op.binaryOperation("−", 1, { $1 - $0 }, nil))
        learnOp(Op.unaryOperation("√", sqrt,
            { $0 < 0 ? OpErrors.SquareRoot : nil }))
        learnOp(Op.unaryOperation("sin", sin, nil))
        learnOp(Op.unaryOperation("cos", cos, nil))
        learnOp(Op.unaryOperation("tan", tan, nil))
        learnOp(Op.unaryOperation("asin", asin,
            { ($0 < -1 || $0 > 1) ? OpErrors.Domain : nil }))
        learnOp(Op.unaryOperation("acos", acos,
            { ($0 < -1 || $0 > 1) ? OpErrors.Domain : nil }))
        learnOp(Op.unaryOperation("atan", atan, nil ))
        learnOp(Op.binaryOperation("^", 3, { pow($1, $0)}, nil))
        learnOp(Op.unaryOperation("log", log10,
            { $0 < 0 ? OpErrors.Domain : nil }))
        learnOp(Op.unaryOperation("ln", log,
            { $0 < 0 ? OpErrors.Domain : nil }))

        //learnOp(Op.NullaryOperation("π", M_PI))
        
        learnConstant(Op.constant("π", M_PI))
        learnConstant(Op.constant("e", M_E))
    }

    
    typealias PropertyList = AnyObject
    
    var program: PropertyList {
        get {
            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? [String] {
                var newOpStack = [Op]()
                let numberFormatter = NumberFormatter()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = numberFormatter.number(from: opSymbol)?.doubleValue {
                        newOpStack.append(.operand(operand))
                    } else {
                        newOpStack.append(.variable(opSymbol))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
//    var programs: [PropertyList] = []
    
    var description: String {
        get {
            var (result, ops) = ("", opStack)
            repeat {
                var current: String?
                (current, _, ops) = description(ops)
                result = result == "" ? current! : "\(current!), \(result)"
            } while ops.count > 0
            return result
        }
    }
    
    fileprivate func description(_ ops: [Op]) -> (result: String?, precedence: Int, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .operand(let operand):
                return (String(format: "%g", operand), op.precedence, remainingOps)
            case .constant(let symbol, _):
                return (symbol, op.precedence, remainingOps);
            case .unaryOperation(let symbol, _, _):
                let operandEvaluation = description(remainingOps)
                if var operand = operandEvaluation.result {
                    if op.precedence >= operandEvaluation.precedence {
                        operand = "(\(operand))"
                    }
                    return ("\(symbol)\(operand)", op.precedence, operandEvaluation.remainingOps)
                }
            case .binaryOperation(let symbol, let precedence, _, _):
                let op1Evaluation = description(remainingOps)
                if var operand1 = op1Evaluation.result {
                    //if remainingOps.count - op1Evaluation.remainingOps.count > 2 {
                    if op.precedence > op1Evaluation.precedence {
                        operand1 = "(\(operand1))"
                    }
                    let op2Evaluation = description(op1Evaluation.remainingOps)
                    if var operand2 = op2Evaluation.result {
                        //if remainingOps.count - op2Evaluation.remainingOps.count > 2 {
                        if op.precedence > op2Evaluation.precedence {
                            operand2 = "(\(operand2))"
                        }
                        return ("\(operand2) \(symbol) \(operand1)", op.precedence, op2Evaluation.remainingOps)
                    }
                }
            case .variable(let symbol):
                return (symbol, op.precedence, remainingOps)
            case .paranthesis(let paranthesis):
                return (paranthesis, Int.max, remainingOps)
            }
        }
        return ("?", Int.max, ops)
    }
    
    fileprivate func evaluate(_ ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .operand(let operand):
                return (operand, remainingOps)
            case .variable(let symbol):
                if let variable = variableValues[symbol] {
                    return (variableValues[symbol], remainingOps)
                }
                error = OpErrors.Variable
                return (nil, remainingOps)
            case .constant(_, let constantValue):
                return (constantValue, remainingOps)
            case .unaryOperation(_, let operation, let errorTest):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    if let errorMessage = errorTest?(operand) {
                        error = errorMessage
                        return (nil, operandEvaluation.remainingOps)
                    }
                    return (operation(operand), operandEvaluation.remainingOps)
                }
            case .binaryOperation(_, _, let operation, let errorTest):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        if let errorMessage = errorTest?(operand1, operand2) {
                            error = errorMessage
                            return (nil, op2Evaluation.remainingOps)
                        }
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    }
                }
            case .paranthesis(let paranthesis):
                if paranthesis == ")" {
                    var op1Evaluation = evaluate(remainingOps)
                    let layer1 = op1Evaluation.remainingOps.removeLast()
                }
            }
            if error == nil {
                error = OpErrors.Operand
            }
        }
        return (nil, ops)
    }
    
    func evaluate() -> Double? {
        error = nil
        let (result, remainder) = evaluate(opStack)
//        println("\(opStack) = \(result) with \(remainder) left over")
        //println("\(Int.max)")
        //let ddescription = description + " "
        //println("\(description) = \(result)")
//        println("remainder = \(remainder)")
//        if remainder.count == 0 { println("empty array") }
        return result
    }
    
//    func evaluatePrograms() -> [PropertyList]
//    {
//        var (result, remainder) = evaluate(opStack)
//        var programs: [PropertyList]
//        var remainingOps = remainder
//        
//        programs = program as! [PropertyList]
//        println("programs = \(programs)")
//
//        
//        while remainingOps.count > 0 {
//            (_, remainingOps) = evaluate(remainingOps)
//            programs.append(program)
//            println("remainingOps.count = \(remainingOps.count), programs = \(programs)")
//        }
//        
//        return programs
//    }
//    func evaluateProgram()
//    {
//        var opsToEvaluate = opStack
//        while opsToEvaluate.count > 0 {
//            println("opsToEvaluate = \(opsToEvaluate)")
//            let (result, remainder) = evaluate(opsToEvaluate)
//            opsToEvaluate = remainder
//            if result == nil {opsToEvaluate.removeLast() }
//            println("from evaluateProgram: result = \(result)")
//            println("opsToEvalute.count = \(opsToEvaluate.count)")
//        }
//        println("program.count = \(program.count)")
//    }
    
    func evaluateAndReportErrors() -> AnyObject? {
        let (result, _) = evaluate(opStack)
        return result != nil ? result : error
    }
    
    func popOperand() -> Double? {
        if !opStack.isEmpty {
            opStack.removeLast()
        }
        return evaluate()
    }
    
    func pushOperand(_ operand: Double) -> Double? {
        opStack.append(Op.operand(operand))
        //println("pushOperand(operand: Double) -> Double? called")
        return evaluate()
    }
    
    func pushOperand(_ symbol: String) -> Double? {
        if let value = knownConstants[symbol] {
            opStack.append(value)
        } else {
            opStack.append(Op.variable(symbol))
        }
        //println("pushOperand(symbol: String) -> Double? called")
        return evaluate()
    }
    
    func performOperation(_ symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
    func clear() {
        opStack.removeAll()
    }
    // MARK: - DDMathParser properties
    
    let defaultOperators = DDMathOperatorSet.default()
    let evaluator = DDMathEvaluator.default()
    
    
    //    DDMathOperatorSet *defaultOperators = [DDMathOperatorSet defaultOperatorSet];
    //    defaultOperators.interpretsPercentSignAsModulo = NO;
    //
    //    DDMathOperator *powerOperator = [defaultOperators operatorForFunction:DDOperatorPower];
    //    powerOperator.associativity = DDOperatorAssociativityRight;
    //
    //    DDMathEvaluator *evaluator = [[DDMathEvaluator alloc] init];
    
    var parseStack = [String]()    // Text to be given to the parser (parseIt), it should be different than our
    // display.text, since we will have attributed strings and different syntax with variables, etc.
    // Later, we need to define our displayStack as [Op] rather than [String]
    
    // MARK: - DDMathParser
    
    var variableValuesNS = NSMutableDictionary()
    
    func setDictionary() {
        for (key, value) in variableValuesNS {
            variableValues[key as! String] = value as? Double
        }
    }
    
    func parseAndReturnValue() -> NSNumber?
    {
        var parseStackCopy = parseStack
        
        // Manual substitution here
        // I couldn't get DDMathParser to work
        for (key, value) in variableValues {
            for (index, element) in enumerate(parseStackCopy) {
                if element == key {
                    parseStackCopy[index] = "(\(value))"
                }
            }
        }
        
        // Replacement for tokens
        for (index, element) in enumerate(parseStackCopy) {
            if element == "^" {
                parseStackCopy[index] = "↑"
            }
        }

        var error: NSError?
        
        let textToParse = "".join(parseStackCopy)
        let expression: DDExpression? = DDExpression.expressionFromString(textToParse, error: &error) as! DDExpression?
        let rewritten = DDExpressionRewriter.default().expression(byRewriting: expression, with: nil)
        let value = evaluator.evaluateString(textToParse, withSubstitutions: variableValues, error: &error)

        
        return value
    }

    
    func parseIt() -> (result: NSNumber?, error: NSError?)
    {
        //        expression = DDExpression.expressionFromString(display.text, error: &error) as! DDExpression
        
        //        let variableDictionary = NSMutableDictionary() // [String:NSNumber] = [:]
        //        let newDict = NSDictionary(dictionary: brain.variableValues)
        var parseStackCopy = parseStack
        
        // Manual substitution here
        // I couldn't get DDMathParser to work
        for (key, value) in variableValues {
            for (index, element) in enumerate(parseStackCopy) {
                if element == key {
                    parseStackCopy[index] = "(\(value))"
                }
            }
        }
        
        // Replacement for tokens
        for (index, element) in enumerate(parseStackCopy) {
            if element == "^" {
                parseStackCopy[index] = "↑"
            }
        }
        
//        println("parseStack = \(parseStack)")
//        println("parseStackCopy = \(parseStackCopy)")
        //        for (key, value) in brain.variableValues {
        //            let newKey: NSObject = key as NSObject
        //            if let newValue: AnyObject? = value as? AnyObject {
        //                variableDictionary[newKey] = newValue
        //            }
        //        }
        //        variableDictionary = brain.variableValues
        var error: NSError?
        //        let tokenizer = DDMathStringTokenizer(string: display.text, operatorSet: nil, error: &error)
        //        let parser = DDParser(tokenizer: tokenizer, error: &error)
        //        let expression = parser.parsedExpressionWithError(&error)
        
        let textToParse = "".join(parseStackCopy)
//        println("I am going to parse this: \(textToParse)")
        let expression: DDExpression? = DDExpression.expressionFromString(textToParse, error: &error) as! DDExpression?
        let rewritten = DDExpressionRewriter.default().expression(byRewriting: expression, with: nil)
        //let value = evaluator.evaluateExpression(expression, withSubstitutions: newDict as [NSObject : AnyObject], error: &error)
        //let value = evaluator.evaluateString(textToParse, withSubstitutions: newDict as [NSObject : AnyObject], error: &error)
        let value = evaluator.evaluateString(textToParse, withSubstitutions: variableValues, error: &error)
        
        
        //        println("error.description = \(error?.description)")
        //        println("value.description = \(value?.description)")
        
        return (value, error)
    }
    
    func addOperatorsAndFunctions()
    {
        //        let multiplyOperator = DDMathOperator(operatorFunction: "calculatorMultiply", tokens: ["×"], arity: .Binary, associativity: .Left)
        //        let ddMultiplyOperator = DDMathOperator.infoForOperatorFunction(DDOperatorMultiply)
        //        DDMathOperatorSet.defaultOperatorSet().addOperator(multiplyOperator, withPrecedenceSameAsOperator: ddMultiplyOperator)
        //
        //        DDMathEvaluator.defaultMathEvaluator().registerFunction({
        //            (args: [AnyObject]!, vars: [NSObject : AnyObject]!, eval: DDMathEvaluator!, error: NSErrorPointer) -> DDExpression! in
        //            if args.count != 2 {
        //                var error = NSError(domain: DDMathParserErrorDomain, code: DDErrorCode.InvalidArgument.rawValue, userInfo: nil)
        //                return nil
        //            }
        //
        //            let first: DDExpression = args[0] as! DDExpression
        //            let second: DDExpression = args[1] as! DDExpression
        //
        //            let multiply: DDExpression = DDExpression.functionExpressionWithFunction(DDOperatorMultiply, arguments: [first, second], error: error) as! DDExpression
        //
        //            return multiply
        //
        //            }, forName: "calculatorMultiply")
        
        
        // MARK: SQUARE ROOT Operator with token: √
        
        let sqrtOperator = DDMathOperator(operatorFunction: "calculatorSqrt", tokens: ["√"], arity: .unary, associativity: .right)
        let ddFactorialOperator = DDMathOperator.info(forOperatorFunction: DDOperatorBitwiseNot)
        DDMathOperatorSet.default().addOperator(sqrtOperator, withPrecedenceSameAs: ddFactorialOperator)
        
        evaluator?.registerFunction({ [unowned self]
            (args: [AnyObject]!, vars: [AnyHashable: Any]!, eval: DDMathEvaluator!, error: NSErrorPointer) -> DDExpression! in
            if args.count != 1 {
                var error = NSError(domain: DDMathParserErrorDomain, code: DDErrorCode.invalidArgument.rawValue, userInfo: nil)
                return nil
            }
            
            let expression: DDExpression = args[0] as! DDExpression
            let second: DDExpression = DDExpression.number(with: NSNumber(value: 0.5 as Double)) as! DDExpression
            
            let sqrt: DDExpression = DDExpression.functionExpressionWithFunction(DDOperatorPower, arguments: [expression, second], error: error) as! DDExpression
            
            // Check for negative value in square root,
            // I couldn't get any error messages from DDMathParser,
            // The return value is shown as "nan" instead
            var number = self.evaluator.evaluateExpression(expression, withSubstitutions: self.variableValues, error: error)?.doubleValue
            //println("number = \(number)")
            if number != nil {
                if number < 0 {
                    var error = NSError(domain: DDMathParserErrorDomain, code: DDErrorCode.invalidArgument.rawValue, userInfo: nil)
                    return nil
                }
            }
            
            return sqrt
            
            }, forName: "calculatorSqrt")
        
        // MARK: 😀POWER Operator with token: ↑
        // I am using the token that is already defined in DDMathParser
        // Since I do not want to hack, I define a new token and replace
        // the token I use in my display before parsing
        
        let powerOperator = DDMathOperator(operatorFunction: "calculatorPower", tokens: ["↑"], arity: .binary, associativity: .left)
        let ddPowerOperator = DDMathOperator.info(forOperatorFunction: DDOperatorPower)
        DDMathOperatorSet.default().addOperator(powerOperator, withPrecedenceSameAs: ddPowerOperator)
        
        evaluator?.registerFunction({ [unowned self]
            (args: [AnyObject]!, vars: [AnyHashable: Any]!, eval: DDMathEvaluator!, error: NSErrorPointer) -> DDExpression! in
            if args.count != 2 {
                let error = NSError(domain: DDMathParserErrorDomain, code: DDErrorCode.invalidArgument.rawValue, userInfo: nil)
                return nil
            }
            
            let first: DDExpression = args[0] as! DDExpression
            let second: DDExpression = args[1] as! DDExpression
            
            var firstNumber = self.evaluator.evaluateExpression(first, withSubstitutions: self.variableValues, error: error)?.doubleValue
            var secondNumber = self.evaluator.evaluateExpression(second, withSubstitutions: self.variableValues, error: error)?.doubleValue
            
            if firstNumber != nil && secondNumber != nil {
                
                // Check if we are within the domain
                let number1 = pow(firstNumber!, secondNumber!)
                let number2 = -pow(-firstNumber!, secondNumber!)
                //println("number1, number2 = \(number1), \(number2)")
                
                if number1.isNaN && number2.isNaN {
                    let error = NSError(domain: DDMathParserErrorDomain, code: DDErrorCode.invalidArgument.rawValue, userInfo: nil)
                    return nil
                }
                
                let power = number1.isNaN ? number2 : number1
                let number3 = pow(power, (1 / secondNumber!))
                //println("firstNumber = \(firstNumber),\n number3 = \(number3)")
                if number1 < 0 && (number3.isNaN || number3 > 0) {
                    let error = NSError(domain: DDMathParserErrorDomain, code: DDErrorCode.invalidArgument.rawValue, userInfo: nil)
                    return nil
                }
                // Check complete!
                
                let powerExpression: DDExpression = DDExpression.numberExpressionWithNumber(NSNumber(double: power)) as! DDExpression
                
                //let result: DDExpression? = DDExpression.numberExpressionWithNumber(NSNumber(double: number)) as? DDExpression
                //                let power: DDExpression = DDExpression.functionExpressionWithFunction(DDOperatorPower, arguments: [first, second], error: error) as! DDExpression
                
                
                return powerExpression
            } else {
                return nil
            }
            
            }, forName: "calculatorPower")
        
    }
    
    func rewriteExpression() -> String
    {
        var parseStackCopy = parseStack
        
        // Manual substitution here
        // I couldn't get DDMathParser to work
        for (key, value) in variableValues {
            for (index, element) in enumerate(parseStackCopy) {
                if element == key {
                    parseStackCopy[index] = "(\(value))"
                }
            }
        }
        
        // Replacement for tokens
        for (index, element) in enumerate(parseStackCopy) {
            if element == "^" {
                parseStackCopy[index] = "↑"
            }
        }
        
        //        println("parseStack = \(parseStack)")
        //        println("parseStackCopy = \(parseStackCopy)")
        //        for (key, value) in brain.variableValues {
        //            let newKey: NSObject = key as NSObject
        //            if let newValue: AnyObject? = value as? AnyObject {
        //                variableDictionary[newKey] = newValue
        //            }
        //        }
        //        variableDictionary = brain.variableValues
        var error: NSError?
        //        let tokenizer = DDMathStringTokenizer(string: display.text, operatorSet: nil, error: &error)
        //        let parser = DDParser(tokenizer: tokenizer, error: &error)
        //        let expression = parser.parsedExpressionWithError(&error)
        
        let textToParse = "".join(parseStackCopy)
        let expression: DDExpression? = DDExpression.expressionFromString(textToParse, error: &error) as! DDExpression?
        let rewritten = DDExpressionRewriter.default().expression(byRewriting: expression, with: nil)
        
        //return rewritten.description
        return "\(rewritten)"
    }

}


