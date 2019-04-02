//
//  ViewController.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class HostingAppViewController: UIViewController {
    
    @IBOutlet var stats: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(HostingAppViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HostingAppViewController.keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChangeFrame:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HostingAppViewController.keyboardDidChangeFrame(_:)), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        
        // Animation Test
//        var imageNames = ["frame-000000.png", "frame-000001.png", "frame-000002.png", "frame-000003.png", "frame-000004.png", "frame-000005.png", "frame-000006.png", "frame-000007.png", "frame-000008.png", "frame-000009.png", "frame-000010.png", "frame-000011.png", "frame-000012.png", "frame-000013.png", "frame-000014.png", "frame-000015.png", "frame-000016.png", "frame-000017.png", "frame-000018.png", "frame-000019.png", "frame-000020.png", "frame-000021.png", "frame-000022.png", "frame-000023.png", "frame-000024.png", "frame-000025.png", "frame-000026.png", "frame-000027.png", "frame-000028.png", "frame-000029.png", "frame-000030.png", "frame-000031.png", "frame-000032.png", "frame-000033.png", "frame-000034.png", "frame-000035.png", "frame-000036.png", "frame-000037.png", "frame-000038.png", "frame-000039.png", "frame-000040.png", "frame-000041.png", "frame-000042.png", "frame-000043.png", "frame-000044.png", "frame-000045.png", "frame-000046.png", "frame-000047.png", "frame-000048.png"]
//        var images = [AnyHashable]()
//        for i in 0..<imageNames.count {
//            images.append(UIImage(named: imageNames[i]) ?? UIImage())
//        }
//        // Normal Animation
//        var animationImageView = UIImageView(frame: CGRect(x: 60, y: 95, width: 86, height: 193))
//        animationImageView.animationImages = images as? [UIImage]
//        animationImageView.animationDuration = 0.5
//        view.addSubview(animationImageView)
//        animationImageView.startAnimating()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func dismiss() {
        for view in self.view.subviews {
            if let inputView = view as? UITextField {
                inputView.resignFirstResponder()
            }
        }
    }
    
    var startTime: TimeInterval?
    var firstHeightTime: TimeInterval?
    var secondHeightTime: TimeInterval?
    @objc var referenceHeight: CGFloat = 216
    
    @objc func keyboardWillShow() {
        if startTime == nil {
            startTime = CACurrentMediaTime()
        }
    }
    
    @objc func keyboardDidHide() {
        startTime = nil
        firstHeightTime = nil
        secondHeightTime = nil
        
        self.stats?.text = "(Waiting for keyboard...)"
    }
    
    @objc func keyboardDidChangeFrame(_ notification: Notification) {
      
      if let userInfo = notification.userInfo
      {
        if let frameEnd = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        {
          if frameEnd.height == referenceHeight {
            if firstHeightTime == nil {
                firstHeightTime = CACurrentMediaTime()
                
                if let startTime = self.startTime {
                    if let firstHeightTime = self.firstHeightTime {
                        let formatString = NSString(format: "First: %.2f, Total: %.2f", (firstHeightTime - startTime), (firstHeightTime - startTime))
                        self.stats?.text = formatString as String
                    }
                }
            }
        }
        else if frameEnd.height != 0 {
            if secondHeightTime == nil {
                secondHeightTime = CACurrentMediaTime()

                if let startTime = self.startTime {
                    if let firstHeightTime = self.firstHeightTime {
                        if let secondHeightTime = self.secondHeightTime {
                            let formatString = NSString(format: "First: %.2f, Second: %.2f, Total: %.2f", (firstHeightTime - startTime), (secondHeightTime - firstHeightTime), (secondHeightTime - startTime))
                            self.stats?.text = formatString as String
                        }
                    }
                }
            }
        }
    }
      }
}
}
