//
//  XIBView.swift
//  DappSign
//
//  Created by Oleksiy Kovtun on 9/4/15.
//  Copyright (c) 2015 DappSign. All rights reserved.
//

import UIKit

class XIBView: UIView {
    required init(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        let dynamicTypeStr = NSStringFromClass(self.dynamicType)
        
        if let dotIndex = dynamicTypeStr.rangeOfString(".", options: .LiteralSearch)?.startIndex.successor() {
            let NIBName = dynamicTypeStr.substringFromIndex(dotIndex)
            
            if let view = NSBundle.mainBundle().loadNibNamed(NIBName, owner: self, options: nil).first as? UIView {
                view.setTranslatesAutoresizingMaskIntoConstraints(false)
                
                self.addSubview(view)
                
                // set width
                self.addConstraint(
                    NSLayoutConstraint(
                        item:       view
                    ,   attribute:  NSLayoutAttribute.Width
                    ,   relatedBy:  NSLayoutRelation.Equal
                    ,   toItem:     self
                    ,   attribute:  NSLayoutAttribute.Width
                    ,   multiplier: 1.0
                    ,   constant:   0.0
                    )
                )
                
                // set height
                self.addConstraint(
                    NSLayoutConstraint(
                        item:       view
                    ,   attribute:  NSLayoutAttribute.Height
                    ,   relatedBy:  NSLayoutRelation.Equal
                    ,   toItem:     self
                    ,   attribute:  NSLayoutAttribute.Height
                    ,   multiplier: 1.0
                    ,   constant:   0.0
                    )
                )
                
                // center horizontally
                self.addConstraint(
                    NSLayoutConstraint(
                        item:       view
                    ,   attribute:  NSLayoutAttribute.CenterX
                    ,   relatedBy:  NSLayoutRelation.Equal
                    ,   toItem:     self
                    ,   attribute:  NSLayoutAttribute.CenterX
                    ,   multiplier: 1.0
                    ,   constant:   0.0
                    )
                )
                
                // center vertically
                self.addConstraint(
                    NSLayoutConstraint(
                        item:       view
                    ,   attribute:  NSLayoutAttribute.CenterY
                    ,   relatedBy:  NSLayoutRelation.Equal
                    ,   toItem:     self
                    ,   attribute:  NSLayoutAttribute.CenterY
                    ,   multiplier: 1.0
                    ,   constant:   0.0
                    )
                )
            }
        }
    }
}
