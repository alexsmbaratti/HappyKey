//
//  ForwardingView.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit
let LongPressActivated = 888

class ForwardingView: UIView, UIGestureRecognizerDelegate {
    
    @objc var touchToView: [UITouch:UIView]
	
	@objc var isLongPressEnable = false
	@objc var isLongPressKeyPress = false
	
	@objc var currentMode: Int = 0
	var keyboard_type: UIKeyboardType?

    @objc var viewController: KeyboardViewController?  = nil
	
    fileprivate func MakeLongPressGesturesRecognizer()
    {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(ForwardingView.handleLongGesture(_:)))
        
        gesture.minimumPressDuration = 0.5
        gesture.delegate = self
        gesture.cancelsTouchesInView = false
        self.addGestureRecognizer(gesture)
    }
    
    override init(frame: CGRect) {
        self.touchToView = [:]
        
        super.init(frame: frame)
        
        self.contentMode = UIView.ContentMode.redraw
        self.isMultipleTouchEnabled = true
        self.isUserInteractionEnabled = true
        self.isOpaque = false
		
        self.MakeLongPressGesturesRecognizer()
    }

    @objc convenience init(frame: CGRect, viewController: KeyboardViewController) {
        self.init(frame: frame)

        self.viewController = viewController
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    // Why have this useless drawRect? Well, if we just set the backgroundColor to clearColor,
    // then some weird optimization happens on UIKit's side where tapping down on a transparent pixel will
    // not actually recognize the touch. Having a manual drawRect fixes this behavior, even though it doesn't
    // actually do anything.
    override func draw(_ rect: CGRect) {}
    
    override func hitTest(_ point: CGPoint, with event: UIEvent!) -> UIView? {
        if self.isHidden || self.alpha == 0 || !self.isUserInteractionEnabled {
            return nil
        }
        else {
            return self.bounds.contains(point) ? self : nil
        }
    }
    
    @objc func handleControl(_ view: UIView?, controlEvent: UIControl.Event) {
        if let control = view as? UIControl {
            let targets = control.allTargets
            for target in targets {
                if let actions = control.actions(forTarget: target, forControlEvent: controlEvent) {
                    for action in actions {
                        let selector = Selector(action)
                        control.sendAction(selector, to: target, for: nil)
                        
                    }
                }
            }
        }
    }

	@IBAction func handleLongGesture(_ longPress: UIGestureRecognizer)
	{
		if (longPress.state == UIGestureRecognizer.State.ended)
		{
			
			let position = longPress.location(in: self)
			let view = findNearestView(position)
			
			if view is KeyboardKey
			{
				NotificationCenter.default.post(name: Notification.Name(rawValue: "hideExpandViewNotification"), object: nil)
			}
			
			isLongPressEnable = false
			
			isLongPressKeyPress = true
			
			if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
			{
                (view as? KeyboardKey)?.isHighlighted = false
			}
			
		}
        else if (longPress.state == UIGestureRecognizer.State.began)
        {
            
            isLongPressEnable = true
            
            let position = longPress.location(in: self)
            let view = findNearestView(position)
            
            if let v = view as? KeyboardKey {
                if self.isLongPressEnableKey(v)
                {
                    view!.tag = LongPressActivated

                    self.handleControl(view, controlEvent: .touchDownRepeat)
                }
            }
        }
	}

	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
	{
		if gestureRecognizer is UILongPressGestureRecognizer
		{
			if (gestureRecognizer.state == UIGestureRecognizer.State.possible)
			{
				let position = touch.location(in: self)
                return self.isLongPressEnableKey(findNearestView(position) as? KeyboardKey)
			}
			else if (gestureRecognizer.state == UIGestureRecognizer.State.ended)
			{
				let position = gestureRecognizer.location(in: self)
                return self.isLongPressEnableKey(findNearestView(position) as? KeyboardKey)
			}
		}
		else
		{
			return true
		}
		return false
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
	{
		return true
	}
	
    // TODO: there's a bit of "stickiness" to Apple's implementation
    @objc func findNearestView(_ position: CGPoint) -> UIView? {

        if !self.bounds.contains(position) {
            return nil
        }

        var closest: (UIView, CGFloat)? = nil
        
        for view in self.subviews {
            
            if view.isHidden {
                continue
            }

            let distance = distanceBetween(view.frame, point: position)
            
            if closest != nil {
                if distance < closest!.1 {
                    closest = (view, distance)
                }
            }
            else {
                closest = (view, distance)
            }
            
        }

        return closest?.0
    }

    @objc func removeSubviews()
    {
        for view in self.subviews {
            view.removeFromSuperview()
        }
    }

    // reset tracked views without cancelling current touch
    @objc func resetTrackedViews() {
        for view in self.touchToView.values {
            self.handleControl(view, controlEvent: .touchCancel)
        }
        self.touchToView.removeAll(keepingCapacity: true)
    }
	
	@objc func resetPopUpViews() {
		for view in self.touchToView.values {
			
			(view as? KeyboardKey)?.hidePopup()
		}
	}
	
    @objc func ownView(_ newTouch: UITouch, viewToOwn: UIView?) -> Bool {
        var foundView = false
        
        if viewToOwn != nil {
            for (touch, view) in self.touchToView {
                if viewToOwn == view {
                    if touch == newTouch {
                        break
                    }
                    else {
                        self.touchToView[touch] = nil
                        foundView = true
                    }
                    break
                }
            }
        }
        
        self.touchToView[newTouch] = viewToOwn
        return foundView
    }
    
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

		for touch in touches {
			let position = touch.location(in: self)
			let view = findNearestView(position)
			
			let viewChangedOwnership = self.ownView(touch, viewToOwn: view)
			
			if(isLongPressEnable == true)
			{
				if view != nil && !viewChangedOwnership
				{
                    self.handleControl(view, controlEvent: .touchDown)
				}
				
				NotificationCenter.default.post(name: Notification.Name(rawValue: "hideExpandViewNotification"), object: nil)
				isLongPressEnable = false
				
				if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
				{
                    (view as? KeyboardKey)?.isHighlighted = false
				}
				
			}
			else
			{
				if !viewChangedOwnership {
					self.handleControl(view, controlEvent: .touchDown)
					
					if touch.tapCount > 1 {
						// two events, I think this is the correct behavior but I have not tested with an actual UIControl
						self.handleControl(view, controlEvent: .touchDownRepeat)
					}
				}
                else {
                    NSLog("Oops")

                }
			}
			
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		for touch in touches
		{
			let position = touch.location(in: self)
			
			if isLongPressEnable
			{
                if let expandedButtonView = self.getCYRView() {

                    expandedButtonView.updateSelectedInputIndex(for: position)
				}
			}
			else
			{
				let oldView = self.touchToView[touch]
				let newView = findNearestView(position)
				
				if oldView != newView
				{
					self.handleControl(oldView, controlEvent: .touchDragExit)
					
					let viewChangedOwnership = self.ownView(touch, viewToOwn: newView)
					
					if !viewChangedOwnership
					{
						self.handleControl(newView, controlEvent: .touchDragEnter)
					}
					else
					{
						self.handleControl(newView, controlEvent: .touchDragInside)
					}
				}
				else
				{
					self.handleControl(oldView, controlEvent: .touchDragInside)
				}
			}
		}
	}
    
    override func touchesEnded(_ touches: Set<UITouch>?, with event: UIEvent?) {
        if let allTouches = touches {
            for touch in allTouches {
                let view = self.touchToView[touch]
                
                let touchPosition = touch.location(in: self)
                
                if(isLongPressKeyPress == true)
                {
                    if let expandedButtonView : CYRKeyboardButtonView = self.getCYRView() {
                        if expandedButtonView.selectedInputIndex != NSNotFound {

                            if let inputOption = self.getCYRButton().inputOptions[expandedButtonView.selectedInputIndex] as? String {

                                self.resetPopUpViews()

                                NotificationCenter.default.post(name: Notification.Name(rawValue: "hideExpandViewNotification"), object: nil, userInfo: ["text":inputOption])
                            }
                        }
                    }
                    
                    isLongPressKeyPress = false
                    
                    if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
                    {
                        (view as? KeyboardKey)?.isHighlighted = false
                    }
                    
                }
                else
                {
                    self.handleControl(view, controlEvent: self.bounds.contains(touchPosition) ? .touchUpInside : .touchCancel)
                }
                
                self.touchToView[touch] = nil
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        if let allTouches = touches {
            for touch in allTouches {
                
                let view = self.touchToView[touch]
                
                self.handleControl(view, controlEvent: .touchCancel)
                
                self.touchToView[touch] = nil
            }
        }
    }

    @objc func isLongPressEnableKey(_ key: KeyboardKey?) -> Bool {

        // REVIEW We need to determine whether the key that got pressed has a list of long presses for the current state
        // but the only way to get that is to go through a portal to the view controller. This seems unnecessarily convoluted.

        if self.viewController != nil && self.viewController!.longPressEnabledKey(key) {
            // Assume for now that decimal pad and number pad keys can't do long press.
            if self.currentMode == 0
            {
                return keyboard_type != UIKeyboardType.decimalPad && keyboard_type != UIKeyboardType.numberPad
            }
        }

        return false

    }

	
	@objc func getCYRView() -> CYRKeyboardButtonView!
	{
        for anyView in self.superview!.subviews {

            if anyView is CYRKeyboardButtonView {

                return anyView as! CYRKeyboardButtonView
            }
        }

		return nil
	}
	
	@objc func getCYRButton() -> CYRKeyboardButton!
	{
        for anyView in self.superview!.subviews {

            if anyView is CYRKeyboardButton {

                return anyView as! CYRKeyboardButton
            }
        }

		return nil
	}
	
}
