//
//  VCBackgroundView.swift
//  VernierCaliper2
//
//  Created by Jiun Wei Chia on 29/1/17.
//  Copyright © 2017 Jiun Wei Chia. All rights reserved.
//

import UIKit

@IBDesignable class VCBackgroundView: UIView {
    
    override static var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        baseInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        baseInit()
    }
    
    func baseInit() {
        let gradientLayer = self.layer as! CAGradientLayer
        let startColor = UIColor(red: 251.0/255.0, green: 199.0/255.0, blue: 43.0/255.0, alpha: 1.0).cgColor
        let endColor = UIColor(red: 243.0/255.0, green: 98.0/255.0, blue: 15.0/255.0, alpha: 1.0).cgColor
        gradientLayer.colors = [ startColor, endColor ]
    }
    
}
