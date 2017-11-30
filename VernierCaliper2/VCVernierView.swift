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
    
    enum DraggedComponent {
        case vernierScale(delta: CGSize)
        case object(delta: CGSize)
        case none
    }
    
    // MARK: - Constants
    
    let margin: CGFloat = 20.0
    
    let width: CGFloat = 580.0
    
    let height: CGFloat = 180.0
    
    let point01Width: CGFloat = 130.0
    
    let point005Width: CGFloat = 230.0
    
    // MARK: - Properties
    
    var precision = Precision.point01 {
        didSet {
            point01LinesLayer.isHidden = precision != .point01
            point005LinesLayer.isHidden = precision != .point005
            switch precision {
            case .point01:
                vWidth = point01Width
                redraw(layer: point01LinesLayer)
            case .point005:
                vWidth = point005Width
                redraw(layer: point005LinesLayer)
            }
            reset(layer: vernierScaleLayer)
            redraw(layer: vernierScaleLayer)
            positionArrows()
        }
    }
    
    var zero = 0.0 {
        didSet {
            mainScaleLinesLayer.position.x = CGFloat(zero) * scale
            positionArrows()
        }
    }
    
    var arrows = true {
        didSet {
            positionArrows()
            topArrowLayer.isHidden = !arrows
            bottomArrowLayer.isHidden = !arrows
        }
    }
    
    // Answer is stored in units of pixels.
    var answer = 100.0 {
        didSet {
            reset(layer: objectLayer)
            redraw(layer: objectLayer)
            
            // Need setValue(_:, forKeyPath:) to work around CAEmitterCell and CAEmitterLayer bug.
            // http://stackoverflow.com/questions/16749430/caemittercell-does-not-respect-birthrate-change
            smokeLayer.setValue(100.0, forKeyPath: "emitterCells.smoke.birthRate")
            let deadline = DispatchTime.now() + 0.5
            smokeDeadline = deadline
            DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
                if deadline == self.smokeDeadline {
                    self.smokeLayer.setValue(0.0, forKeyPath: "emitterCells.smoke.birthRate")
                }
            })
        }
    }
    
    var scale: CGFloat = 1.0
    
    var origin = CGPoint(x: 0.0, y: 0.0)
    
    private var vWidth: CGFloat = 130.0
    
    private var draggedComponent = DraggedComponent.none
    
    private var mainScale = UIBezierPath()
    
    private var mainScaleLines = UIBezierPath()
    
    private var vernierScales = [Precision: UIBezierPath]()
    
    private var point01Lines = UIBezierPath()
    
    private var point005Lines = UIBezierPath()
    
    private var topArrow = UIBezierPath()
    
    private var bottomArrow = UIBezierPath()
    
    private var mainScaleLayer = CALayer()
    
    private var mainScaleLinesLayer = CALayer()
    
    private var objectLayer = CALayer()
    
    private var vernierScaleLayer = CALayer()
    
    private var point01LinesLayer = CALayer()
    
    private var point005LinesLayer = CALayer()
    
    private var topArrowLayer = CALayer()
    
    private var bottomArrowLayer = CALayer()
    
    private var smokeLayer = CAEmitterLayer()
    
    private var smokeCell = CAEmitterCell()
    
    private var smokeDeadline = DispatchTime.distantFuture
    
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
        
        var x: Double
        var index: Int
        
        // Create main scale bezier path.
        mainScale.move(to: CGPoint(x: 0, y: 10))
        mainScale.addLine(to: CGPoint(x: width, y: 10))
        mainScale.addLine(to: CGPoint(x: width, y: 70))
        mainScale.addLine(to: CGPoint(x: 30, y: 70))
        mainScale.addLine(to: CGPoint(x: 30, y: 130))
        mainScale.addLine(to: CGPoint(x: 20, y: 130))
        mainScale.addLine(to: CGPoint(x: 0, y: 70))
        mainScale.close()
        
        // Create main scale lines.
        x = 50.0
        index = 0
        while CGFloat(x) < width {
            mainScaleLines.move(to: CGPoint(x: x, y: 70 - 1))
            mainScaleLines.addLine(to: CGPoint(x: x, y: index % 5 == 0 ? 45 : 55))
            x += 10.0
            index += 1
        }
        
        // Create vernier scale bezier paths.
        var path: UIBezierPath
        
        path = UIBezierPath()
        path.move(to: CGPoint.zero)
        path.addLine(to: CGPoint(x: point01Width, y: 0))
        path.addLine(to: CGPoint(x: point01Width, y: 15))
        path.addLine(to: CGPoint(x: 0, y: 15))
        path.close()
        path.move(to: CGPoint(x: 0, y: 65))
        path.addLine(to: CGPoint(x: point01Width, y: 65))
        path.addLine(to: CGPoint(x: point01Width, y: 100))
        path.addLine(to: CGPoint(x: 20, y: 100))
        path.addLine(to: CGPoint(x: 10, y: 130))
        path.addLine(to: CGPoint(x: 0, y: 130))
        path.close()
        vernierScales[.point01] = path
        
        path = UIBezierPath()
        path.move(to: CGPoint.zero)
        path.addLine(to: CGPoint(x: point005Width, y: 0))
        path.addLine(to: CGPoint(x: point005Width, y: 15))
        path.addLine(to: CGPoint(x: 0, y: 15))
        path.close()
        path.move(to: CGPoint(x: 0, y: 65))
        path.addLine(to: CGPoint(x: point005Width, y: 65))
        path.addLine(to: CGPoint(x: point005Width, y: 100))
        path.addLine(to: CGPoint(x: 20, y: 100))
        path.addLine(to: CGPoint(x: 10, y: 130))
        path.addLine(to: CGPoint(x: 0, y: 130))
        path.close()
        vernierScales[.point005] = path
        
        // Create 0.01 cm precision lines.
        x = 20.0
        for index in 0...10 {
            point01Lines.move(to: CGPoint(x: x, y: 65 + 1))
            point01Lines.addLine(to: CGPoint(x: x, y: index % 5 == 0 ? 80 : 75))
            x += 9.0
        }
        
        // Create 0.005 cm precision lines.
        x = 20.0
        for index in 0...20 {
            point005Lines.move(to: CGPoint(x: x, y: 65 + 1))
            point005Lines.addLine(to: CGPoint(x: x, y: index % 5 == 0 ? 80 : 75))
            x += 9.5
        }
        
        // Create top arrow bezier path.
        topArrow.move(to: CGPoint(x: 6, y: 30))
        topArrow.addLine(to: CGPoint(x: 0, y: 18))
        topArrow.addLine(to: CGPoint(x: 4, y: 18))
        topArrow.addLine(to: CGPoint(x: 4, y: 0))
        topArrow.addLine(to: CGPoint(x: 8, y: 0))
        topArrow.addLine(to: CGPoint(x: 8, y: 18))
        topArrow.addLine(to: CGPoint(x: 12, y: 18))
        topArrow.close()
        
        // Create bottom arrow bezier path.
        bottomArrow.move(to: CGPoint(x: 6, y: 0))
        bottomArrow.addLine(to: CGPoint(x: 0, y: 12))
        bottomArrow.addLine(to: CGPoint(x: 4, y: 12))
        bottomArrow.addLine(to: CGPoint(x: 4, y: 30))
        bottomArrow.addLine(to: CGPoint(x: 8, y: 30))
        bottomArrow.addLine(to: CGPoint(x: 8, y: 12))
        bottomArrow.addLine(to: CGPoint(x: 12, y: 12))
        bottomArrow.close()
        
        setup(layer: mainScaleLayer)
        layer.addSublayer(mainScaleLayer)
        
        setup(layer: mainScaleLinesLayer)
        mainScaleLayer.addSublayer(mainScaleLinesLayer)
        
        setup(layer: objectLayer)
        layer.addSublayer(objectLayer)
        
        setup(layer: vernierScaleLayer)
        layer.addSublayer(vernierScaleLayer)
        
        setup(layer: point01LinesLayer)
        vernierScaleLayer.addSublayer(point01LinesLayer)
        
        setup(layer: point005LinesLayer)
        point005LinesLayer.isHidden = true
        vernierScaleLayer.addSublayer(point005LinesLayer)
        
        setup(layer: topArrowLayer, anchor: CGPoint(x: 0.5, y: 1.0))
        layer.addSublayer(topArrowLayer)
        
        setup(layer: bottomArrowLayer, anchor: CGPoint(x: 0.5, y: 0.0))
        vernierScaleLayer.addSublayer(bottomArrowLayer)
        
        smokeCell.lifetime = 1.0
        smokeCell.alphaSpeed = -1.0
        smokeCell.spin = 5.0
        smokeCell.contents = UIImage(named: "smoke")?.cgImage
        // Need cell name to work around CAEmitterCell and CAEmitterLayer bug.
        // http://stackoverflow.com/questions/16749430/caemittercell-does-not-respect-birthrate-change
        smokeCell.name = "smoke"
        setup(layer: smokeLayer, actions: [
            "position": NSNull(),
            "bounds": NSNull(),
            "emitterSize": NSNull(),
            "emitterPosition": NSNull()
        ])
        smokeLayer.emitterShape = kCAEmitterLayerRectangle
        smokeLayer.emitterMode = kCAEmitterLayerOutline
        smokeLayer.emitterCells = [smokeCell]
        objectLayer.addSublayer(smokeLayer)
    }
    
    // MARK: - UIView overrides
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Store positions of object and vernier scale for restoration later.
        let oldScale = scale
        let oldOrigin = origin
        let mainScaleLinesX = mainScaleLinesLayer.position.x / scale
        let objectY = (objectLayer.position.y - origin.y) / scale
        let vernierScaleX = (vernierScaleLayer.position.x - origin.x) / scale
        let point01LinesX = point01LinesLayer.position.x / scale
        let point005LinesX = point005LinesLayer.position.x / scale
        
        // Calculate new scale and origin since bounds may have changed.
        let widthScale = (bounds.width - 2.0 * margin) / width
        let heightScale = (bounds.height - 2.0 * margin) / height
        scale = min(widthScale, heightScale)
        let scaledWidth = width * scale
        let scaledHeight = height * scale
        origin.x = (bounds.width - scaledWidth) / 2.0
        origin.y = (bounds.height - scaledHeight) / 2.0
        
        // Only redraw layers if scale has changed.
        if scale != oldScale {
            redrawAll()
        }
        
        // Only fix positions if scale and/or origin have changed.
        if origin != oldOrigin || scale != oldScale {
            resetAll()
            mainScaleLinesLayer.position.x = mainScaleLinesX * scale
            objectLayer.position.y = origin.y + objectY * scale
            vernierScaleLayer.position.x = origin.x + vernierScaleX * scale
            point01LinesLayer.position.x = point01LinesX * scale
            point005LinesLayer.position.x = point005LinesX * scale
            positionArrows()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func handleDrags(_ sender: UIGestureRecognizer) {
        let location = sender.location(in: self)
        
        switch sender.state {
        case .began:
            if objectLayer.frame.contains(location) {
                let delta = CGSize(width: location.x - objectLayer.frame.minX, height: location.y - objectLayer.frame.minY)
                draggedComponent = .object(delta: delta)
            } else if vernierScaleLayer.frame.contains(location) {
                let delta = CGSize(width: location.x - vernierScaleLayer.frame.minX, height: location.y - vernierScaleLayer.frame.minY)
                draggedComponent = .vernierScale(delta: delta)
            } else {
                draggedComponent = .none
            }
        case .changed:
            switch draggedComponent {
            case .object(let delta):
                var newPosition = CGPoint(x: objectLayer.position.x, y: location.y - delta.height)
                newPosition.y = max(newPosition.y, origin.y + (70.0 + 10.0) * scale)
                if vernierScaleLayer.position.x < objectLayer.frame.maxX {
                    newPosition.y = max(newPosition.y, origin.y + 130.0 * scale)
                }
                newPosition.y = min(newPosition.y, bounds.height - 40.0 * scale - margin)
                objectLayer.position = newPosition
            case .vernierScale(let delta):
                var newPosition = CGPoint(x: location.x - delta.width, y: origin.y)
                newPosition.x = max(newPosition.x, objectLayer.position.x)
                if objectLayer.position.y < origin.y + 130.0 * scale {
                    newPosition.x = max(newPosition.x, objectLayer.frame.maxX)
                }
                newPosition.x = min(newPosition.x, bounds.width - vWidth * scale - margin)
                vernierScaleLayer.position = newPosition
                positionArrows()
            default:
                break
            }
        default:
            draggedComponent = .none
        }
    }
    
    
    // MARK: - Methods
    
    func resetAll() {
        reset(layer: mainScaleLayer)
        reset(layer: mainScaleLinesLayer)
        reset(layer: objectLayer)
        reset(layer: vernierScaleLayer)
        reset(layer: point01LinesLayer)
        reset(layer: point005LinesLayer)
        reset(layer: topArrowLayer)
        reset(layer: bottomArrowLayer)
        reset(layer: smokeLayer)
    }
    
    private func setup(layer: CALayer, anchor: CGPoint = CGPoint.zero,
                       actions: [String: CAAction] = ["position": NSNull()]) {
        // Disable implicit animation when position is changed.
        layer.actions = actions
        layer.anchorPoint = anchor
        reset(layer: layer)
    }
    
    private func reset(layer: CALayer) {
        switch layer {
        case mainScaleLayer:
            layer.position = origin
        case objectLayer:
            layer.position = CGPoint(x: origin.x + 30.0 * scale, y: origin.y + (height - 40.0) * scale)
        case vernierScaleLayer:
            layer.position = CGPoint(x: origin.x + (width - vWidth) * scale, y: origin.y)
        case topArrowLayer:
            layer.position.y = origin.y + 50.0 * scale
        case bottomArrowLayer:
            layer.position.y = 80.0 * scale
        default:
            layer.position = CGPoint.zero
        }
    }
    
    private func scaleDraw(layer: CALayer, path: UIBezierPath, size: CGSize, fill: UIColor?, stroke: UIColor?,
                           width: CGFloat = 2.0, clip: Bool = true, custom: (() -> Void)? = nil) {
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        layer.bounds.size = scaledSize
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, UIScreen.main.scale * 2.0)
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.scaleBy(x: scale, y: scale)
        if clip {
            path.addClip()
        }
        if let f = fill {
            f.setFill()
            path.fill()
        }
        if let s = stroke {
            s.setStroke()
            path.lineWidth = width
            path.stroke()
        }
        if let c = custom {
            c()
        }
        context.restoreGState()
        layer.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
    }
    
    private func redraw(layer: CALayer) {
        let mainScaleTextAttributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor: UIColor.white]
        let vernierScaleTextAttributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12), NSAttributedStringKey.foregroundColor: UIColor.white]
        
        switch layer {
        case mainScaleLayer:
            scaleDraw(layer: layer, path: mainScale, size: CGSize(width: width, height: 130.0),
                      fill: UIColor.gray, stroke: UIColor.black, custom: {
                        NSString(string: "cm").draw(at: CGPoint(x: self.width - 30.0, y: 20.0), withAttributes: mainScaleTextAttributes)
            })
        case mainScaleLinesLayer:
            scaleDraw(layer: layer, path: mainScaleLines, size: CGSize(width: width, height: 130.0),
                      fill: nil, stroke: UIColor.white, width: 1.0, clip: false, custom: {
                        NSString(string: "0").draw(at: CGPoint(x: 46.0, y: 20.0), withAttributes: mainScaleTextAttributes)
                        NSString(string: "1").draw(at: CGPoint(x: 146.0, y: 20.0), withAttributes: mainScaleTextAttributes)
                        NSString(string: "2").draw(at: CGPoint(x: 246.0, y: 20.0), withAttributes: mainScaleTextAttributes)
                        NSString(string: "3").draw(at: CGPoint(x: 346.0, y: 20.0), withAttributes: mainScaleTextAttributes)
                        NSString(string: "4").draw(at: CGPoint(x: 446.0, y: 20.0), withAttributes: mainScaleTextAttributes)
            })
        case objectLayer:
            let objectSize = CGSize(width: CGFloat(answer), height: 40.0)
            scaleDraw(layer: layer, path: UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: objectSize)),
                      size: objectSize, fill: UIColor.red, stroke: UIColor.black, clip: false)
            // Also size smokeLayer to fit objectLayer.
            smokeLayer.bounds.size = layer.bounds.size
            smokeLayer.emitterSize = layer.bounds.size
            smokeLayer.emitterPosition = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)
        case vernierScaleLayer:
            scaleDraw(layer: layer, path: vernierScales[precision]!, size: CGSize(width: vWidth, height: 130.0),
                      fill: UIColor.blue, stroke: UIColor.black)
        case point01LinesLayer:
            scaleDraw(layer: layer, path: point01Lines, size: CGSize(width: vWidth, height: 130.0),
                      fill: nil, stroke: UIColor.white, width: 1.0, clip: false, custom: {
                        NSString(string: "0").draw(at: CGPoint(x: 16.0, y: 80.0), withAttributes: vernierScaleTextAttributes)
                        NSString(string: "5").draw(at: CGPoint(x: 61.0, y: 80.0), withAttributes: vernierScaleTextAttributes)
                        NSString(string: "10").draw(at: CGPoint(x: 104.0, y: 80.0), withAttributes: vernierScaleTextAttributes)
            })
        case point005LinesLayer:
            scaleDraw(layer: layer, path: point005Lines, size: CGSize(width: vWidth, height: 130.0),
                      fill: nil, stroke: UIColor.white, width: 1.0, clip: false, custom: {
                        NSString(string: "0").draw(at: CGPoint(x: 16.0, y: 80.0), withAttributes: vernierScaleTextAttributes)
                        NSString(string: "5").draw(at: CGPoint(x: 111.0, y: 80.0), withAttributes: vernierScaleTextAttributes)
                        NSString(string: "10").draw(at: CGPoint(x: 204.0, y: 80.0), withAttributes: vernierScaleTextAttributes)
            })
        case topArrowLayer:
            scaleDraw(layer: layer, path: topArrow, size: CGSize(width: 12.0, height: 30.0),
                      fill: UIColor.red, stroke: UIColor.black)
        case bottomArrowLayer:
            scaleDraw(layer: layer, path: bottomArrow, size: CGSize(width: 12.0, height: 30.0),
                      fill: UIColor.red, stroke: UIColor.black)
        default:
            break
        }
        
        setNeedsDisplay()
    }
    
    private func redrawAll() {
        redraw(layer: mainScaleLayer)
        redraw(layer: mainScaleLinesLayer)
        redraw(layer: objectLayer)
        redraw(layer: vernierScaleLayer)
        redraw(layer: point01LinesLayer)
        redraw(layer: point005LinesLayer)
        redraw(layer: topArrowLayer)
        redraw(layer: bottomArrowLayer)
    }
    
    private func positionArrows() {
        if !arrows {
            return
        }
        let main0 = origin.x + CGFloat(50.0 + zero) * scale
        let vernier0 = vernierScaleLayer.position.x + 20.0 * scale
        let length = (vernier0 - main0) / scale
        // Top and bottom arrows must agree on a quantized value of length.
        // This prevents top arrow from shifting back while bottom arrow is still pointing at 0 on the vernier scale.
        // This occurs if we use some calculation shortcuts based on the unquantized length.
        var intervals: Int
        switch precision {
        case .point01:
            intervals = Int(round(length))
            topArrowLayer.position.x = main0 + CGFloat(floor(Double(intervals) / 10.0)) * 10.0 * scale
            bottomArrowLayer.position.x = (20.0 + CGFloat((intervals + 10) % 10) * 9.0) * scale
        case .point005:
            intervals = Int(round(length * 2))
            topArrowLayer.position.x = main0 + CGFloat(floor(Double(intervals) / 20.0)) * 10.0 * scale
            bottomArrowLayer.position.x = (20.0 + CGFloat((intervals + 20) % 20) * 9.5) * scale
        }
    }

}
