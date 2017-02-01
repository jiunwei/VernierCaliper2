//
//  VCAppController.swift
//  VernierCaliper2
//
//  Created by Jiun Wei Chia on 29/1/17.
//  Copyright © 2017 Jiun Wei Chia. All rights reserved.
//

import UIKit

class VCAppController: UIViewController, VCInputBarDelegate {
    
    // MARK: - Type definitions
    
    enum Mode {
        case practice
        case newGame
        case game
    }
    
    enum Precision: String {
        case point01 = "0.01 cm"
        case point005 = "0.005 cm"
        case random = "Random"
    }
    
    enum TimeLimit: String {
        case sixty = "60 s"
        case thirty = "30 s"
        case fifteen = "15 s"
    }
    
    struct Settings {
        var precision = Precision.point01
        var zero = true
        var arrows = false
        var timeLimit = TimeLimit.sixty
    }
    
    struct GameState {
        var score = 0
        var timeLeft = 0
        var timer: Timer? = nil
    }
    
    // MARK: - Constants
    
    static let barHeight: CGFloat = 44
    
    // MARK: - Properties
    
    @IBOutlet weak var alertView: UIView!
    
    @IBOutlet weak var newGameView: UIVisualEffectView!
    
    @IBOutlet weak var inputBar: VCInputBar!
    
    @IBOutlet weak var vernierView: VCVernierView!
    
    @IBOutlet var precisionItem: UIBarButtonItem!
    
    @IBOutlet var zeroItem: UIBarButtonItem!
    
    @IBOutlet var arrowsItem: UIBarButtonItem!
    
    @IBOutlet var timeLimitItem: UIBarButtonItem!
    
    @IBOutlet var scoreItem: UIBarButtonItem!

    @IBOutlet var timeLeftItem: UIBarButtonItem!
    
    @IBOutlet var spaceItem: UIBarButtonItem!
    
    @IBOutlet var newItem: UIBarButtonItem!
    
    @IBOutlet var quitItem: UIBarButtonItem!
    
    private var currentMode = Mode.practice
    
    private var gameState = GameState()
    
    private var modeItems = [Mode: [UIBarButtonItem]]()
    
    private var modeSettings = [Mode: Settings]()
    
    private var precisionAlerts = [Mode: UIAlertController]()
    
    private var timeLimitAlert = UIAlertController(title: "Time Limit", message: nil, preferredStyle: .actionSheet)
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set VCInputBar delegate.
        inputBar.delegate = self
        
        // Initialize modeItems.
        modeItems[.practice] = [precisionItem, zeroItem, arrowsItem, spaceItem, newItem]
        modeItems[.newGame] = [precisionItem, zeroItem, timeLimitItem]
        modeItems[.game] = [scoreItem, timeLeftItem, spaceItem, quitItem]
        
        // Initialize modeSettings.
        modeSettings[.practice] = Settings(precision: .point01, zero: true, arrows: false, timeLimit: .sixty)
        modeSettings[.newGame] = Settings(precision: .random, zero: true, arrows: false, timeLimit: .sixty)
        
        // Initialize precisionAlerts.
        // Code is repeated since UIAlertActions cannot be used with multiple UIAlertControllers.
        let practicePrecisionAlert = UIAlertController(title: "Precision", message: nil, preferredStyle: .actionSheet)
        let practicePoint01Action = UIAlertAction(title: Precision.point01.rawValue, style: .default, handler: { _ in
            self.modeSettings[.practice]!.precision = .point01
            self.updateButtonTitles()
            self.newObject()
        })
        let practicePoint05Action = UIAlertAction(title: Precision.point005.rawValue, style: .default, handler: { _ in
            self.modeSettings[.practice]!.precision = .point005
            self.updateButtonTitles()
            self.newObject()
        })
        practicePrecisionAlert.addAction(practicePoint01Action)
        practicePrecisionAlert.addAction(practicePoint05Action)
        precisionAlerts[.practice] = practicePrecisionAlert
        
        let newGamePrecisionAlert = UIAlertController(title: "Precision", message: nil, preferredStyle: .actionSheet)
        let newGamePoint01Action = UIAlertAction(title: Precision.point01.rawValue, style: .default, handler: { _ in
            self.modeSettings[.newGame]!.precision = .point01
            self.updateButtonTitles()
        })
        let newGamePoint05Action = UIAlertAction(title: Precision.point005.rawValue, style: .default, handler: { _ in
            self.modeSettings[.newGame]!.precision = .point005
            self.updateButtonTitles()
        })
        let newGameRandomAction = UIAlertAction(title: Precision.random.rawValue, style: .default, handler: { _ in
            self.modeSettings[.newGame]!.precision = .random
            self.updateButtonTitles()
        })
        newGamePrecisionAlert.addAction(newGamePoint01Action)
        newGamePrecisionAlert.addAction(newGamePoint05Action)
        newGamePrecisionAlert.addAction(newGameRandomAction)
        newGamePrecisionAlert.popoverPresentationController?.barButtonItem = precisionItem
        precisionAlerts[.newGame] = newGamePrecisionAlert
        
        // Initialize timeLimitAlert.
        let sixtyAction = UIAlertAction(title: TimeLimit.sixty.rawValue, style: .default, handler: { _ in
            self.modeSettings[.newGame]!.timeLimit = .sixty
            self.updateButtonTitles()
        })
        let thirtyAction = UIAlertAction(title: TimeLimit.thirty.rawValue, style: .default, handler: { _ in
            self.modeSettings[.newGame]!.timeLimit = .thirty
            self.updateButtonTitles()
        })
        let fifteenAction = UIAlertAction(title: TimeLimit.fifteen.rawValue, style: .default, handler: { _ in
            self.modeSettings[.newGame]!.timeLimit = .fifteen
            self.updateButtonTitles()
        })
        timeLimitAlert.addAction(sixtyAction)
        timeLimitAlert.addAction(thirtyAction)
        timeLimitAlert.addAction(fifteenAction)
        timeLimitAlert.popoverPresentationController?.barButtonItem = timeLimitItem
        
        // Initialize notification handlers.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
        
        // Update views.
        updateUIState()
        updateButtonTitles()
        
        // Generate a new object.
        newObject()
    }
    
    // MARK: - Actions
    
    @IBAction func modeChanged(_ sender: UISegmentedControl) {
        // Determine new mode.
        currentMode = sender.selectedSegmentIndex == 0 ? .practice : .newGame
        
        // Update views.
        vernierView.resetAll()
        updateUIState()
        updateButtonTitles()
    }
    
    @IBAction func precisionPressed(_ sender: UIBarButtonItem) {
        precisionAlerts[currentMode]!.popoverPresentationController?.barButtonItem = precisionItem
        present(precisionAlerts[currentMode]!, animated: true, completion: nil)
    }
    
    @IBAction func zeroPressed(_ sender: UIBarButtonItem) {
        modeSettings[currentMode]!.zero = !modeSettings[currentMode]!.zero
        vernierView.zero = modeSettings[currentMode]!.zero
        updateButtonTitles()
    }
    
    @IBAction func arrowsPressed(_ sender: UIBarButtonItem) {
        modeSettings[currentMode]!.arrows = !modeSettings[currentMode]!.arrows
        vernierView.arrows = modeSettings[currentMode]!.arrows
        updateButtonTitles()
    }
    
    @IBAction func timeLimitPressed(_ sender: UIBarButtonItem) {
        timeLimitAlert.popoverPresentationController?.barButtonItem = timeLimitItem
        present(timeLimitAlert, animated: true, completion: nil)
    }
    
    @IBAction func newPressed(_ sender: UIBarButtonItem) {
        newObject()
    }
    
    @IBAction func quitPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Quit", message: "Are you sure you want to quit?\nYour score will be discarded.", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Quit", style: .default, handler: { _ in
            self.gameState.timer?.invalidate()
            self.currentMode = .newGame
            self.updateUIState()
        })
        let noAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(yesAction)
        alert.addAction(noAction)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func startGame(_ sender: Any) {
        let gameSettings = modeSettings[.newGame]!
        var message = ""
        
        message += label(forPrecision: gameSettings.precision) + "\n"
        message += label(forZero: gameSettings.zero) + "\n"
        message += label(forTimeLimit: gameSettings.timeLimit) + "\n"
        
        let alert = UIAlertController(title: "Start Game", message: message + "\nAre you ready to start?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Start", style: .default, handler: { _ in
            self.currentMode = .game
            self.gameState.score = 0
            switch self.modeSettings[.newGame]!.timeLimit {
            case .sixty:
                self.gameState.timeLeft = 60
            case .thirty:
                self.gameState.timeLeft = 30
            case .fifteen:
                self.gameState.timeLeft = 15
            }
            self.newObject()
            self.updateUIState()
            self.updateGameTitles()
            self.gameState.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timerFired(_:)), userInfo: nil, repeats: true)
        })
        let noAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(yesAction)
        alert.addAction(noAction)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func showLeaderboards(_ sender: Any) {
        // TODO: Show Game Center Interface
    }
    
    @IBAction func dismissKeyboard(_ sender: Any) {
        view.endEditing(true)
        updateUIState()
    }
    
    // MARK: - Methods
    
    private func label(forPrecision precision: Precision) -> String {
        return "Precision: " + precision.rawValue
    }
    
    private func label(forZero zero: Bool) -> String {
        return "Zero Errors: " + (zero ? "On" : "Off")
    }
    
    private func label(forArrows arrows: Bool) -> String {
        return "Arrows: " + (arrows ? "On" : "Off")
    }
    
    private func label(forTimeLimit timeLimit: TimeLimit) -> String {
        return "Time Limit: " + timeLimit.rawValue
    }
    
    private func labelForScore() -> String {
        return "Score: " + String(gameState.score)
    }
    
    private func labelForTimeLeft() -> String {
        return "Time Left: " + String(gameState.timeLeft) + " s"
    }
    
    private func updateUIState() {
        newGameView.isHidden = currentMode != .newGame
        
        setToolbarItems(modeItems[currentMode], animated: true)
        
        navigationController?.setNavigationBarHidden(currentMode == .game, animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    private func updateButtonTitles() {
        let settings = currentSettings()
        
        precisionItem.title = label(forPrecision: settings.precision)
        zeroItem.title = label(forZero: settings.zero)
        arrowsItem.title = label(forArrows: settings.arrows)
        timeLimitItem.title = label(forTimeLimit: settings.timeLimit)
    }
    
    private func updateGameTitles() {
        scoreItem.title = labelForScore()
        timeLeftItem.title = labelForTimeLeft()
    }
    
    private func currentSettings() -> Settings {
        return modeSettings[currentMode == .game ? .newGame : currentMode]!
    }
    
    private func newObject() {
        let settings = currentSettings()
        let point01Answer = Double(arc4random() % 250 + 30)
        let point005Answer = Double(arc4random() % 500) / 2.0 + 30.0
        
        switch settings.precision {
        case .point01:
            vernierView.precision = .point01
            vernierView.answer = point01Answer
        case .point005:
            vernierView.precision = .point005
            vernierView.answer = point005Answer
        case .random:
            if arc4random() % 2 == 0 {
                vernierView.precision = .point01
                vernierView.answer = point01Answer
            } else {
                vernierView.precision = .point005
                vernierView.answer = point005Answer
            }
        }
    }
    
    func timerFired(_ timer: Timer) {
        gameState.timeLeft -= 1
        updateGameTitles()
        if gameState.timeLeft <= 5 && gameState.timeLeft > 0 {
            UIView.animateKeyframes(withDuration: 0.5, delay: 0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25, animations: {
                    self.alertView.alpha = 1
                })
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25, animations: {
                    self.alertView.alpha = 0
                })
            }, completion: nil)
        }
        if gameState.timeLeft == 0 {
            gameState.timer?.invalidate()
            inputBar.dismiss()
            let alert = UIAlertController(title: "Time's Up", message: "Your final score is " + String(gameState.score) + "!", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Submit", style: .default, handler: { _ in
                // TODO: Submit to Game Center
                self.currentMode = .newGame
                self.updateUIState()
                
            })
            let noAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.currentMode = .newGame
                self.updateUIState()
            })
            alert.addAction(yesAction)
            alert.addAction(noAction)
            if presentedViewController != nil {
                dismiss(animated: true, completion: nil)
            }
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Notification handlers
    
    func keyboardWillShow(_ aNotification: Notification) {
        UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration), animations: {
            self.vernierView.frame.origin.y -= (self.vernierView.origin.y - 20.0)
        })
    }
    
    func keyboardWillHide(_ aNotification: Notification) {
        UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration), animations: {
            self.vernierView.frame.origin.y = self.inputBar.frame.maxY
        })
        updateUIState()
    }
    
    // MARK: - VCInputBarDelegate
    
    func checkPressed() {
        var success = false
        var message = "That is incorrect. Please try again."
        if let result = inputBar.doubleValue {
            if Int(result * 1000) == Int(vernierView.answer * 10) {
                success = true
                message = "You got it right! Let's try another."
                gameState.score += 1
                inputBar.dismiss()
                updateGameTitles()
            }
        }
        let alert = UIAlertController(title: "Check", message: message, preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            if success {
                self.newObject()
            }
        })
        alert.addAction(yesAction)
        present(alert, animated: true, completion: nil)
    }
    
}
