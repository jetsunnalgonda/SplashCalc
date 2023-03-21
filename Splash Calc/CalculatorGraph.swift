//
//  CalculatorGraph.swift
//  Calculator
//
//  Created by Haluk Isik on 6/20/15.
//  Copyright (c) 2015 Haluk Isik. All rights reserved.
//

import UIKit

protocol CalculatorGraphDataSource: class {
    func y(_ x: CGFloat) -> CGFloat?
    var count: Int { get }
}

@IBDesignable
class CalculatorGraph: UIView
{
    weak var dataSource: CalculatorGraphDataSource?
    //var axesDrawer = AxesDrawer()
    @IBInspectable
    var color: UIColor = UIColor.gray { didSet { setNeedsDisplay() } }
    //var scaleFactor: CGFloat = 1 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var pointsPerUnit: CGFloat = 50 {
        didSet
        {
            //println("pointsPerUnit before = \(pointsPerUnit)")
            pointsPerUnit = min(max(pointsPerUnit, 50 / Constants.MaximumZoomRatio), 50 * Constants.MaximumZoomRatio)
            //println("pointsPerUnit after = \(pointsPerUnit)")
            setNeedsDisplay()
        }
    }
    var origin: CGPoint = CGPoint() {
        didSet {
            origin.x = min(max(origin.x, self.bounds.size.width * -1), self.bounds.size.width * 2)
            origin.y = min(max(origin.y, self.bounds.size.height * -1), self.bounds.size.height * 2)
            //println("origin = \(origin)")
            //println("self.bounds.size.width = \(self.bounds.size.width)")
            
            resetOrigin = false
            setNeedsDisplay()
        }
    }
    var lineColor: UIColor = UIColor.black { didSet { setNeedsDisplay() } }
    var lineWidth: CGFloat = 2.0 { didSet { setNeedsDisplay() } }
    
    fileprivate var resetOrigin: Bool = true {
        didSet {
            if resetOrigin { setNeedsDisplay() }
        }
    }

    fileprivate struct Constants {
        static let MaximumZoomRatio: CGFloat = 10000
    }
    
    var snapshot: UIView?
    
    func zoom(_ gesture: UIPinchGestureRecognizer)
    {
        switch gesture.state {
        case .began:
            snapshot = self.snapshotView(afterScreenUpdates: false)
            snapshot!.alpha = 0.8
            self.addSubview(snapshot!)
        case .changed:
            let touch = gesture.location(in: self)
            snapshot!.frame.size.height *= gesture.scale
            snapshot!.frame.size.width *= gesture.scale
            snapshot!.frame.origin.x = snapshot!.frame.origin.x * gesture.scale + (1 - gesture.scale) * touch.x
            snapshot!.frame.origin.y = snapshot!.frame.origin.y * gesture.scale + (1 - gesture.scale) * touch.y
            gesture.scale = 1.0
        case .ended:
            let changedScale = snapshot!.frame.height / self.frame.height
            pointsPerUnit *= changedScale
            origin.x = origin.x * changedScale + snapshot!.frame.origin.x
            origin.y = origin.y * changedScale + snapshot!.frame.origin.y
            
            snapshot!.removeFromSuperview()
            snapshot = nil
            println("(zoom) pointsPerUnit = \(pointsPerUnit)")
        default: break
        }
    }
    
    func pan(_ gesture: UIPanGestureRecognizer)
    {
        //println("pan")
        switch gesture.state {
        case .began:
            snapshot = self.snapshotView(afterScreenUpdates: false)
            snapshot!.alpha = 0.8
            
            self.addSubview(snapshot!)
        case .changed:
            let translation = gesture.translation(in: self)
            snapshot!.center.x += translation.x
            snapshot!.center.y += translation.y
            gesture.setTranslation(CGPoint.zero, in: self)
        case .ended:
            origin.x += snapshot!.frame.origin.x
            origin.y += snapshot!.frame.origin.y
            
            snapshot!.removeFromSuperview()
            snapshot = nil
        default: break
        }
    }
    
    func centerGraph(_ gesture: UITapGestureRecognizer)
    {
        println("double tap")

        switch gesture.state {
        case .ended:
            origin = gesture.location(in: self)
        default: break
        }
    }
    
    // viewBounds passed to AxesDrawer
    fileprivate var viewBounds: CGRect {
        return CGRect(
            origin: CGPoint(x: 0, y: 0),
            size: bounds.size
        )
    }
    var viewCenter: CGPoint {
        return convert(center, from: superview)
    }
    
//    var dataValues = [CGFloat:CGFloat]()
    
    override func draw(_ rect: CGRect)
    {
        //let pointsPerUnit = dataSource?.getPointsPerUnit(self) ?? 50
        if resetOrigin { origin = center }
        AxesDrawer(color: color, contentScaleFactor: contentScaleFactor).drawAxesInRect(viewBounds, origin: origin, pointsPerUnit: pointsPerUnit)
        
        lineColor.set()
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        var firstValue = true
        var point = CGPoint()
        let boundary = Int(bounds.size.width * contentScaleFactor)
        for var i = 0; i <= boundary; i += 1 {
            point.x = CGFloat(i) / contentScaleFactor
            if let y = dataSource?.y((point.x - origin.x) / pointsPerUnit) {
                if !y.isNormal && !y.isZero {
                    continue
                }
                point.y = origin.y - y * pointsPerUnit
                if firstValue {
                    path.move(to: point)
                    firstValue = false
                } else {
                    path.addLine(to: point)
                }
            } else {
                firstValue = true
            }
        }
        path.stroke()
        println("count = \(dataSource!.count)")

    }

}
