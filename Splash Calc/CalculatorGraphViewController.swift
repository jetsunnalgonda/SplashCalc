//
//  CalculatorGraphViewController.swift
//  Calculator
//
//  Created by Haluk Isik on 6/19/15.
//  Copyright (c) 2015 Haluk Isik. All rights reserved.
//

import UIKit

class CalculatorGraphViewController: UIViewController, CalculatorGraphDataSource, UIScrollViewDelegate
{
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            let tap = UITapGestureRecognizer(target: self, action: #selector(CalculatorGraphViewController.centerOffset(_:)))
            tap.numberOfTapsRequired = 2
            scrollView.addGestureRecognizer(tap)
        }
    }
    var graphView = CalculatorGraph()
    @IBOutlet weak var calculatorGraph: CalculatorGraph! {
        didSet {
            calculatorGraph.dataSource = self
            // Add gestures
            calculatorGraph.addGestureRecognizer(UIPinchGestureRecognizer(target: calculatorGraph, action: "zoom:"))
            //calculatorGraph.addGestureRecognizer(UIPanGestureRecognizer(target: calculatorGraph, action: "pan:"))
//            let tap = UITapGestureRecognizer(target: calculatorGraph, action: "centerGraph:")
//            tap.numberOfTapsRequired = 2
//            calculatorGraph.addGestureRecognizer(tap)
            
//            calculatorGraph.dataValues = initializeDataValues()
        }
    }
    
    func y(_ x: CGFloat) -> CGFloat?
    {
        count += 1
        if rpnMode {
            brain.variableValues["x"] = Double(x)
            if let y = brain.evaluate() {
                return CGFloat(y)
            }
            return nil
        } else {
            brain.variableValues["$x"] = Double(x)
            let (y, _) = brain.parseIt()
            if y != nil { return CGFloat(y!) }
            return nil
        }
    }
    
//    func initializeDataValues() -> [CGFloat:CGFloat]
//    {
//        let x
//    }
    var count = 0
    var rpnMode = false
    var parseStack: [String] {
        get {
            return brain.parseStack
        }
        set {
            brain.parseStack = newValue
        }
    }
    
    fileprivate var brain = CalculatorBrain()

    typealias PropertyList = AnyObject
    
    var program: PropertyList {
        get {
            return brain.program
        }
        set {
            brain.program = newValue
        }
    }
    
    var programs: [PropertyList] = []
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = false
//        self.navigationController?.navigationBar.translucent = true
//        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
//        self.navigationController?.view.backgroundColor = UIColor.clearColor()
//        self.navigationController?.navigationBar.barTintColor = UIColor(red: 1.0, green: 0.6, blue: 1.0, alpha: 0.1)
        
        let font = UIFont(name: "SteelfishRg-Regular", size: 20)
        if let font = font {
            self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : font, NSForegroundColorAttributeName : UIColor.black]
        }

        println("self.navigationController?.navigationBar.titleTextAttributes = \(self.navigationController?.navigationBar.titleTextAttributes)")
        
        prepareGraphView(graphView)

        scrollView.addSubview(graphView)
        scrollView.minimumZoomScale = 0.3
        scrollView.maximumZoomScale = 3.0
        
        scrollView.contentSize = graphView.frame.size
        scrollView.contentOffset = CGPoint(x: self.view.bounds.size.width * 1.5, y: self.view.bounds.size.height * 1.5)
        //println("brain.program = \(brain.program)")
        //self.navigationController?.navigationBar.backgroundColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.3)
        
    }
    
    func centerOffset(_ gesture: UITapGestureRecognizer)
    {
        println("gesture.locationInView(scrollView) = \(gesture.location(in: scrollView))")
        println("gesture.locationInView(graphView) = \(gesture.location(in: graphView))")

        scrollView.contentOffset = CGPoint(x: self.view.bounds.size.width * 1.5, y: self.view.bounds.size.height * 1.5)
    }
    
    
    func prepareGraphView(_ graphView: CalculatorGraph)
    {
        let width = self.view.bounds.size.width
        let height = self.view.bounds.size.height
        
        graphView.frame.size = CGSize(width: width * 4, height: height * 4)
        graphView.origin = CGPoint(x: width * 2, y: height * 2)
        
        graphView.backgroundColor = UIColor.white
        graphView.dataSource = self
        
        graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: "zoom:"))
//        let tap = UITapGestureRecognizer(target: graphView, action: "centerGraph:")
//        tap.numberOfTapsRequired = 2
//        graphView.addGestureRecognizer(tap)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return graphView
    }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView!, atScale scale: CGFloat) {
//        println("view = \(view), scale = \(scale)")
        println("graphView.pointsPerUnit = \(graphView.pointsPerUnit)")
        graphView.removeFromSuperview()
        let newView = CalculatorGraph()
        prepareGraphView(newView)
        scrollView.addSubview(newView)
        graphView.pointsPerUnit *= scale
        println("newView.pointsPerUnit = \(newView.pointsPerUnit)")

    }
}
