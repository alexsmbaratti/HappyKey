//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit
import AudioToolbox

enum TTDeviceType{
	case ttDeviceTypeIPhone4
	case ttDeviceTypeIPhone5
	case ttDeviceTypeIPhone6
	case ttDeviceTypeIPhone6p
	
}

let metrics: [String:Double] = [
    "topBanner": 30
]
func metric(_ name: String) -> CGFloat { return CGFloat(metrics[name]!) }

// TODO: move this somewhere else and localize
let kAutoCapitalization = "kAutoCapitalization"
let kPeriodShortcut = "kPeriodShortcut"
let kKeyboardClicks = "kKeyboardClicks"
let kSmallLowercase = "kSmallLowercase"
let kActiveLanguageCode = "kActiveLanguageCode"

let vEnglishLanguageCode = "HappyKey"
let vQwertyKeyboardFileName = "QWERTY"

class KeyboardViewController: UIInputViewController {

    @objc let backspaceDelay: TimeInterval = 0.5
    @objc let backspaceRepeat: TimeInterval = 0.07

    var keyboard: Keyboard!
    @objc var forwardingView: ForwardingView!
    @objc var layout: KeyboardLayout?
    @objc var heightConstraint: NSLayoutConstraint?
    
    @objc var bannerView: SuggestionView?

    @objc var currentMode: Int {
        didSet {
            if oldValue != currentMode {
                setMode(currentMode)
            }
			
			forwardingView.currentMode = currentMode
			forwardingView.keyboard_type = keyboard_type
        }
    }
	
    @objc var backspaceActive: Bool {
        get {
            return (backspaceDelayTimer != nil) || (backspaceRepeatTimer != nil)
        }
    }
    @objc var backspaceDelayTimer: Timer?
    @objc var backspaceRepeatTimer: Timer?
    
    enum AutoPeriodState {
        case noSpace
        case firstSpace
    }
    
    var autoPeriodState: AutoPeriodState = .noSpace
    @objc var lastCharCountInBeforeContext: Int = 0
    
    var shiftState: ShiftState {
        didSet {
            self.updateKeyCaps(shiftState != .disabled)
        }
    }
    
    // state tracking during shift tap
    @objc var shiftWasMultitapped: Bool = false
    var shiftStartingState: ShiftState?
    
    @objc var keyboardHeight: CGFloat {
        get {
            return self.heightConstraint?.constant ?? 0
        }

        set {
            self.setHeight(newValue)
        }
    }
	
	@objc var viewLongPopUp:CYRKeyboardButtonView = CYRKeyboardButtonView()
	@objc var button = CYRKeyboardButton()
	
	var keyboard_type: UIKeyboardType!
	@objc var preKeyboardType = UIKeyboardType.default
	
    // TODO: why does the app crash if this isn't here?
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    // HACKHACK
    // Since UIApplication.sharedApplication().statusBarOrientation has been deprecated.
    // For now assume interfaceOrientation and device orientation are the same thing.
    // Couldn't get UIDevice.currentDevice().orientation to work even if I wrapped with begin/endGeneratingDeviceOrientationNotifications
    @objc class func getInterfaceOrientation() -> UIInterfaceOrientation
    {
        let screenSize : CGSize = UIScreen.main.bounds.size
        return screenSize.width < screenSize.height ? UIInterfaceOrientation.portrait : UIInterfaceOrientation.landscapeLeft
    }

    fileprivate func InitializeLayout()
    {
        self.forwardingView = ForwardingView(frame: CGRect.zero, viewController: self)
        self.view.addSubview(self.forwardingView)

        self.bannerView = self.createBanner()
        for button in self.bannerView!.buttons {
            button.addTarget(self, action: #selector(KeyboardViewController.didTapSuggestionButton(_:)), for: [.touchUpInside, .touchUpOutside, .touchDragOutside])
            button.addTarget(self, action: #selector(KeyboardViewController.didTTouchDownSuggestionButton(_:)), for: [.touchDown, .touchDragInside, .touchDragEnter])
            button.addTarget(self, action: #selector(KeyboardViewController.didTTouchExitDownSuggestionButton(_:)), for: [.touchDragExit, .touchCancel])
        }

        self.view.insertSubview(self.bannerView!, aboveSubview: self.forwardingView)

        initializePopUp()

    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        UserDefaults.standard.register(defaults: [
            kAutoCapitalization: true,
            kPeriodShortcut: true,
            kKeyboardClicks: false,
            kSmallLowercase: false,
            kActiveLanguageCode: vEnglishLanguageCode
            ])

        self.shiftState = .disabled
        self.currentMode = 0

        //sleep(30)
        
        self.currentInterfaceOrientation = KeyboardViewController.getInterfaceOrientation()

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

		InitializeLayout()

        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardViewController.defaultsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(KeyboardViewController.hideExpandView(_:)), name: NSNotification.Name(rawValue: "hideExpandViewNotification"), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        WordStore.CurrentWordStore().persistWords()
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    override func dismissKeyboard() {
        WordStore.CurrentWordStore().persistWords()
    }

    deinit {
        backspaceDelayTimer?.invalidate()
        backspaceRepeatTimer?.invalidate()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func defaultsChanged(_ notification: Notification) {
        self.updateKeyCaps(self.shiftState.uppercase())
    }
    
    // without this here kludge, the height constraint for the keyboard does not work for some reason
    @objc var kludge: UIView?
    @objc func setupKludge() {
        if self.kludge == nil {
            let kludge = UIView()
            self.view.addSubview(kludge)
            kludge.translatesAutoresizingMaskIntoConstraints = false
            kludge.isHidden = true
            
            let a = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
            let b = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
            let c = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
            let d = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
            self.view.addConstraints([a, b, c, d])
            
            self.kludge = kludge
        }
    }

    fileprivate func layoutHelper()
    {

        let proxy = textDocumentProxy
        self.keyboard = defaultKeyboard(proxy.keyboardType!)

        preKeyboardType = proxy.keyboardType!

        self.layout = type(of: self).layoutClass.init(model: self.keyboard, superview: self.forwardingView, layoutConstants: type(of: self).layoutConstants, darkMode: self.darkMode(), solidColorMode: self.solidColorMode())

        self.layout?.initialize()
        self.setMode(0)

        self.setupKludge()

        self.updateKeyCaps(self.shiftState.uppercase())
        self.setCapsIfNeeded()

        self.updateAppearances(self.darkMode())
        self.addInputTraitsObservers()

        self.constraintsAdded = true

    }

    /*
    BUG NOTE

    For some strange reason, a layout pass of the entire keyboard is triggered 
    whenever a popup shows up, if one of the following is done:

    a) The forwarding view uses an autoresizing mask.
    b) The forwarding view has constraints set anywhere other than init.

    On the other hand, setting (non-autoresizing) constraints or just setting the
    frame in layoutSubviews works perfectly fine.

    I don't really know what to make of this. Am I doing Autolayout wrong, is it
    a bug, or is it expected behavior? Perhaps this has to do with the fact that
    the view's frame is only ever explicitly modified when set directly in layoutSubviews,
    and not implicitly modified by various Autolayout constraints
    (even though it should really not be changing).
    */
    
    @objc var constraintsAdded: Bool = false
    @objc func setupLayout() {
        if !constraintsAdded {
            
            layoutHelper()

        }
    }
    
    // only available after frame becomes non-zero
    @objc func darkMode() -> Bool {
        let darkMode = { () -> Bool in
                return self.textDocumentProxy.keyboardAppearance == UIKeyboardAppearance.dark
        }()

        return darkMode
    }
    
    @objc func solidColorMode() -> Bool {
        return UIAccessibilityIsReduceTransparencyEnabled()
    }
    
    var lastLayoutBounds: CGRect?
	override func viewDidLayoutSubviews() {
		if view.bounds == CGRect.zero {
			return
		}
		
		self.setupLayout()
        
		let orientationSavvyBounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.heightForOrientation(self.currentInterfaceOrientation, withTopBanner: false))
		
		if (lastLayoutBounds != nil && lastLayoutBounds == orientationSavvyBounds) {
			// do nothing
		}
		else {
            let uppercase = self.shiftState.uppercase()
			let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
			
			self.forwardingView.frame = orientationSavvyBounds
			self.layout?.layoutKeys(self.currentMode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
			self.lastLayoutBounds = orientationSavvyBounds
			self.setupKeys()
		}
		
		self.bannerView?.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: metric("topBanner"))
		
		self.bannerView?.isHidden = textDocumentProxy.keyboardType == UIKeyboardType.numberPad || textDocumentProxy.keyboardType == UIKeyboardType.decimalPad

		self.forwardingView.frame.origin = CGPoint(x: 0, y: self.view.bounds.height - self.forwardingView.bounds.height)
		
	}
	
    override func loadView() {
        super.loadView()
		
        self.bannerView = self.createBanner()
        self.view.insertSubview(self.bannerView!, belowSubview: self.forwardingView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.bannerView?.isHidden = false
        self.keyboardHeight = self.heightForOrientation(self.currentInterfaceOrientation, withTopBanner: true)
    }
	
    @objc var currentInterfaceOrientation : UIInterfaceOrientation
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false

        self.layout?.rasterizeKeys(true)

        self.keyboardHeight = self.heightForOrientation(toInterfaceOrientation, withTopBanner: true)
        self.currentInterfaceOrientation = toInterfaceOrientation
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.layout?.rasterizeKeys(false)
    }
	

    // If the char we got was one of the selections from pressing the keyboard select button then don't insert it into the text document.
    // Instead take the appropriate action.
    // For now, huge hack to decide that that's what we should do.
    // Returns true if action was taken, else false indicating the caller can treat the text as typed and take action like inserting into the buffer.
    //
    // TODO: The globe button stays highlighted even though we're done.
    @objc func HandleKeyboardSelection(_ selection : String) -> Bool
    {
        if selection == SpecialUnicodeSymbols.NextKeyboardSymbol {

            self.advanceTapped()
            return true

        } else if selection == SpecialUnicodeSymbols.GearSymbol {

            self.toggleSettings()
            return true

        } else if selection.characters.count == 2 {
            // switch language AND keyboard layout
            ChangeKeyboardLanguage(selection)
            return true
        }

        return false
    }

    @objc func ChangeKeyboardLanguage(_ languageCode: String)
    {
        UserDefaults.standard.setValue(languageCode, forKey: kActiveLanguageCode)

        self.RebootKeyboard()
    }

    fileprivate func RebootKeyboard()
    {
        WordStore.CurrentWordStore().ResetContext()

        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false

        self.layout?.rasterizeKeys(true)
        self.forwardingView.removeSubviews()

        self.keyboardHeight = self.heightForOrientation(self.currentInterfaceOrientation, withTopBanner: true)

        self.constraintsAdded = false
        self.setupLayout()
    }

    fileprivate func tearDownSubViews() {
        self.forwardingView?.removeFromSuperview()
        self.forwardingView = nil
        
        self.bannerView?.removeFromSuperview()
        self.bannerView = nil

        self.kludge?.removeFromSuperview()
        self.kludge = nil

        self.button.removeFromSuperview()
        self.viewLongPopUp.removeFromSuperview()

        self.constraintsAdded = false
    }

	@objc func hideExpandView(_ notification: Notification)
	{
		
        if (notification as NSNotification).userInfo != nil {

            if let title = (notification as NSNotification).userInfo!["text"] as? String {

                if !HandleKeyboardSelection(title) {

                    InsertText(CasedString(title, shiftState: self.shiftState))
                }

                self.setCapsIfNeeded()
            }
		}
		
        if !self.forwardingView.isLongPressEnable {

            self.view.bringSubview(toFront: self.bannerView!)
		}

		viewLongPopUp.isHidden = true

	}

    @objc func heightForOrientation(_ orientation: UIInterfaceOrientation, withTopBanner: Bool) -> CGFloat {

        let actualScreenWidth = (UIScreen.main.nativeBounds.size.width /
            UIScreen.main.nativeScale)

        let actualScreenHeight = (UIScreen.main.nativeBounds.size.height / UIScreen.main.nativeScale)

        let canonicalPortraitHeight = CGFloat(orientation.isPortrait && actualScreenWidth >= 400 ? 226 : 216)

        let canonicalLandscapeHeight = CGFloat(orientation.isLandscape && actualScreenHeight >= 800 ? 330 : 162)


        let topBannerHeight = (withTopBanner && textDocumentProxy.keyboardType != UIKeyboardType.numberPad && textDocumentProxy.keyboardType != UIKeyboardType.decimalPad)
            ? metric("topBanner") : 0

        return CGFloat(orientation.isPortrait ? canonicalPortraitHeight + topBannerHeight : canonicalLandscapeHeight + topBannerHeight)
        
    }

    @objc func setupKeys() {
        if self.layout == nil {
            return
        }
		
        for page in keyboard.pages {
            for rowKeys in page.rows { // TODO: quick hack
                for key in rowKeys {
                    if let keyView = self.layout?.viewForKey(key) {
                        keyView.removeTarget(nil, action: nil, for: UIControlEvents.allEvents)
						
                        switch key.type {

                        case Key.KeyType.keyboardChange:
                            // Long press on keyboard change shows popup with options to change layout or move to next
                            // installed keyboard
                            keyView.addTarget(self, action: #selector(KeyboardViewController.keyCharLongPressed(_:)), for: .touchDownRepeat)

                            // Single tap on keyboard change key just advances to next installed keyboard
                            keyView.addTarget(self, action: #selector(KeyboardViewController.advanceTapped), for: .touchUpInside)

                        case Key.KeyType.backspace:
                            let cancelEvents: UIControlEvents = [UIControlEvents.touchUpInside, UIControlEvents.touchUpInside, UIControlEvents.touchDragExit, UIControlEvents.touchUpOutside, UIControlEvents.touchCancel, UIControlEvents.touchDragOutside]
                            
                            keyView.addTarget(self, action: #selector(KeyboardViewController.backspaceDown(_:)), for: .touchDown)
                            keyView.addTarget(self, action: #selector(KeyboardViewController.backspaceUp(_:)), for: cancelEvents)

                        case Key.KeyType.shift:
                            keyView.addTarget(self, action: #selector(KeyboardViewController.shiftDown(_:)), for: .touchDown)
                            keyView.addTarget(self, action: #selector(KeyboardViewController.shiftUp(_:)), for: .touchUpInside)
                            keyView.addTarget(self, action: #selector(KeyboardViewController.shiftDoubleTapped(_:)), for: .touchDownRepeat)

                        case Key.KeyType.modeChange:
                            keyView.addTarget(self, action: #selector(KeyboardViewController.modeChangeTapped(_:)), for: .touchDown)

                        default:
                            break
                        }
                        
                        if key.isCharacter {
                            if UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad {
                                keyView.addTarget(self, action: #selector(KeyboardViewController.showPopup(_:)), for: [.touchDown, .touchDragInside, .touchDragEnter])



                                keyView.addTarget(keyView, action: #selector(KeyboardKey.hidePopup), for: [.touchDragExit, .touchCancel])
                                keyView.addTarget(self, action: #selector(KeyboardViewController.hidePopupDelay(_:)), for: [.touchUpInside, .touchUpOutside, .touchDragOutside])
                            }
							
							keyView.addTarget(self, action: #selector(KeyboardViewController.keyCharLongPressed(_:)), for: .touchDownRepeat)
                        }
                        
                        if key.hasOutput {
                            keyView.addTarget(self, action: #selector(KeyboardViewController.keyPressedHelper(_:)), for: .touchUpInside)
                        }
                        
                        if key.type != Key.KeyType.shift && key.type != Key.KeyType.modeChange {
                            
                            keyView.addTarget(self, action: #selector(KeyboardViewController.highlightKey(_:)), for: [.touchDown, .touchDragInside, .touchDragEnter])
                            keyView.addTarget(self, action: #selector(KeyboardViewController.unHighlightKey(_:)), for: [.touchUpInside, .touchUpOutside, .touchDragOutside,  .touchDragExit, .touchCancel])
                        }
                        
                        keyView.addTarget(self, action: #selector(KeyboardViewController.playKeySound), for: .touchDown)
                    }
                }
            }
        }
    }
    
    /////////////////
    // POPUP DELAY //
    /////////////////
    
    @objc var keyWithDelayedPopup: KeyboardKey?
    @objc var popupDelayTimer: Timer?

    @objc func showPopup(_ sender: KeyboardKey) {
        if sender == self.keyWithDelayedPopup {
            self.popupDelayTimer?.invalidate()
        }

		let proxy = textDocumentProxy
        if proxy.keyboardType != UIKeyboardType.numberPad && proxy.keyboardType != UIKeyboardType.decimalPad {

            // Push the top row of suggestion buttons back so we can draw the popup over the top
            self.view.sendSubview(toBack: self.bannerView!)

            sender.showPopup()
		}
    }
	
    @objc func hidePopupDelay(_ sender: KeyboardKey) {
        self.popupDelayTimer?.invalidate()
        
        if sender != self.keyWithDelayedPopup {
            self.keyWithDelayedPopup?.hidePopup()
            self.keyWithDelayedPopup = sender
        }
        
        if sender.popup != nil {
            self.popupDelayTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(KeyboardViewController.hidePopupCallback), userInfo: nil, repeats: false)
        }
    }
    
    @objc func hidePopupCallback() {
        self.keyWithDelayedPopup?.hidePopup()
        self.keyWithDelayedPopup = nil
        self.popupDelayTimer = nil

        // Restore the top row of suggestion buttons.
        // We had to push them to the back so the key popup could draw in that space.
        self.view.bringSubview(toFront: self.bannerView!)

    }

    /////////////////////
    // POPUP DELAY END //
    /////////////////////
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    // TODO: this is currently not working as intended; only called when selection changed -- iOS bug

	override func textDidChange(_ textInput: UITextInput?) {
		self.contextChanged()
		
		let proxy = textDocumentProxy 
		
		keyboard_type = textDocumentProxy.keyboardType!
		
		DispatchQueue.main.async(execute: {
			if proxy.keyboardType! != self.preKeyboardType
			{
                self.RebootKeyboard()
			}
			
		})
	}
	
    @objc func contextChanged() {
        self.setCapsIfNeeded()
        self.autoPeriodState = .noSpace
        WordStore.CurrentWordStore().ResetContext()
    }
	
    @objc func setHeight(_ height: CGFloat) {
        if self.heightConstraint == nil {
            self.heightConstraint = NSLayoutConstraint(
                item:self.view,
                attribute:NSLayoutAttribute.height,
                relatedBy:NSLayoutRelation.equal,
                toItem:nil,
                attribute:NSLayoutAttribute.notAnAttribute,
                multiplier:0,
                constant:height)
            self.heightConstraint!.priority = UILayoutPriority(rawValue: 999)
            
            self.view.addConstraint(self.heightConstraint!) // TODO: what if view already has constraint added?
        }
        else {
            self.heightConstraint?.constant = height
        }
    }
    
    @objc func updateAppearances(_ appearanceIsDark: Bool) {
        self.layout?.solidColorMode = self.solidColorMode()
        self.layout?.darkMode = appearanceIsDark
        self.layout?.updateKeyAppearance()
        
        self.bannerView?.darkMode = appearanceIsDark
    }
    
    @objc func highlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = true
    }
    
    @objc func unHighlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = false
    }
    
    @objc func keyPressedHelper(_ sender: KeyboardKey) {
        if let model = self.layout?.keyForView(sender) {
            self.keyPressed(model)

            // auto exit from special char subkeyboard
            if model.type == Key.KeyType.space || model.type == Key.KeyType.return
                || model.lowercaseOutput == "'"
                || model.type == Key.KeyType.character {

                    self.currentMode = 0
            }

            // auto period on double space
            self.handleAutoPeriod(model)

            // TODO: reset context
        }
        
        self.setCapsIfNeeded()

    }
	
    func handleAutoPeriod(_ key: Key) {
        if !UserDefaults.standard.bool(forKey: kPeriodShortcut) {
            return
        }
		
        if self.autoPeriodState == .firstSpace {
            if key.type != Key.KeyType.space {
                self.autoPeriodState = .noSpace
                return
            }
			
            let charactersAreInCorrectState = { () -> Bool in
                let previousContext = self.textDocumentProxy.documentContextBeforeInput
				
                if previousContext == nil || previousContext!.characters.count < 3 {
                    return false
                }
				
                var index = previousContext!.endIndex
				
                index = previousContext!.index(before: index)
                if previousContext![index] != " " {
                    return false
                }
                
                index = previousContext!.index(before: index)
                if previousContext![index] != " " {
                    return false
                }
                
                index = previousContext!.index(before: index)
                let char = previousContext![index]
                if characterIsWhitespace(char) || characterIsPunctuation(char) || char == "," {
                    return false
                }
                
                return true
            }()
            
            if charactersAreInCorrectState {
                self.textDocumentProxy.deleteBackward()
                self.textDocumentProxy.deleteBackward()
                InsertText(".")
                InsertText(" ")
            }
            
            self.autoPeriodState = .noSpace
        }
        else {
            if key.type == Key.KeyType.space {
                self.autoPeriodState = .firstSpace
            }
        }
    }
    
    @objc func cancelBackspaceTimers() {
        self.backspaceDelayTimer?.invalidate()
        self.backspaceRepeatTimer?.invalidate()
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = nil
    }
    
    @objc func backspaceDown(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()
        
        self.textDocumentProxy.deleteBackward()
        WordStore.CurrentWordStore().DeleteBackward()

        self.setCapsIfNeeded()
        
        // trigger for subsequent deletes
        self.backspaceDelayTimer = Timer.scheduledTimer(timeInterval: backspaceDelay - backspaceRepeat, target: self, selector: #selector(KeyboardViewController.backspaceDelayCallback), userInfo: nil, repeats: false)
    }
    
    @objc func backspaceUp(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()
    }
    
    @objc func backspaceDelayCallback() {
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = Timer.scheduledTimer(timeInterval: backspaceRepeat, target: self, selector: #selector(KeyboardViewController.backspaceRepeatCallback), userInfo: nil, repeats: true)
    }
    
    @objc func backspaceRepeatCallback() {
        self.playKeySound()
        
        self.textDocumentProxy.deleteBackward()
        
        self.setCapsIfNeeded()
    }
    
    @objc func shiftDown(_ sender: KeyboardKey) {
        self.shiftStartingState = self.shiftState
        
        if let shiftStartingState = self.shiftStartingState {
            if shiftStartingState.uppercase() {
                // handled by shiftUp
                return
            }
            else {
                self.shiftState = (self.shiftState == .disabled) ? .enabled : .disabled
                (sender.shape as? ShiftShape)?.withLock = false
            }
        }
    }
    
    @objc func shiftUp(_ sender: KeyboardKey) {
        if self.shiftWasMultitapped {
            // do nothing
        }
        else {
            if let shiftStartingState = self.shiftStartingState {
                if !shiftStartingState.uppercase() {
                    // handled by shiftDown
                }
                else {
                    self.shiftState = (self.shiftState == .disabled) ? .enabled : .disabled
                    (sender.shape as? ShiftShape)?.withLock = false
                }
            }
        }

        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
    }
    
    @objc func shiftDoubleTapped(_ sender: KeyboardKey) {
        self.shiftWasMultitapped = true
        self.shiftState = (self.shiftState == .locked) ? .disabled : .locked
    }
    
    @objc func updateKeyCaps(_ uppercase: Bool) {
        let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
        self.layout?.updateKeyCaps(false, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
    }
    
    @objc func modeChangeTapped(_ sender: KeyboardKey) {
        if let toMode = self.layout?.viewToModel[sender]?.toMode {
            self.currentMode = toMode
        }
    }
    
    @objc func setMode(_ mode: Int) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        let uppercase = self.shiftState.uppercase()
        let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
        self.layout?.layoutKeys(mode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
        
        self.setupKeys()
    }
    
    @objc func advanceTapped() {
        WordStore.CurrentWordStore().persistWords()

        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        self.advanceToNextInputMode()
    }

    // Nice tutorial on navigation controllers and view controllers:
    // http://makeapppie.com/2014/09/15/swift-swift-programmatic-navigation-view-controllers-in-swift/
    @objc var nav: CustomNavigationController? = nil

    @IBAction func toggleSettings() {
        self.nav = CustomNavigationController(parent: self)
        self.present(nav!, animated: false, completion: nil)

        let vc = LanguageSettingsViewController(languageDefinitions: LanguageDefinitions.Singleton(), navController: nav)
        self.nav?.pushViewController(vc, animated: true)
    }
    
    @objc func setCapsIfNeeded() /* -> Bool */{
        if self.shouldAutoCapitalize() {
            self.shiftState = (self.shiftState == .locked) ? .locked : .enabled
            
            return // true
        }
        else {
            self.shiftState = (self.shiftState == .locked) ? .locked : .disabled
            
            return // false
        }
    }
    
    @objc func shouldAutoCapitalize() -> Bool {
        if !UserDefaults.standard.bool(forKey: kAutoCapitalization) {
            return false
        }
        
        let documentProxy = self.textDocumentProxy
        if let autocapitalization = documentProxy.autocapitalizationType {

            switch autocapitalization {
            case .none:
                return false

            case .words:
                if let beforeContext = documentProxy.documentContextBeforeInput {
                    let previousCharacter = beforeContext[beforeContext.characters.index(before: beforeContext.endIndex)]
                    return characterIsWhitespace(previousCharacter)
                }

                return true

            case .sentences:
                if let beforeContext = documentProxy.documentContextBeforeInput {
                    let offset = min(3, beforeContext.characters.count)
                    var index = beforeContext.endIndex
                    
                    for i in 0 ..< offset {
                        index = beforeContext.index(before: index)
                        let char = beforeContext[index]
                        
                        if characterIsPunctuation(char) {
                            return i > 0 //punctuation with at least one space after it
                        }
                        else {
                            if !characterIsWhitespace(char) {
                                return false //hit a foreign character before getting to 3 spaces
                            }
                            else if characterIsNewline(char) {
                                return true //hit start of line
                            }
                        }
                    }
                }

                return true

            case .allCharacters:
                return true
            }
        }
        else {
            return false
        }
        
    }
    
    // This only works if full access is enabled.
    // Current over-arching goal is to implement a kbd that does not require full access so we can't play sound.
    // But leave this as a stub in case Apple relaxes what you can do as a kbd later.
    @objc func playKeySound() {
    }
    
    //////////////////////////////////////
    // MOST COMMONLY EXTENDABLE METHODS //
    //////////////////////////////////////
    
    @objc class var layoutClass: KeyboardLayout.Type { get { return KeyboardLayout.self }}
    @objc class var layoutConstants: LayoutConstants.Type { get { return LayoutConstants.self }}

    @objc func InsertText(_ insertChar: String)
    {
        self.textDocumentProxy.insertText(insertChar)

        WordStore.CurrentWordStore().recordChar(insertChar)

        self.bannerView?.LabelSuggestionButtons(WordStore.CurrentWordStore().getSuggestions(3))
    }
    
    func keyPressed(_ key: Key) {
        InsertText(key.outputForCase(self.shiftState.uppercase()))
    }
    
    // a banner that sits in the empty space on top of the keyboard
    @objc func createBanner() -> SuggestionView {
        // note that dark mode is not yet valid here, so we just put false for clarity
        return SuggestionView(darkMode: false, solidColorMode: self.solidColorMode())
    }
    
	// MARK: Added methods for extra features
	@objc func initializePopUp()
	{
        button.initializePopup(self.forwardingView)
		self.view.insertSubview(self.button, aboveSubview: self.forwardingView)

        viewLongPopUp.isHidden = true
	}

	@objc func didTTouchExitDownSuggestionButton(_ sender: AnyObject?)
	{
        if let button = sender as? UIButton {
            button.backgroundColor = UIColor(red:0.68, green:0.71, blue:0.74, alpha:1)
            button.setTitleColor(UIColor.white, for: UIControlState())
        }
	}
	
	@objc func didTTouchDownSuggestionButton(_ sender: AnyObject?)
	{
        if let button = sender as? UIButton {

            if let btn_title = button.title(for: UIControlState()) , !stringIsWhitespace(btn_title)  {
                self.bannerView?.showPressedAppearance(button)
            }
        }
    }
	
	@objc func didTapSuggestionButton(_ sender: AnyObject?)
	{
        
		self.currentMode = 0
		
		self.autoPeriodState = .firstSpace

        onSuggestionTap(sender)

        self.bannerView?.updateAppearance()
		
		self.setCapsIfNeeded()
		
	}
	
    @objc func onSuggestionTap(_ sender: AnyObject?)
    {
        if let button = sender as? UIButton {

            let title = TrimWhiteSpace(button.title(for: UIControlState()))

            if title == ""
            {
                return
            }

            // Tapping on the suggestion replaces the word we've been inserting into the text buffer
            for _ in 0 ..< WordStore.CurrentWordStore().CurrentWord.characters.count {
                self.textDocumentProxy.deleteBackward()
            }

            let insertionWord =
                self.shiftState == .enabled ? title.capitalized
                    : self.shiftState == .locked ? title.uppercased()
                    : title

            InsertText(insertionWord + " ")

            // Update the last used datetime for this word
            // REVIEW insert the case-corrected insertionWord? Or just the value shown on the suggestion key?
            WordStore.CurrentWordStore().recordWord(title)
        }
    }

    @objc func getLongPresses(_ sender: KeyboardKey) -> [String]?
    {
        return self.layout?.viewToModel[sender]?.getLongPressesForShiftState(self.shiftState)
    }

    @objc func longPressEnabledKey(_ sender : KeyboardKey?) -> Bool
    {
        if sender == nil {
            return false
        }

        let longPresses = self.getLongPresses(sender!)
        return longPresses != nil && longPresses!.count > 0 && longPresses![0] != ""
    }

    @objc func keyCharLongPressed(_ sender: KeyboardKey)
    {
        if sender.tag == LongPressActivated
        {
            sender.hidePopup()

            if let arrOptions = self.getLongPresses(sender) , arrOptions.count > 0 && arrOptions[0] != "" {

                var offsetY : CGFloat = 9

                if self.currentInterfaceOrientation == UIInterfaceOrientation.landscapeLeft || self.currentInterfaceOrientation == UIInterfaceOrientation.landscapeRight {
                    offsetY = 3
                }
                else {
                    switch  KeyboardViewController.getDeviceType() {
                    case TTDeviceType.ttDeviceTypeIPhone4, TTDeviceType.ttDeviceTypeIPhone5:
                        offsetY = 9

                    case TTDeviceType.ttDeviceTypeIPhone6:
                        offsetY = 13

                    case TTDeviceType.ttDeviceTypeIPhone6p:
                        offsetY = 16
                    }
                }

                self.button.removeFromSuperview()

                self.button.frame = CGRect(x: sender.frame.origin.x, y: sender.frame.origin.y + sender.frame.size.height - offsetY, width: sender.frame.size.width, height: sender.frame.size.height)

                self.view.insertSubview(self.button, aboveSubview: self.forwardingView)

                let isTopRow:Bool = self.layout?.keyForView(sender)?.isTopRow ?? false
                self.viewLongPopUp = self.button.showLongPopUpOptions(isTopRow)
                self.button.input = sender.text
                self.button.isHidden = true
                self.button.inputOptions = arrOptions
                self.viewLongPopUp.isHidden = false

                for anyView in self.view.subviews
                {
                    if anyView is CYRKeyboardButtonView
                    {
                        anyView.removeFromSuperview()
                    }
                }

                self.viewLongPopUp.isUserInteractionEnabled = false;

                button.setupInputOptionsConfiguration(with: forwardingView)
                self.view.insertSubview(self.viewLongPopUp, aboveSubview: self.forwardingView)
                self.forwardingView.isLongPressEnable = true
                self.view.bringSubview(toFront: self.viewLongPopUp)
                
                sender.tag = 0
                
            }
        }
    }
	
	class func getDeviceType()->TTDeviceType
	{
        var height = UIScreen.main.bounds.size.height
		
		if UIScreen.main.bounds.size.height < UIScreen.main.bounds.size.width
		{
			height = UIScreen.main.bounds.size.width
		}

        var deviceType = TTDeviceType.ttDeviceTypeIPhone5

		switch (height) {
		case 480:
			deviceType = TTDeviceType.ttDeviceTypeIPhone4
			break
			
		case 568:
			deviceType = TTDeviceType.ttDeviceTypeIPhone5
			break
            
		case 667:
			deviceType = TTDeviceType.ttDeviceTypeIPhone6
			break
            
		case 736:
			deviceType = TTDeviceType.ttDeviceTypeIPhone6p
			break
			
		default:
			break
		}
		
		return deviceType
		
	}
    
}
