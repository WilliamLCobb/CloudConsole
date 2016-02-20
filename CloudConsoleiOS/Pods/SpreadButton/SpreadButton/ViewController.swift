//
//  ViewController.swift
//  SpreadButton
//
//  Created by lzy on 16/1/18.
//  Copyright © 2016年 lzy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    var spreadButton: SpreadButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let btn1 = SpreadSubButton(backgroundImage: UIImage(named: "clock"), highlightImage: UIImage(named: "clock_highlight")) { (index, sender) -> Void in
            print("first")
        }
        
        let btn2 = SpreadSubButton(backgroundImage: UIImage(named: "pencil"), highlightImage: UIImage(named: "pencil_highlight")) { (index, sender) -> Void in
            print("second")
        }
        
        let btn3 = SpreadSubButton(backgroundImage: UIImage(named: "juice"), highlightImage: UIImage(named: "juice_highlight")) { (index, sender) -> Void in
            print("third")
        }
        
        let btn4 = SpreadSubButton(backgroundImage: UIImage(named: "service"), highlightImage: UIImage(named: "service_highlight")) { (index, sender) -> Void in
            print("fourth")
        }
        
        let btn5 = SpreadSubButton(backgroundImage: UIImage(named: "shower"), highlightImage: UIImage(named: "shower_highlight")) { (index, sender) -> Void in
            print("fifth")
        }
        
        
        let spreadButton = SpreadButton(image: UIImage(named: "powerButton"),
                               highlightImage: UIImage(named: "powerButton_highlight"),
                                     position: CGPointMake(40, UIScreen.mainScreen().bounds.height - 40))
        self.spreadButton = spreadButton
        
        spreadButton?.setSubButtons([btn1, btn2, btn3, btn4, btn5])
        spreadButton?.mode = SpreadMode.SpreadModeSickleSpread
        spreadButton?.direction = SpreadDirection.SpreadDirectionRightUp
        spreadButton?.radius = 120
        spreadButton?.positionMode = SpreadPositionMode.SpreadPositionModeFixed
        
        /*  and you can assign a newValue to change the default
        spreadButton?.animationDuring = 0.2
        spreadButton?.animationDuringClose = 0.25
        spreadButton?.radius = 180
        spreadButton?.coverAlpha = 0.3
        spreadButton?.coverColor = UIColor.yellowColor()
        spreadButton?.touchBorderMargin = 10.0
        */
        
        
        //you can assign the Blocks like this
        spreadButton?.buttonWillSpreadBlock = { print(CGRectGetMaxY($0.frame)) }
        spreadButton?.buttonDidSpreadBlock = { _ in print("did spread") }
        spreadButton?.buttonWillCloseBlock = { _ in print("will closed") }
        spreadButton?.buttonDidCloseBlock = { _ in print("did closed") }
        
        if spreadButton != nil {
            self.view.addSubview(spreadButton!)
        }
    }
    
    @IBAction func changePositionMode(sender: AnyObject) {
        if spreadButton?.positionMode == SpreadPositionMode.SpreadPositionModeFixed {
            spreadButton?.positionMode = SpreadPositionMode.SpreadPositionModeTouchBorder
            sender.setTitle("ModeTouchBorder", forState: .Normal)
        } else {
            spreadButton?.positionMode = SpreadPositionMode.SpreadPositionModeFixed
            sender.setTitle("ModeFixed", forState: .Normal)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

