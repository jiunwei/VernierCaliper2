//
//  VCVernierView.swift
//  VernierCaliper2
//
//  Created by Jiun Wei Chia on 30/1/17.
//  Copyright © 2017 Jiun Wei Chia. All rights reserved.
//

import UIKit

@IBDesignable class VCVernierView: UIView {
 
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
        

    }
    
    
}
