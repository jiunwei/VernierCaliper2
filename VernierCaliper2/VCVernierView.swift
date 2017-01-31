//
//  VCVernierView.swift
//  VernierCaliper2
//
//  Created by Jiun Wei Chia on 30/1/17.
//  Copyright © 2017 Jiun Wei Chia. All rights reserved.
//

import UIKit

@IBDesignable class VCVernierView: UIView {
 
    // MARK: - Type definitions
    
    enum Precision: String {
        case point01 = "0.01 cm"
        case point005 = "0.005 cm"
    }
    
    // MARK: - Constants
    
    let margin: CGFloat = 20.0
    
    let width: CGFloat = 580.0
    
    let height: CGFloat = 180.0
    
    // MARK: - Properties
    
    var precision = Precision.point01 {
        didSet {
            
        }
    }
    
    var zero = true {
        didSet {
            
        }
    }
    
    var arrows = false {
        didSet {
            
        }
    }
    
    // Answer is stored in units of pixels.
    var answer = 50 {
        didSet {
            
        }
    }
    
    private var mainScale: UIBezierPath!
    
    private var mainScaleLayer = CALayer()
    
    private var objectLayer = CALayer()
    
    private var scale: CGFloat = 1.0
    
    private var origin = CGPoint(x: 0.0, y: 0.0)
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        baseInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        baseInit()
    }
    
    private func baseInit() {
        backgroundColor = UIColor.clear
        isOpaque = false
        
        mainScale = UIBezierPath()
        mainScale.move(to: CGPoint(x: 0, y: 0))
        mainScale.addLine(to: CGPoint(x: width, y: 0))
        mainScale.addLine(to: CGPoint(x: width, y: 60))
        mainScale.addLine(to: CGPoint(x: 30, y: 60))
        mainScale.addLine(to: CGPoint(x: 30, y: 120))
        mainScale.addLine(to: CGPoint(x: 20, y: 120))
        mainScale.addLine(to: CGPoint(x: 0, y: 60))
        mainScale.close()
        
        mainScaleLayer.anchorPoint = CGPoint(x: 0, y: 0)
        layer.addSublayer(mainScaleLayer)
        
        objectLayer.anchorPoint = CGPoint(x: 0, y: 0)
        layer.addSublayer(objectLayer)
    }
    
    // MARK: - UIView overrides
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let widthScale = (bounds.width - 2.0 * margin) / width
        let heightScale = (bounds.height - 2.0 * margin) / height
        scale = min(widthScale, heightScale)
        let scaledWidth = width * scale
        let scaledHeight = height * scale
        origin.x = (bounds.width - scaledWidth) / 2.0
        origin.y = (bounds.height - scaledHeight) / 2.0
        
        var context: CGContext
        var size: CGSize
        
        size = CGSize(width: width * scale, height: 120.0 * scale)
        mainScaleLayer.bounds.size = size
        mainScaleLayer.position = origin
        UIGraphicsBeginImageContext(size)
        context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.scaleBy(x: scale, y: scale)
        mainScale.fill()
        context.restoreGState()
        mainScaleLayer.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
        
        size = CGSize(width: CGFloat(answer) * scale, height: 40.0 * scale)
        objectLayer.bounds.size = size
        objectLayer.position = CGPoint(x: origin.x + 30 * scale, y: origin.y + (height - 40.0) * scale)
        UIGraphicsBeginImageContext(size)
        context = UIGraphicsGetCurrentContext()!
        UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: size)).fill()
        objectLayer.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
        
        setNeedsDisplay()
    }
    
    // MARK: - UIResponder overrides
    
    
    
    // MARK: - Methods
    
    
}
