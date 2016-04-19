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
    @IBOutlet weak var representativeImageView:     UIImageView!
    @IBOutlet weak var representativeNameLabel:     UILabel!
    
    internal var transitionDelegate: TransitionDelegate? = nil
    
    private var timeUntilNextDailyDappLabelUpdateTimer: NSTimer? = nil
    private var timeUntilNextDailyDappUpdateTimer: NSTimer? = nil
    private var timeUntilNextDailyDapp: (Int, Int)? = nil
    private var scoreboardDapps: [PFObject] = []
    private var scoreboardDappSignVC: ScoreboardDappSignVC? = nil
    
    override func viewDidLoad() {
        print("viewDidLoad()")
        super.viewDidLoad()
        self.initButtons()
        self.updateTimeUntilNextDailyDapp()
        self.updateTimeUntilNextDailyDappLabel()
        self.initRepresentativeImageView()
        self.initTimers()
    }
    
    override func viewWillAppear(animated: Bool) {
        print("viewWillAppear()")
        super.viewWillAppear(animated)
        
        ScoreboardHelper.downloadScoreboardDapps {
            (scoreboardDapps: [PFObject], error: NSError?) -> Void in
            self.scoreboardDapps = scoreboardDapps
            
            if let dapp = self.scoreboardDapps.first {
                self.scoreboardDappSignVC?.showDappObject(dapp)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - UI
    
    private func initButtons() {
        self.addBordersToView(self.profileButton)
        self.addBordersToView(self.composeButton)
        
        let cornerRadius: CGFloat = 6.0
        
        self.profileButton.layer.cornerRadius = cornerRadius
        self.composeButton.layer.cornerRadius = cornerRadius
    }
    
    private func initRepresentativeImageView() {
        self.addBordersToView(self.representativeImageView)
        
        let representativeImageViewWidth = CGRectGetWidth(self.representativeImageView.frame)
        let cornerRadius = representativeImageViewWidth / 2
        
        self.representativeImageView.layer.cornerRadius = cornerRadius
    }
    
    private func addBordersToView(view: UIView) {
        view.layer.borderColor = UIColor.whiteColor().CGColor
        view.layer.borderWidth = 2.0
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
        print("prepareForSegue()")
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case ScoreboardDappSignVC.embedSegueID:
                self.scoreboardDappSignVC = segue.destinationViewController as? ScoreboardDappSignVC
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
}
