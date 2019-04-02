//
//  HappyKeyboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 9/24/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

/*
This is the demo keyboard. If you're implementing your own keyboard, simply follow the example here and then
set the name of your KeyboardViewController subclass in the Info.plist file.
*/

let kCatTypeEnabled = "kCatTypeEnabled"

class HappyKeyboard: KeyboardViewController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        UserDefaults.standard.register(defaults: [kCatTypeEnabled: true])
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func keyPressed(_ key: Key) {
        let textDocumentProxy = self.textDocumentProxy
        
        let keyOutput = key.outputForCase(self.shiftState.uppercase())
        
        if !UserDefaults.standard.bool(forKey: kCatTypeEnabled) {
            InsertText(keyOutput)
            return
        }
        
        if key.type == .character || key.type == .specialCharacter {
            let context = textDocumentProxy.documentContextBeforeInput
            if context != nil {
                if context!.count < 2 {
                    InsertText(keyOutput)
                    return
                }
                
                var index = context!.endIndex
              
                index = context!.index( before: index )
                if context?[index] != " " {
                    InsertText(keyOutput)
                    return
                }
                
                index = context!.index(before: index)
                if context?[index] == " " {
                    InsertText(keyOutput)
                    return
                }
                
                InsertText(keyOutput)
                return
            }
            else {
                InsertText(keyOutput)
                return
            }
        }
        else {
            InsertText(keyOutput)
            return
        }
        
    }
    
    override func setupKeys() {
        super.setupKeys()
    }
    
    override func createBanner() -> SuggestionView {
        return HappyKeyboardBanner(darkMode: false, solidColorMode: self.solidColorMode())
    }
    
}
