//
//  Utilities.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/22/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import Foundation
import UIKit

var profile: ((_ id: String) -> Double?) = {
    var counterForName = Dictionary<String, Double>()
    var isOpen = Dictionary<String, Double>()
    
    return { (id: String) -> Double? in
        if let startTime = isOpen[id] {
            let diff = CACurrentMediaTime() - startTime
            if let currentCount = counterForName[id] {
                counterForName[id] = (currentCount + diff)
            }
            else {
                counterForName[id] = diff
            }
            
            isOpen[id] = nil
        }
        else {
            isOpen[id] = CACurrentMediaTime()
        }
        
        return counterForName[id]
    }
}()

// Remove trailing and leading white space.
// Treat nil as equivalent to the empty string.
func TrimWhiteSpace(_ x : String?) -> String {
    return x == nil ? "" : x!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
}

func characterIsPunctuation(_ character: Character) -> Bool {
    return character == "." || character == "!" || character == "?"
}

func characterIsNewline(_ character: Character) -> Bool {
    return character == "\n" || character == "\r"
}

func characterIsWhitespace(_ character: Character) -> Bool {
    // there are others, but who cares
    return character == " " || character == "\n" || character == "\r" || character == "\t"
}

func stringIsWhitespace(_ str: String?) -> Bool {
    return TrimWhiteSpace(str) == ""
}

func isInitCaps(_ string: String) -> Bool
{
    return string.count > 0
        && ("A"..."Z").contains(string[string.startIndex])
}

// HACKHACK I need a locally defined class that I can get a reference to self for as a param to NSBundle()
class foo
{

}

// In the deployed app, JSON resources etc live in the main bundle but when running a unit test we're not running as the main bundle
func getBundle() -> Bundle {

#if UNIT_TESTS
    return NSBundle(forClass: foo.self)
#else
    return Bundle.main
#endif

}

func loadJSON(_ fileName: String?) -> NSDictionary?
{
    if let path = getBundle().path(forResource: fileName, ofType: "json")
    {
        if !FileManager().fileExists(atPath: path) {
            NSLog("File does not exist at \(path)")
            return nil
        }

        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path))
        {
            do {
                let JSON = try JSONSerialization.jsonObject(with: jsonData, options:JSONSerialization.ReadingOptions(rawValue: 0))

                return JSON as? NSDictionary
            }
            catch let JSONError as NSError {
                NSLog("JSONError exception\n\(JSONError)")
                return nil
            }
            catch {
                NSLog("Some other error occurred")
                return nil
            }
        }
    }
    
    return nil

}

func isOpenAccessGranted() -> Bool {
    #if FULLACCESS
        return (UIPasteboard.generalPasteboard().isKindOfClass(UIPasteboard))
    #else
        return true
    #endif
}

// http://stackoverflow.com/questions/3552108/finding-closest-object-to-cgpoint b/c I'm lazy
func distanceBetween(_ rect: CGRect, point: CGPoint) -> CGFloat {
    if rect.contains(point) {
        return 0
    }

    var closest = rect.origin

    if (rect.origin.x + rect.size.width < point.x) {
        closest.x += rect.size.width
    }
    else if (point.x > rect.origin.x) {
        closest.x = point.x
    }
    if (rect.origin.y + rect.size.height < point.y) {
        closest.y += rect.size.height
    }
    else if (point.y > rect.origin.y) {
        closest.y = point.y
    }

    let a = pow(Double(closest.y - point.y), 2)
    let b = pow(Double(closest.x - point.x), 2)
    return CGFloat(sqrt(a + b));
}

func CasedString(_ str : String, shiftState : ShiftState) -> String
{
    if shiftState == .enabled
    {
        return str.capitalized
    }
    else if shiftState == .locked
    {
        return str.uppercased()
    }
    else
    {
        return str
    }
}
