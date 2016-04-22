//
//  ScoreboardDappSignVC.swift
//  DappSign
//
//  Created by Oleksiy Kovtun on 4/19/16.
//  Copyright © 2016 DappSign. All rights reserved.
//

import UIKit

enum DappSignSide {
    case Front
    case Back
}

protocol ScoreboardDappSignDelegate {
    func willFlipToSide(side: DappSignSide)
    func didFlipToSide(side: DappSignSide)
    func didFinishCountingDown()
    func openLinkWithURL(linkURL: NSURL)
}

class ScoreboardDappSignVC: UIViewController {
    internal static let embedSegueID: String = "embedScoreboardDappSignVC"
    
    internal var delegate: ScoreboardDappSignDelegate? = nil
    
    private var scoreboardDappSignFrontSideVC: ScoreboardDappSignFrontSideVC? = nil
    private var dappBackSideLinksVC: DappBackSideLinksVC? = nil
    private var visibleChildVC: UIViewController? = nil
    private var tapGR: UITapGestureRecognizer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initChildViewControllers()
        self.initTapGestureRecognizer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - init
    
    private func initChildViewControllers() {
        self.scoreboardDappSignFrontSideVC =
            self.storyboard?.instantiateViewControllerWithIdentifier(
                ScoreboardDappSignFrontSideVC.storyboardID
            ) as? ScoreboardDappSignFrontSideVC
        
        if let scoreboardDappSignFrontSideVC = self.scoreboardDappSignFrontSideVC {
            scoreboardDappSignFrontSideVC.countdownDelegate = self
            
            self.addChildViewController(scoreboardDappSignFrontSideVC)
            
            self.view.addSubview(scoreboardDappSignFrontSideVC.view)
            
            self.visibleChildVC = scoreboardDappSignFrontSideVC
        }
        
        self.dappBackSideLinksVC = self.storyboard?.instantiateViewControllerWithIdentifier(
            DappBackSideLinksVC.storyboardID
        ) as? DappBackSideLinksVC
        
        if let dappBackSideLinksVC = self.dappBackSideLinksVC {
            dappBackSideLinksVC.delegate = self
            
            self.addChildViewController(dappBackSideLinksVC)
        }
    }
    
    private func initTapGestureRecognizer() {
        let frontSideTapGR = UITapGestureRecognizer(
            target: self,
            action: Selector("transitionToBackSide")
        )
        
        if let scoreboardDappSignFrontSideVC = self.scoreboardDappSignFrontSideVC {
            scoreboardDappSignFrontSideVC.view.addGestureRecognizer(frontSideTapGR)
        }
        
        let backSideTapGR = UITapGestureRecognizer(
            target: self,
            action: Selector("transitionToFrontSide")
        )
        
        if let dappBackSideLinksVC = self.dappBackSideLinksVC {
            dappBackSideLinksVC.view.addGestureRecognizer(backSideTapGR)
        }
    }
    
    // MARK: - transitions
    
    internal func transitionToFrontSide() {
        if self.visibleChildVC == self.dappBackSideLinksVC {
            if let
                dappBackSideLinksVC = self.dappBackSideLinksVC,
                scoreboardDappSignFrontSideVC = self.scoreboardDappSignFrontSideVC {
                    self.delegate?.willFlipToSide(.Front)
                    self.transitionFromViewController(dappBackSideLinksVC,
                        toViewController: scoreboardDappSignFrontSideVC,
                        completion: {
                            self.delegate?.didFlipToSide(.Front)
                        }
                    )
            }
        }
    }
    
    internal func transitionToBackSide() {
        if self.visibleChildVC == self.scoreboardDappSignFrontSideVC {
            if let
                scoreboardDappSignFrontSideVC = self.scoreboardDappSignFrontSideVC,
                dappBackSideLinksVC = self.dappBackSideLinksVC {
                    self.delegate?.willFlipToSide(.Back)
                    self.transitionFromViewController(scoreboardDappSignFrontSideVC,
                        toViewController: dappBackSideLinksVC,
                        completion: {
                            self.delegate?.didFlipToSide(.Back)
                        }
                    )
            }
        }
    }
    
    // MARK: - internal
    
    internal func showDappObject(dapp: PFObject?) {
        AnimationHelper.animateDappSignView(self.view)
        self.scoreboardDappSignFrontSideVC?.showDappObject(dapp)
        
        if let dapp = dapp {
            self.dappBackSideLinksVC?.showLinksForDapp(dapp)
        }
    }
    
    internal func frontSideImage() -> UIImage? {
        if self.visibleChildVC == self.scoreboardDappSignFrontSideVC {
            let frontSideImage = self.scoreboardDappSignFrontSideVC?.view.toImage()
            
            return frontSideImage
        }
        
        return nil
    }
    
    // MARK: - animation
    
    internal func moveRighOffTheScreen(completion: (Void -> Void)? = nil) {
        let screenWidth = UIScreen.mainScreen().bounds.size.width
        let animationDuration = 0.5
        
        spring(animationDuration) {
            let translateRightOffTheScreen = CGAffineTransformMakeTranslation(screenWidth, 0.0)
            
            self.view.transform = translateRightOffTheScreen
        }
        
        delay(animationDuration) {
            completion?()
        }
    }
    
    // MARK: - private
    
    private func transitionFromViewController(fromViewController: UIViewController,
        toViewController: UIViewController,
        completion: Void -> Void
    ) {
        toViewController.view.frame = self.view.bounds
        
        self.transitionFromViewController(fromViewController,
            toViewController: toViewController,
            duration: 0.3,
            options: UIViewAnimationOptions.TransitionFlipFromRight,
            animations: nil,
            completion: {
                (finished: Bool) -> Void in
                toViewController.didMoveToParentViewController(self)
                
                self.visibleChildVC = toViewController
                
                completion()
        })
    }
}

extension ScoreboardDappSignVC: CountdownDelegate {
    func didFinishCountingDown() {
        self.delegate?.didFinishCountingDown()
    }
}

extension ScoreboardDappSignVC: DappBackSideLinksVCDelegate {
    func openLinkWithURL(linkURL: NSURL) {
        self.delegate?.openLinkWithURL(linkURL)
    }
}
