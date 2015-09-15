//
//  SwipeableView.swift
//  SwipeTest
//
//  Created by Oleksiy Kovtun on 9/14/15.
//  Copyright (c) 2015 Yanpix. All rights reserved.
//

import UIKit

internal enum SwipeDirection {
    case LeftToRight
    case RightToLeft
}

protocol SwipeableViewDelegate: class {
    func didSwipe(swipeDirection: SwipeDirection)
}

class SwipeableView: UIView {
    private var originalCenter = CGPointZero
    private var animator: UIDynamicAnimator?
    private var snapBehavior: UISnapBehavior?
    private var gravity: UIGravityBehavior?
    private var swipeDirection: SwipeDirection?
    
    internal var minTranslationX: CGFloat?
    internal weak var delegate: SwipeableViewDelegate?
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addPanGesture()
    }
    
    required init(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        self.addPanGesture()
    }
    
    private func addPanGesture() {
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: Selector("handlePanGesture:")))
    }
    
    override func layoutSubviews() {
        self.originalCenter = self.center
        
        if let superview = self.superview {
            if self.animator == nil {
                self.animator = UIDynamicAnimator(referenceView: superview)
            }
            
            if self.snapBehavior == nil {
                let snapBehaviour = UISnapBehavior(item: self, snapToPoint: self.originalCenter)
                snapBehaviour.damping = 0.4
                
                self.snapBehavior = snapBehaviour
            }
            
            if self.gravity == nil {
                self.gravity = UIGravityBehavior(items: [self])
                self.gravity?.action = {
                    if CGRectGetMinY(self.frame) > CGRectGetHeight(superview.frame) || CGRectGetMaxY(self.frame) < 0.0 {
                        self.show()
                    }
                }
            }
        }
    }
    
    internal func show() {
        self.animator?.removeAllBehaviors()
        
        if let superview = self.superview {
            self.center = superview.center
        }
        
        let scale = CGAffineTransformMakeScale(0.5, 0.5)
        let translate = CGAffineTransformMakeTranslation(0.0, -200.0)
        
        self.transform = CGAffineTransformConcat(scale, translate)
        
        if let swipeDirection = self.swipeDirection {
            self.delegate?.didSwipe(swipeDirection)
        }
        
        spring(0.5) {
            let scale = CGAffineTransformMakeScale(1.0, 1.0)
            let translate = CGAffineTransformMakeTranslation(0.0, 0.0)
            
            self.transform = CGAffineTransformConcat(scale, translate)
        }
    }
    
    // MARK: - pan gesture recognizer
    
    internal func handlePanGesture(panGR: UIPanGestureRecognizer) {
        let translation = panGR.translationInView(self)
        
        switch panGR.state {
        case .Began:
            self.animator?.removeAllBehaviors()
            
            break
        case .Changed:
            let defaultRotationAngle = CGFloat(M_PI) / 10.0
            let rotationMax: CGFloat = 1.0
            let xRotationStrength = min(translation.x / self.frame.size.width, rotationMax)
            let yRotationStrength = min(translation.y / self.frame.size.height, rotationMax)
            var rotationAngle = defaultRotationAngle * xRotationStrength * yRotationStrength
            
            self.transform = CGAffineTransformMakeRotation(rotationAngle)
            self.center = CGPoint(
                x: self.originalCenter.x + translation.x
            ,   y: self.originalCenter.y + translation.y
            )
            
            break
        case .Ended:
            self.swipeDirection = nil
            
            if let superview = self.superview, minTranslationX = self.minTranslationX {
                if translation.x >= minTranslationX {
                    self.swipeDirection = SwipeDirection.LeftToRight
                } else if translation.x <= -minTranslationX {
                    self.swipeDirection = SwipeDirection.RightToLeft
                }
            }
            
            if let swipeDir = self.swipeDirection {
                switch swipeDir {
                case .LeftToRight:
                    self.gravity?.gravityDirection = CGVectorMake(0.0, -10.0)
                case .RightToLeft:
                    self.gravity?.gravityDirection = CGVectorMake(0.0, 10.0)
                }
                
                self.animator?.addBehavior(self.gravity)
            } else {
                self.animator?.addBehavior(self.snapBehavior)
            }
            
            break
        default:
            break
        }
    }
}
