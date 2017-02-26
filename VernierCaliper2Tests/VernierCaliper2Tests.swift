//
//  VernierCaliper2Tests.swift
//  VernierCaliper2Tests
//
//  Created by Jiun Wei Chia on 28/1/17.
//  Copyright © 2017 Jiun Wei Chia. All rights reserved.
//

import XCTest
@testable import VernierCaliper2

class VernierCaliper2Tests: XCTestCase {
    
    var appController: VCAppController!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        appController = UIApplication.shared.keyWindow!.rootViewController!.childViewControllers[0] as! VCAppController
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLocale() {
        VCAppController.locale = Locale(identifier: "en_SG")
        
        var oldScore: Int
        
        oldScore = appController.gameState.score
        appController.vernierView.answer = 217
        appController.inputBar.textField.text = "2.17"
        appController.checkPressed()
        XCTAssert(appController.gameState.score == oldScore + 1, "Score not increased when answer uses decimal point correctly")
        
        oldScore = appController.gameState.score
        appController.vernierView.answer = 217
        appController.inputBar.textField.text = "2,17"
        appController.checkPressed()
        XCTAssert(appController.gameState.score == oldScore, "Score changed when answer uses decimal comma incorrectly")
        
        VCAppController.locale = Locale(identifier: "in")
        
        oldScore = appController.gameState.score
        appController.vernierView.answer = 217
        appController.inputBar.textField.text = "2,17"
        appController.checkPressed()
        XCTAssert(appController.gameState.score == oldScore + 1, "Score not increased when answer uses decimal comma correctly")
        
        oldScore = appController.gameState.score
        appController.vernierView.answer = 217
        appController.inputBar.textField.text = "2.17"
        appController.checkPressed()
        XCTAssert(appController.gameState.score == oldScore, "Score changed when answer uses decimal point incorrectly")
    }
    
}
