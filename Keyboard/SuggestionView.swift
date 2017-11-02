//
//  SuggestionView.swift
// The view to house the row of suggestion buttons across the top of the keyboard

import UIKit

class SuggestionView: LightDarkView  {

    @objc var btn1 : UIButton = UIButton()
    @objc var btn2 : UIButton = UIButton()
    @objc var btn3 : UIButton = UIButton()

    @objc var buttons: [UIButton] {
        get {
            return [self.btn1, self.btn2, self.btn3]
        }
    }

    override func updateAppearance() {
        for button in self.buttons {
            showUnpressedAppearance(button)
        }
    }

    @objc let bluishGray = UIColor(red:0.68, green:0.71, blue:0.74, alpha:1)
    @objc let whitish = UIColor(red:0.92, green:0.93, blue:0.94, alpha:1)

    @objc func showPressedAppearance(_ button: UIButton)
    {
        button.backgroundColor = whitish
        button.setTitleColor(UIColor.black, for: UIControlState())
    }

    @objc func showUnpressedAppearance(_ button: UIButton)
    {
        button.backgroundColor = bluishGray
        button.setTitleColor(UIColor.white, for: UIControlState())
    }

    @objc func LabelSuggestionButtons(_ labels: [String])
    {
        self.btn1.setTitle(labels.count > 0 ? labels[0] : "", for: UIControlState())
        self.btn2.setTitle(labels.count > 1 ? labels[1] : "", for: UIControlState())
        self.btn3.setTitle(labels.count > 2 ? labels[2] : "", for: UIControlState())
    }

}
