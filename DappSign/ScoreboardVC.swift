//
//  ScoreboardVC.swift
//  DappSign
//
//  Created by Oleksiy Kovtun on 2/29/16.
//  Copyright © 2016 DappSign. All rights reserved.
//

import UIKit

class ScoreboardVC: UIViewController {
    @IBOutlet weak var profileButton:               UIButton!
    @IBOutlet weak var composeButton:               UIButton!
    @IBOutlet weak var timeUntilNextDailyDappLabel: UILabel!
    @IBOutlet weak var hashtagsLabel:               UILabel!
    @IBOutlet weak var tweetButton:                 UIButton!
    
    internal var transitionDelegate: TransitionDelegate? = nil
    
    private var timeUntilNextDailyDappLabelUpdateTimer: NSTimer? = nil
    private var timeUntilNextDailyDappUpdateTimer: NSTimer? = nil
    private var timeUntilNextDailyDapp: (Int, Int)? = nil
    private var dapps: [PFObject] = []
    private var scoreboardDappSignVC: ScoreboardDappSignVC? = nil
    private var scoreboardDappMappVC: ScoreboardDappMappVC? = nil
    private var currentDappIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewHelper.initButtonLayer(self.profileButton)
        ViewHelper.initButtonLayer(self.composeButton)
        self.updateTimeUntilNextDailyDapp()
        self.updateTimeUntilNextDailyDappLabel()
        self.initTimers()
        
        self.scoreboardDappSignVC?.view.hidden = true
        self.hashtagsLabel.text = ""
        
        self.disableTweetButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        ScoreboardHelper.downloadScoreboardDapps {
            (scoreboardDapps: [PFObject], error: NSError?) -> Void in
            self.dapps = scoreboardDapps
            
            if let dapp = self.dapps.first {
                self.scoreboardDappSignVC?.view.hidden = false
                self.currentDappIndex = 0
                
                self.initHashtagsLabelWithHashtagsForDapp(dapp)
                self.scoreboardDappSignVC?.showDappObject(dapp)
                self.scoreboardDappMappVC?.showDappMappDataForDapp(dapp)
                self.enableTweetButton()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - @IBActions
    
    @IBAction func tweet() {
        if let
            currentDapp = self.currentDapp(),
            dappSignImage = self.scoreboardDappSignVC?.frontSideImage() {
                TwitterHelper.tweetDapp(currentDapp, image: dappSignImage, completion: {
                    (success: Bool, error: NSError?) -> Void in
                    if success {
                        self.showAlertViewWithOKButtonAndMessage(
                            "The card has been successfully tweeted."
                        )
                    } else if let error = error {
                        self.showAlertViewWithOKButtonAndMessage(
                            "Failed to tweet the card. Error: \(error)"
                        )
                    } else {
                        self.showAlertViewWithOKButtonAndMessage(
                            "Failed to tweet the card. Unknown error."
                        )
                    }
                })
        }
    }
    
    // MARK: - init
    
    private func initTimers() {
        self.timeUntilNextDailyDappLabelUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(1.0,
            target:   self,
            selector: "updateTimeUntilNextDailyDappLabel",
            userInfo: nil,
            repeats:  true
        )
        self.timeUntilNextDailyDappUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(0.5,
            target:   self,
            selector: "updateTimeUntilNextDailyDapp",
            userInfo: nil,
            repeats:  true
        )
    }
    
    // MARK: - timer functions
    
    internal func updateTimeUntilNextDailyDappLabel() {
        struct show {
            static var colon = false
        }
        
        show.colon = !show.colon
        
        if let (hours, minutes) = self.timeUntilNextDailyDapp {
            let minutesString = self.minutesStringWithMinutes(minutes)
            
            if show.colon {
                self.timeUntilNextDailyDappLabel.text = "\(hours):\(minutesString)"
            } else {
                self.timeUntilNextDailyDappLabel.text = "\(hours) \(minutesString)"
            }
            
            let lessThanOneHourLeft = hours == 23 && minutes > 0
            
            if lessThanOneHourLeft {
                self.transitionDelegate?.transitionFromViewController(self)
            }
        } else {
            if show.colon {
                self.timeUntilNextDailyDappLabel.text = "--:--"
            } else {
                self.timeUntilNextDailyDappLabel.text = "-- --"
            }
        }
    }
    
    internal func updateTimeUntilNextDailyDapp() {
        if let timeInterval = DailyDappDatesHelper.timeIntervalUntilNextDailyDappStartDate() {
            self.timeUntilNextDailyDapp = DateHelper.fullHoursAndFullMinutesInTimeInterval(
                timeInterval
            )
        } else {
            self.timeUntilNextDailyDapp = nil
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case ScoreboardDappSignVC.embedSegueID:
                self.scoreboardDappSignVC = segue.destinationViewController as? ScoreboardDappSignVC
                
                self.scoreboardDappSignVC?.delegate = self
            case ScoreboardDappMappVC.embedSegueID:
                self.scoreboardDappMappVC = segue.destinationViewController as? ScoreboardDappMappVC
            case _:
                break
            }
        }
    }
    
    // MARK: - 
    
    private func minutesStringWithMinutes(minutes: Int) -> String {
        if minutes < 10 {
            return "0\(minutes)"
        }
        
        return "\(minutes)"
    }
    
    private func showNextDapp() {
        self.currentDappIndex = (self.currentDappIndex + 1) % self.dapps.count
        
        let currentDapp = self.currentDapp()
        
        self.disableTweetButton()
        
        if let currentDapp = currentDapp {
            self.scoreboardDappSignVC?.moveRighOffTheScreen {
                self.initHashtagsLabelWithHashtagsForDapp(currentDapp)
                self.scoreboardDappSignVC?.showDappObject(currentDapp)
                self.enableTweetButton()
            }
        }
        
        self.scoreboardDappMappVC?.showDappMappDataForDapp(currentDapp)
    }
    
    private func currentDapp() -> PFObject? {
        if (self.currentDappIndex < 0 || self.currentDappIndex >= self.dapps.count) {
            return nil
        }
        
        let dapp = self.dapps[self.currentDappIndex]
        
        return dapp
    }
    
    private func initHashtagsLabelWithHashtagsForDapp(dapp: PFObject) {
        self.hashtagsLabel.text = ""
        
        DappsHelper.downloadHashtagsForDapp(dapp) {
            (hashtags: [PFObject]?, error: NSError?) -> Void in
            if let
                hashtags = hashtags,
                currentDapp = self.currentDapp() {
                    if dapp.objectId == currentDapp.objectId {
                        let hashtagsString = HashtagHelper.hashtagNamesStringWithHashtags(hashtags)
                        
                        self.hashtagsLabel.text = hashtagsString
                        
                        return
                    }
            }
            
            self.hashtagsLabel.text = ""
        }
    }
    
    private func disableTweetButton() {
        self.tweetButton.alpha = 0.5
        self.tweetButton.userInteractionEnabled = false
    }
    
    private func enableTweetButton() {
        self.tweetButton.alpha = 1.0
        self.tweetButton.userInteractionEnabled = true
    }
}

extension ScoreboardVC: ScoreboardDappSignDelegate {
    func willFlipToSide(side: DappSignSide) {
        switch side {
        case .Front:
            break;
        case .Back:
            self.disableTweetButton()
        }
    }
    
    func didFlipToSide(side: DappSignSide) {
        switch side {
        case .Front:
            self.enableTweetButton()
        case .Back:
            break;
        }
    }
    
    func didFinishCountingDown() {
        self.showNextDapp()
    }
    
    func openLinkWithURL(linkURL: NSURL) {
        ViewControllerHelper.openLinkWithURL(linkURL, inViewController: self)
    }
}
