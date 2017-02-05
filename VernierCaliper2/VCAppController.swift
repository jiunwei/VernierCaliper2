//
//  VCAppController.swift
//  VernierCaliper2
//
//  Created by Jiun Wei Chia on 29/1/17.
//  Copyright © 2017 Jiun Wei Chia. All rights reserved.
//

import UIKit
import AudioToolbox

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
    
    class Settings: NSObject, NSCoding {
        var precision = Precision.point01
        var zero = false
        var arrows = true
        var timeLimit = TimeLimit.sixty
        var sounds = true
        
        override init() {
            super.init()
        }
        
        required init?(coder aDecoder: NSCoder) {
            guard let precision = aDecoder.decodeObject(forKey: "precision") as? String, let timeLimit = aDecoder.decodeObject(forKey: "timeLimit") as? String else {
                return nil
            }
            
            self.precision = Precision(rawValue: precision)!
            self.timeLimit = TimeLimit(rawValue: timeLimit)!
            
            zero = aDecoder.decodeBool(forKey: "zero")
            arrows = aDecoder.decodeBool(forKey: "arrows")
            sounds = aDecoder.decodeBool(forKey: "sounds")
        }
        
        func encode(with: NSCoder) {
            with.encode(precision.rawValue, forKey: "precision")
            with.encode(zero, forKey: "zero")
            with.encode(arrows, forKey: "arrows")
            with.encode(timeLimit.rawValue, forKey: "timeLimit")
            with.encode(sounds, forKey: "sounds")
        }
    }
    
    struct GameState {
        var score = 0
        var timeLeft = 0
        var timer: Timer? = nil
    }
    
    // MARK: - Constants
    
    static let barHeight: CGFloat = 44
    
    let settingsURL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("settings")
    
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
    
    @IBOutlet var soundsItem: UIBarButtonItem!
    
    @IBOutlet var spaceItem: UIBarButtonItem!
    
    @IBOutlet var newItem: UIBarButtonItem!
    
    @IBOutlet var quitItem: UIBarButtonItem!
    
    private var currentMode = Mode.practice
    
    private var gameState = GameState()
    
    private var modeItems = [Mode: [UIBarButtonItem]]()
    
    private var settings = Settings()
    
    private var harpSound = UnsafeMutablePointer<SystemSoundID>.allocate(capacity: 1)
    
    private var dingSound = UnsafeMutablePointer<SystemSoundID>.allocate(capacity: 1)
    
    private var buzzerSound = UnsafeMutablePointer<SystemSoundID>.allocate(capacity: 1)
    
    private var alarmSound = UnsafeMutablePointer<SystemSoundID>.allocate(capacity: 1)
    
    private var tickSound = UnsafeMutablePointer<SystemSoundID>.allocate(capacity: 1)
    
    // MARK: - Deinitializers
    
    deinit {
        deinitSound(sound: harpSound)
        deinitSound(sound: dingSound)
        deinitSound(sound: buzzerSound)
        deinitSound(sound: alarmSound)
        deinitSound(sound: tickSound)
    }
    
    func deinitSound(sound: UnsafeMutablePointer<SystemSoundID>) {
        AudioServicesDisposeSystemSoundID(sound.pointee)
        sound.deallocate(capacity: 1)
    }
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set VCInputBar delegate.
        inputBar.delegate = self
        
        // Initialize modeItems.
        modeItems[.practice] = [precisionItem, zeroItem, arrowsItem, soundsItem, spaceItem, newItem]
        modeItems[.newGame] = [precisionItem, zeroItem, timeLimitItem, soundsItem]
        modeItems[.game] = [soundsItem, scoreItem, timeLeftItem, spaceItem, quitItem]
        
        // Load sounds.
        loadSound(name: "harp", sound: harpSound)
        loadSound(name: "ding", sound: dingSound)
        loadSound(name: "buzzer", sound: buzzerSound)
        loadSound(name: "alarm", sound: alarmSound)
        loadSound(name: "tick", sound: tickSound)
        
        // Load settings.
        if let loadedSettings = NSKeyedUnarchiver.unarchiveObject(withFile: settingsURL.path) as? Settings {
            settings = loadedSettings
        }
        configureVernierView()
        
        // Initialize notification handlers.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
        
        // Update views.
        updateUIState()
        updateButtonTitles()
    }
    
    // MARK: - Actions
    
    @IBAction func modeChanged(_ sender: UISegmentedControl) {
        // Determine new mode and configure vernier view.
        currentMode = sender.selectedSegmentIndex == 0 ? .practice : .newGame
        
        // Update UI state.
        updateUIState()
    }
    
    @IBAction func precisionPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Precision", message: nil, preferredStyle: .actionSheet)
        let point01Action = UIAlertAction(title: Precision.point01.rawValue, style: .default, handler: { _ in
            if self.settings.precision != .point01 {
                self.settings.precision = .point01
                self.updateButtonTitles()
                self.newObject()
            }
        })
        let point05Action = UIAlertAction(title: Precision.point005.rawValue, style: .default, handler: { _ in
            if self.settings.precision != .point005 {
                self.settings.precision = .point005
                self.updateButtonTitles()
                self.newObject()
            }
        })
        let randomAction = UIAlertAction(title: Precision.random.rawValue, style: .default, handler: { _ in
            if self.settings.precision != .random {
                self.settings.precision = .random
                self.updateButtonTitles()
                self.newObject()
            }
        })
        alert.addAction(point01Action)
        alert.addAction(point05Action)
        alert.addAction(randomAction)
        alert.popoverPresentationController?.barButtonItem = precisionItem
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func zeroPressed(_ sender: UIBarButtonItem) {
        settings.zero = !settings.zero
        updateButtonTitles()
        newZero()
    }
    
    @IBAction func arrowsPressed(_ sender: UIBarButtonItem) {
        settings.arrows = !settings.arrows
        updateButtonTitles()
        vernierView.arrows = settings.arrows
    }
    
    @IBAction func timeLimitPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Time Limit", message: nil, preferredStyle: .actionSheet)
        let sixtyAction = UIAlertAction(title: TimeLimit.sixty.rawValue, style: .default, handler: { _ in
            self.settings.timeLimit = .sixty
            self.updateButtonTitles()
        })
        let thirtyAction = UIAlertAction(title: TimeLimit.thirty.rawValue, style: .default, handler: { _ in
            self.settings.timeLimit = .thirty
            self.updateButtonTitles()
        })
        let fifteenAction = UIAlertAction(title: TimeLimit.fifteen.rawValue, style: .default, handler: { _ in
            self.settings.timeLimit = .fifteen
            self.updateButtonTitles()
        })
        alert.addAction(sixtyAction)
        alert.addAction(thirtyAction)
        alert.addAction(fifteenAction)
        alert.popoverPresentationController?.barButtonItem = timeLimitItem
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func soundsPressed(_ sender: UIBarButtonItem) {
        settings.sounds = !settings.sounds
        updateButtonTitles()
    }
    
    @IBAction func newPressed(_ sender: UIBarButtonItem) {
        newObject()
    }
    
    @IBAction func quitPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Quit", message: "Are you sure you want to quit?\nYour score will be discarded.", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Quit", style: .default, handler: { _ in
            self.gameState.timer?.invalidate()
            self.currentMode = .newGame
            self.configureVernierView()
            self.updateUIState()
        })
        let noAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(yesAction)
        alert.addAction(noAction)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func startGame(_ sender: Any) {
        var message = ""
        
        message += label(forPrecision: settings.precision) + "\n"
        message += label(forZero: settings.zero) + "\n"
        message += label(forTimeLimit: settings.timeLimit) + "\n"
        
        let alert = UIAlertController(title: "Start Game", message: message + "\nAre you ready to start?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Start", style: .default, handler: { _ in
            self.currentMode = .game
            self.configureVernierView()
            self.updateUIState()
            
            switch self.settings.timeLimit {
            case .sixty:
                self.gameState.timeLeft = 60
            case .thirty:
                self.gameState.timeLeft = 30
            case .fifteen:
                self.gameState.timeLeft = 15
            }
            self.gameState.score = 0
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
    
    private func label(forSounds sounds: Bool) -> String {
        return "Sounds: " + (sounds ? "On" : "Off")
    }
    
    func loadSound(name: String, sound: UnsafeMutablePointer<SystemSoundID>) {
        let url = Bundle.main.url(forResource: name, withExtension: "mp3")!
        AudioServicesCreateSystemSoundID(url as CFURL, sound)
    }
    
    private func updateUIState() {
        newGameView.isHidden = currentMode != .newGame
        
        setToolbarItems(modeItems[currentMode], animated: true)
        
        navigationController?.setNavigationBarHidden(currentMode == .game, animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    private func updateButtonTitles() {
        precisionItem.title = label(forPrecision: settings.precision)
        zeroItem.title = label(forZero: settings.zero)
        arrowsItem.title = label(forArrows: settings.arrows)
        timeLimitItem.title = label(forTimeLimit: settings.timeLimit)
        soundsItem.title = label(forSounds: settings.sounds)
        
        NSKeyedArchiver.archiveRootObject(settings, toFile: settingsURL.path)
    }
    
    private func updateGameTitles() {
        scoreItem.title = labelForScore()
        timeLeftItem.title = labelForTimeLeft()
    }
    
    private func newObject() {
        func point01Object() {
            vernierView.precision = .point01
            vernierView.answer = Double(arc4random() % 250) + 30.0
        }
        
        func point005Object() {
            vernierView.precision = .point005
            vernierView.answer = Double(arc4random() % 500) / 2.0 + 30.0
        }
        
        switch settings.precision {
        case .point01:
            point01Object()
        case .point005:
            point005Object()
        case .random:
            if arc4random() % 2 == 0 {
                point01Object()
            } else {
                point005Object()
            }
        }
        
        newZero()
        inputBar.clear()
        
        // Only play harp sound if object is visible.
        if settings.sounds && currentMode != .newGame {
            AudioServicesPlaySystemSound(harpSound.pointee)
        }
    }
    
    private func newZero() {
        switch vernierView.precision {
        case .point01:
            vernierView.zero = settings.zero ? Double(arc4random() % 11) - 5.0 : 0.0
        case .point005:
            vernierView.zero = settings.zero ? Double(arc4random() % 22) / 2.0 - 5.0 : 0.0
        }
    }
    
    private func configureVernierView() {
        // Always hide arrows for game mode.
        vernierView.arrows = currentMode == .game ? false : settings.arrows
        // Precision and zero are configured by calling newObject() since size of object must always match the precision used.
        newObject()
    }
    
    func timerFired(_ timer: Timer) {
        gameState.timeLeft -= 1
        updateGameTitles()
        if gameState.timeLeft <= 5 && gameState.timeLeft > 0 {
            if settings.sounds {
                AudioServicesPlaySystemSound(alarmSound.pointee)
            }
            UIView.animateKeyframes(withDuration: 0.5, delay: 0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25, animations: {
                    self.alertView.alpha = 1
                })
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25, animations: {
                    self.alertView.alpha = 0
                })
            }, completion: nil)
        }
        if gameState.timeLeft > 0 {
            if settings.sounds {
                AudioServicesPlaySystemSound(tickSound.pointee)
            }
        }
        if gameState.timeLeft == 0 {
            gameState.timer?.invalidate()
            inputBar.dismiss()
            if settings.sounds {
                AudioServicesPlaySystemSound(dingSound.pointee)
            }
            let alert = UIAlertController(title: "Time's Up", message: "Your final score is " + String(gameState.score) + "!", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Submit", style: .default, handler: { _ in
                // TODO: Submit to Game Center
                self.currentMode = .newGame
                self.configureVernierView()
                self.updateUIState()
                
            })
            let noAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.currentMode = .newGame
                self.configureVernierView()
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
        var sound = buzzerSound.pointee
        if let result = inputBar.doubleValue {
            if Int(result * 1000) == Int(vernierView.answer * 10) {
                success = true
                message = "You got it right! Let's try another."
                sound = dingSound.pointee
                gameState.score += 1
                inputBar.dismiss()
                updateGameTitles()
            }
        }
        if settings.sounds {
            AudioServicesPlaySystemSound(sound)
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
