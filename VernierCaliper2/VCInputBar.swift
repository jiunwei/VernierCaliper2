//
//  VCInputBar.swift
//  VernierCaliper2
//
//  Created by Jiun Wei Chia on 29/1/17.
//  Copyright © 2017 Jiun Wei Chia. All rights reserved.
//

import UIKit

protocol VCInputBarDelegate: class {
    
    func checkPressed()
    
}

@IBDesignable class VCInputBar: UIView, UITextFieldDelegate {
    
    // MARK: - Properties
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var button: UIButton!
    
    weak var delegate: VCInputBarDelegate? = nil
    
    var doubleValue: Double? {
        let formatter = NumberFormatter()
        formatter.locale = VCAppController.locale
        return formatter.number(from: textField.text!)?.doubleValue
    }
    
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
        
        frame.size.height = VCAppController.barHeight
        
        Bundle(for: VCInputBar.self).loadNibNamed("VCInputBar", owner: self)
        addSubview(contentView)
    }
    
    // MARK: - Actions
    
    @IBAction func checkPressed(_ sender: Any) {
        delegate?.checkPressed()
    }
    
    // MARK: - Methods
    
    func dismiss() {
        textField.resignFirstResponder()
    }
    
    func clear() {
        textField.text = ""
    }
    
    // MARK: - UIView overrides
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var result = super.sizeThatFits(size)
        result.height = VCAppController.barHeight
        return result
    }
    
    override func layoutSubviews() {
        contentView.frame = bounds
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.range(of: "^[\\d\\.,]*$", options: .regularExpression) != nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        checkPressed(textField)
        return true
    }
    
}
