//
//  HomeViewController.swift
//  DappSign
//
//  Created by Seshagiri Vakkalanka on 2/28/15.
//  Copyright (c) 2015 DappSign. All rights reserved.
//

import UIKit

internal let DappSwipedNotification = "dappSwipedNotification"
internal let dappsSwipedRelationKey = "dappsSwiped"
internal let dappsDappedRelationKey = "dappsDapped"

class HomeViewController: UIViewController, SwipeableViewDelegate {
    @IBOutlet weak var dappViewsContainerView: SwipeableView!
    @IBOutlet weak var dappSignView: DappSignView!
    @IBOutlet weak var dappMappView: DappMappView!
    @IBOutlet weak var shareOnFacebookButton: UIButton!
    @IBOutlet weak var tweetThisCardButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var dappScoreLabel: UILabel!
    @IBOutlet weak var linkView: LinkView!
    @IBOutlet weak var embedDappView: EmbedDappView!
    
    @IBOutlet var representativesImagesViews: [UIImageView]!
    
    @IBOutlet weak var plusOneDappsCountLabel: UILabel!
    @IBOutlet weak var plusOneFirstRepresentativeLabel: UILabel!
    @IBOutlet weak var plusOneSecondRepresentativeLabel: UILabel!
    @IBOutlet weak var plusOneThirdRepresentativeLabel: UILabel!
    
    @IBOutlet weak var plusOneDappsCountLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var plusOneFirstRepresentativeLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var plusOneSecondRepresentativeLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var plusOneThirdRepresentativeLabelTopConstraint: NSLayoutConstraint!
    
    private var representativesImagesURLs: [NSURL] = []
    private var visibleDappView: UIView!
    private var lastDappedDapp: PFObject?
    private var animatingPlusOneLabels = false
    private var dappLinksVC: DappLinksVC?
    private var links: [PFObject] = []
    
    private let embedDappLinksVCSegueID = "embedDappLinksVCSegue"
    private let flipDuration = 0.5
    
    var dapps: [PFObject] = []
    var dappsDownloader: DappsDownloader?
    var dappFonts = DappFonts()
    var dappColors = DappColors()
    
    var timer: NSTimer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.dappTextView.TextAlignment
        
        self.dappScoreLabel.text = nil;
        
        self.dappViewsContainerView.hidden = true
        self.dappViewsContainerView.delegate = self
        self.dappViewsContainerView.minTranslationX = 150.0;
        
        self.showDappView(self.dappSignView)
        
        if PFUser.currentUser() == nil {
            self.profileButton.hidden = true
        }
        
        self.updateUserInformation()
        self.downloadDapps()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("handleDappSwipedNotification:"),
            name: DappSwipedNotification,
            object: nil
        )
        
        self.hideLabel(plusOneDappsCountLabel)
        self.hideLabel(plusOneFirstRepresentativeLabel)
        self.hideLabel(plusOneSecondRepresentativeLabel)
        self.hideLabel(plusOneThirdRepresentativeLabel)
        
        self.linkView.delegate = self
        self.linkView.hidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0
            ,   target: self
            ,   selector: Selector("updateDappScore")
            ,   userInfo: nil
            ,   repeats: true
        )
        
        self.downloadRepresentativesImages()
    }
    
    func loopAnimation() {
        self.showThenHidePlusOneLabels()
        
        self.performSelector(Selector("loopAnimation"), withObject: nil, afterDelay: 3.0)
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.timer?.invalidate()
    }
    
    // MARK: - @IBActions
    
    @IBAction func handleDappSignTapGesture(tapGR: UITapGestureRecognizer) {
        if let dappLinksVCView = self.dappLinksVC?.view {
            self.flipWithDuration(self.flipDuration
                ,   view1: self.dappViewsContainerView
                , 	view2: dappLinksVCView
            )
        }
        
        if let dapp = self.dapps.first {
            Requests.downloadLinksForDapp(dapp, completion: {
                (links: [PFObject]?, error: NSError?) -> Void in
                if let links = links {
                    self.links = links
                    
                    self.dappLinksVC?.dappLinksView.linksTableView.reloadData()
                }
                
                if let error = error {
                    print("Error downloading links for dapp with ID \(dapp.objectId): \(error)")
                }
            })
        }
    }
    
    @IBAction func handleDappLinksTapGesture(tapGR: UITapGestureRecognizer) {
        if let dappLinksVCView = self.dappLinksVC?.view {
            self.flipWithDuration(self.flipDuration
                ,   view1: self.dappViewsContainerView
                ,   view2: dappLinksVCView
            )
        }
    }
    
    @IBAction func postCurrentDappCardToFacebook(sender: AnyObject) {
        if let 	currentDappCardAsImage = self.dappViewsContainerView.toImage()
            ,   currentDapp = self.dapps.first {
                FacebookHelper.postImageToFacebook(currentDappCardAsImage
                    ,   dapp: currentDapp
                    ,   completion: { (success: Bool, error: NSError?) -> Void in
                        if success {
                            self.showAlertViewWithOKButtonAndMessage(
                                "The card has been successfully posted."
                            )
                        } else {
                            if let error = error {
                                self.showAlertViewWithOKButtonAndMessage(
                                    "Failed to post the card. Error: \(error)"
                                )
                            } else {
                                self.showAlertViewWithOKButtonAndMessage(
                                    "Failed to post the card. Unknown error."
                                )
                            }
                        }
                })
        }
    }
    
    @IBAction func tweetCurrentDappCard(sender: AnyObject) {
        if let  currentDappCardAsImage = self.dappViewsContainerView.toImage()
            ,   currentDapp = self.dapps.first {
                TwitterHelper.tweetDapp(currentDapp
                    ,   image: currentDappCardAsImage
                    ,   completion: { (success: Bool, error: NSError?) -> Void in
                        if success {
                            self.showAlertViewWithOKButtonAndMessage(
                                "The card has been successfully tweeted."
                            )
                        } else {
                            if let error = error {
                                self.showAlertViewWithOKButtonAndMessage(
                                    "Failed to tweet the card. Error: \(error)"
                                )
                            } else {
                                self.showAlertViewWithOKButtonAndMessage(
                                    "Failed to tweet the card. Unknown error."
                                )
                            }
                        }
                })
        }
    }
    
    @IBAction func showLinkView(sender: AnyObject) {
        if let dapp = self.dapps.first {
            if self.embedDappView.hidden {
                self.embedDappView.hidden = false
                
                self.embedDappView.initURLAndEmbedCodeForDappWithID(dapp.objectId)
            }
        }
    }
    
    // MARK: -
    
    private func flipWithDuration(duration: NSTimeInterval, view1: UIView, view2: UIView) {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationTransition(.FlipFromLeft, forView: view1, cache: true)
        UIView.commitAnimations()
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationTransition(.FlipFromLeft, forView: view2, cache: true)
        
        view1.hidden = !view1.hidden
        view2.hidden = !view2.hidden
        
        UIView.commitAnimations()
    }
    
    private func sendRequestsForDapp(dapp: PFObject, dapped: Bool) {
        let currentUser = PFUser.currentUser()
        
        Requests.addDappToDappsSwipedArray(dapp, user: currentUser, completion: {
            (succeeded: Bool, error: NSError?) -> Void in
            if !succeeded {
                if let error = error {
                    print(error)
                }
                
                return
            }
            
            if !dapped {
                return
            }
            
            Requests.addDappToDappsDappedArray(dapp, user: currentUser, completion: {
                (succeeded: Bool, error: NSError?) -> Void in
                if !succeeded {
                    if let error = error {
                        print("Failed to add dapp with ID \(dapp.objectId) to 'dappsDapped' array. Error = \(error.localizedDescription)")
                    } else {
                        print("Failed to add dapp with ID \(dapp.objectId) to 'dappsDapped' array. Unknown error.")
                    }
                }
            })
            
            Requests.incrementScoreOfTheDapp(dapp, completion: {
                (succeeded: Bool, error: NSError?) -> Void in
                if !succeeded {
                    if let error = error {
                        print(error)
                    }
                    
                    return
                }
            })
            
            if let userId = dapp["userid"] as? String {
                Requests.incrementDappScoreForUserWithId(userId, completion: {
                    (succeeded: Bool, error: NSError?) -> Void in
                    if !succeeded {
                        if let error = error {
                            print("Failed to update dappScore for user with id \(userId). Error: \(error.localizedDescription)")
                        } else {
                            print("Failed to update dappScore for user with id \(userId). Unknown error")
                        }
                    }
                })
            }
            
            let currentUserId = PFUser.currentUser().objectId
            
            Requests.incrementDappScoreForUserWithId(currentUserId, completion: {
                (succeeded: Bool, error: NSError?) -> Void in
                if !succeeded {
                    if let error = error {
                        print(error.localizedDescription)
                    }
                }
            })
        })
    }
    
    // MARK: - Requests
    
    private func updateUserInformation() {
        let user = PFUser.currentUser()
        
        if user == nil {
            return
        }
        
        let userName = user["name"] as? String
        
        if userName != nil {
            return
        }
        
        let FBSession = PFFacebookUtils.session()
        let accessToken = FBSession.accessTokenData.accessToken
        
        let url = NSURL(string: "https://graph.facebook.com/me/picture?type=large&return_ssl_resources+1&access_token=\(accessToken)")
        let urlRequest = NSURLRequest(URL: url!)
        let queue = NSOperationQueue.mainQueue()
        
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: queue) {
            (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
            user["image"] = data
            
            user.saveInBackgroundWithBlock({
                (succeeded: Bool, error: NSError!) -> Void in
                if succeeded {
                    print("Successfully saved user's image.")
                } else {
                    print("Failed to save user's image.")
                    print("Errro: \(error)")
                }
            })
            
            FBRequestConnection.startForMeWithCompletionHandler({
                connection, result, error in
                if let resultDict = result as? NSDictionary {
                    let name = resultDict["name"] as! String
                    
                    user["name"] = name
                    user["lowercaseName"] = name.lowercaseString
                    
                    user.saveInBackgroundWithBlock({
                        (succeeded: Bool, error: NSError!) -> Void in
                        if succeeded {
                            print("Successfully saved user's name.")
                        } else {
                            print("Failed to save user's name.")
                            print("Errro: \(error)")
                        }
                    })
                }
            })
            
            user["dappScore"] = 0
            
            user.saveInBackgroundWithBlock({
                (succeeded: Bool, error: NSError!) -> Void in
                if succeeded {
                    print("Successfully set user's dappScore to 0.")
                } else {
                    print("Failed to set user's dappScore to 0.")
                    print("Errro: \(error)")
                }
            })
        }
    }
    
    private func downloadDapps() {
        self.downloadPrimaryDappsWithSuccessClosure {
            () -> Void in
            self.downloadSecondaryDapps()
        }
    }
    
    private func downloadPrimaryDappsWithSuccessClosure(success: () -> Void) {
        let user = PFUser.currentUser()
        
        self.dappsDownloader = DappsDownloader(type: .Primary)
        
        self.dappsDownloader?.downloadDappsNotSwipedByUser(user,
            completion: {
                (dapps: [PFObject], error: NSError!) -> Void in
                if error != nil {
                    print(error)
                    
                    self.initDappView()
                    
                    return
                }
                
                self.dapps = dapps
                
                if self.dapps.count > 0 {
                    self.initDappView()
                }
                
                success()
        })
    }
    
    private func downloadSecondaryDapps() {
        let user = PFUser.currentUser()
        
        self.dappsDownloader = DappsDownloader(type: .Secondary)
        
        self.dappsDownloader?.downloadDappsNotSwipedByUser(user, completion: {
            (dapps: [PFObject], error: NSError!) -> Void in
            if error != nil {
                print(error)
                
                self.initDappView()
                
                return
            }
            
            if dapps.count > 0 {
                var shouldShowCurrentDapp = false;
                
                if self.dapps.count == 0 {
                    shouldShowCurrentDapp = true
                }
                
                var sortedDapps = dapps
                
                sortedDapps.sortInPlace({
                    (dapp1: PFObject, dapp2: PFObject) -> Bool in
                    return dapp1["dappScore"] as? Int > dapp2["dappScore"] as? Int
                })
                
                for dapp in sortedDapps {
                    self.dapps.append(dapp)
                }
                
                if shouldShowCurrentDapp {
                    self.initDappView()
                }
            } else if self.dapps.count == 0 {
                self.initDappView()
            }
        })
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showProfile" {
            let profileNC = segue.destinationViewController as! UINavigationController
            
            if let profileVC = profileNC.viewControllers.first as? ProfileViewController {
                profileVC.user = PFUser.currentUser()
            }
        } else if segue.identifier == "embedDappLinksVCSegue" {
            self.dappLinksVC = segue.destinationViewController as? DappLinksVC
            self.dappLinksVC?.view.hidden = true
            self.dappLinksVC?.delegate = self
            
            let tapGR = UITapGestureRecognizer(
                target: self
                , 	action: Selector("handleDappLinksTapGesture:")
            )
            
            self.dappLinksVC?.dappLinksView.addGestureRecognizer(tapGR)
        }
    }
    
    // MARK: - Timer
    
    func updateDappScore() {
        let currentUser = PFUser.currentUser()
        
        Requests.downloadDappScoreForUserWithId(currentUser.objectId, completion: {
            (dappScore: Int?, error: NSError?) -> Void in
            if error != nil {
                print(error)
                
                self.dappScoreLabel.text = nil
                
                return
            }
            
            if let dappScore = dappScore {
                if dappScore == 1 {
                    self.dappScoreLabel.text = "1 Dapp"
                } else {
                    self.dappScoreLabel.text = "\(dappScore) Dapp"
                }
            }
        })
    }
    
    // MARK: -
    
    internal func handleDappSwipedNotification(notification: NSNotification) {
        if let dappId = notification.object as? String {
            if self.dapps.first?.objectId == dappId {
                self.dapps.removeAtIndex(0)
                
                self.initDappView()
            } else {
                self.dapps = self.dapps.filter({ $0.objectId != dappId })
            }
        }
    }
    
    private func initDappView() {
        if self.dappViewsContainerView.hidden {
            self.dappViewsContainerView.hidden = false
            
            self.dappViewsContainerView.show()
        }
        
        if (self.visibleDappView == self.dappSignView) {
            let dapp = dapps.first
            
            self.dappSignView.showDapp(dapp)
            
            if let dapp_ = dapp, userID = dapp_["userid"] as? String {
                Requests.userWithID(userID, completion: { (user: PFUser?, error: NSError?) -> Void in
                    if let usr = user {
                        self.dappSignView.showUserInfo(usr)
                    } else if let err = error {
                        print("Failed to download information about user with ID \(userID). Error = \(err)")
                    } else {
                        print("Failed to download information about user with ID \(userID). Unknown error.")
                    }
                })
                
                Requests.addUserToUsersWhoSaw(dapp_, user: PFUser.currentUser(), completion: {
                    (succeeded: Bool, error: NSError!) -> Void in
                    if !succeeded {
                        if let err = error {
                            print("error = \(err)")
                        } else {
                            print("error = unknown")
                        }
                        
                        return
                    }
                })
            }
        } else if (self.visibleDappView == self.dappMappView) {
            let SVGMapURL = SVGMapGenerator.generate([:])
            
            // placeholders
            self.dappMappView.show(0, SVGMapURLPath: SVGMapURL, percents: 0)
            
            if let dapp = self.lastDappedDapp {
                Requests.percents(dapp, completion: {
                    (usersDapped: [PFUser:Bool]?, error: NSError?) -> Void in
                    if let usersDapped_ = usersDapped {
                        if usersDapped_.count >= 20 {
                            self.downloadDataForMapAndShowIt(usersDapped_, dapp: dapp)
                            
                            return
                        }
                        
                        var dappsCount = UInt(10 + arc4random_uniform(20))
                        var IDsFreqs = CongressionalDistrictsIDs.getRandomIDsFreqs(dappsCount)
                        let SVGMapURL = SVGMapGenerator.generate(IDsFreqs)
                        var percents = 0 as UInt
                        
                        if let 	user = PFUser.currentUser()
                            ,   congrDistrID = user["congressionalDistrictID"] as? String {
                                let additionalFreq = UInt(1 + arc4random_uniform(4))
                                var dappTotalViews = 1 as UInt
                                var dappDapps = 1 as UInt
                                
                                if let freq = IDsFreqs[congrDistrID] as UInt? {
                                    IDsFreqs[congrDistrID] = freq + additionalFreq
                                    
                                    dappTotalViews = freq + additionalFreq
                                } else {
                                    IDsFreqs[congrDistrID] = additionalFreq
                                    
                                    dappTotalViews = additionalFreq
                                }
                                
                                dappDapps = UInt(arc4random_uniform(UInt32(dappTotalViews)))
                                
                                if dappDapps == 0 {
                                    dappDapps = 1
                                } else if dappDapps > dappTotalViews {
                                    dappDapps = dappTotalViews
                                }
                                
                                percents = UInt(roundf(Float(dappDapps) / Float(dappTotalViews) * 100))
                                dappsCount += additionalFreq
                        }
                        
                        self.dappMappView.show(dappsCount, SVGMapURLPath: SVGMapURL, percents: percents)
                    }
                })
            }
        }
    }
    
    private func downloadDataForMapAndShowIt(usersDapped: [PFObject:Bool], dapp: PFObject) {
        let dapps = Array(usersDapped.values)
        
        CongressionalDistrictsIDs.getIDsFrequenciesForDapp(dapp, completion: {
            (IDsFreqs: IDsFrequencies?) -> Void in
            if let IDsFreqs_ = IDsFreqs {
                var dappScore = 0 as UInt
                
                if let dappScore_ = dapp["dappScore"] as? UInt {
                    dappScore = dappScore_
                }
                
                let SVGMapURL = SVGMapGenerator.generate(IDsFreqs_)
                let dappedCount = Array(usersDapped.keys).filter({
                    let currentUser = PFUser.currentUser()
                    
                    if let  currentUserCongrDistrID = currentUser["congressionalDistrictID"] as? String
                        ,   userCongrDistrID = $0["congressionalDistrictID"] as? String {
                            if $0.objectId == currentUser.objectId {
                                // the back end hasn't been updated yet
                                return true
                            } else if currentUserCongrDistrID == userCongrDistrID {
                                if let dapped = usersDapped[$0] as Bool? {
                                    if dapped == true {
                                        return true
                                    }
                                }
                            }
                    }
                    
                    return false
                }).count
                
                var percents = 0 as UInt
                
                if dappedCount > 0 && dapps.count > 0 {
                    percents = UInt(roundf(Float(dappedCount) / Float(dapps.count) * 100))
                }
                
                self.dappMappView.show(dappScore, SVGMapURLPath: SVGMapURL, percents: percents)
            }
        })
    }
    
    func downloadRepresentativesImages() {
        func representativesImagesURLs(completion: (URLs: [NSURL]?) -> Void) {
            if self.representativesImagesURLs.count > 0 {
                completion(URLs: self.representativesImagesURLs)
                
                return
            }
            
            self.representativesImagesURLs = []
            
            let currentUser = PFUser.currentUser()
            
            Requests.downloadRepresentativesForUserWithID(currentUser.objectId, completion: {
                (representatives: [PFObject]?, error: NSError?) -> Void in
                if let representatives_ = representatives {
                    for representative in representatives_ {
                        if let
                            imgURLStr = representative["imgUrl"] as? String,
                            imgURL = NSURL(string: imgURLStr) {
                                self.representativesImagesURLs.append(imgURL)
                        }
                    }
                    
                    completion(URLs: self.representativesImagesURLs)
                } else {
                    if let err = error {
                        print("\(err)")
                    } else {
                        print("Unknown error.")
                    }
                    
                    completion(URLs: nil)
                }
            })
        }
        
        representativesImagesURLs { (URLs: [NSURL]?) -> Void in
            if let URLs_ = URLs {
                self.representativesImagesURLs = URLs_
                
                for index in 0 ... self.representativesImagesURLs.count {
                    if (index == self.representativesImagesURLs.count ||
                        index == self.representativesImagesViews.count) {
                            break
                    }
                    
                    let representativeImageView = self.representativesImagesViews[index]
                    
                    if representativeImageView.image != nil {
                        continue
                    }
                    
                    let URL = URLs_[index]
                    
                    Requests.downloadImageFromURL(URL, completion: {
                        (image: UIImage?, error: NSError?) -> Void in
                        if let img = image {
                            representativeImageView.image = img
                        } else if let err = error {
                            print("\(err)")
                        } else {
                            print("Unknown error.")
                        }
                    })
                }
            }
        }
    }
    
    // MARK: - SwipeableViewDelegate
    
    func didSwipe(swipeDirection: SwipeDirection) {
        if (self.visibleDappView == self.dappSignView) {
            let dapped = (swipeDirection == SwipeDirection.LeftToRight)
            
            if let currentDapp = self.dapps.first {
                self.lastDappedDapp = currentDapp
                
                self.sendRequestsForDapp(currentDapp, dapped: dapped)
                
                if dapped {
                    self.showThenHidePlusOneLabels()
                }
            } else {
                self.lastDappedDapp = nil
            }
            
            if self.dapps.count > 0 {
                self.dapps.removeAtIndex(0)
            }
            
            if (dapped && self.dapps.count > 0) {
                self.showDappView(self.dappMappView)
            }
        } else {
            self.showDappView(self.dappSignView)
        }
        
        self.initDappView()
        
        if self.dapps.count == 0 {
            self.downloadDapps()
        }
    }
    
    // MARK: -
    
    private func showDappView(dappView: UIView) {
        if (dappView == self.dappSignView) {
            self.dappSignView.hidden = false
            self.dappMappView.hidden = true
            self.visibleDappView = dappView
        } else if (dappView == self.dappMappView) {
            self.dappSignView.hidden = true
            self.dappMappView.hidden = false
            self.visibleDappView = dappView
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    private func showThenHidePlusOneLabels() {
        if self.animatingPlusOneLabels {
            return
        }
        
        self.animatingPlusOneLabels = true
        
        let plusOneLabels =
        [   plusOneDappsCountLabel
        ,   plusOneFirstRepresentativeLabel
        ,   plusOneSecondRepresentativeLabel
        ,   plusOneThirdRepresentativeLabel
        ]
        
        let labelTopConstraint =
        [   plusOneDappsCountLabel:           plusOneDappsCountLabelTopConstraint
        ,   plusOneFirstRepresentativeLabel:  plusOneFirstRepresentativeLabelTopConstraint
        ,   plusOneSecondRepresentativeLabel: plusOneSecondRepresentativeLabelTopConstraint
        ,   plusOneThirdRepresentativeLabel:  plusOneThirdRepresentativeLabelTopConstraint
        ]

        let topConstraintMax =
        [   plusOneDappsCountLabelTopConstraint:           CGFloat(-16.0)
        ,   plusOneFirstRepresentativeLabelTopConstraint:  CGFloat(18.0)
        ,   plusOneSecondRepresentativeLabelTopConstraint: CGFloat(18.0)
        ,   plusOneThirdRepresentativeLabelTopConstraint:  CGFloat(18.0)
        ]
        
        let topConstraintMin =
        [   plusOneDappsCountLabelTopConstraint:           CGFloat(-30.0)
        ,   plusOneFirstRepresentativeLabelTopConstraint:  CGFloat(-2.0)
        ,   plusOneSecondRepresentativeLabelTopConstraint: CGFloat(-2.0)
        ,   plusOneThirdRepresentativeLabelTopConstraint:  CGFloat(-2.0)
        ]

        let animationDuration = 0.4
        let delayMultiplier = 0.1
        let allAnimationsDuration = (
            animationDuration +
            Double(plusOneLabels.count - 1) *
            delayMultiplier
        )
        
        for labelIndex in 0 ... plusOneLabels.count - 1 {
            let label = plusOneLabels[labelIndex]
            
            if let topConstraint = labelTopConstraint[label] {
                let animationDelay = Double(labelIndex) * delayMultiplier
                
                delay(animationDelay) {
                    self.showLabel(label)
                }
                
                UIView.animateWithDuration(animationDuration
                ,   delay: animationDelay
                , 	options: UIViewAnimationOptions.CurveLinear
                , 	animations: {
                        if let topConstraintMinVal = topConstraintMin[topConstraint] {
                            topConstraint.constant = topConstraintMinVal
                        }
                    
                        self.view.layoutIfNeeded()
                    }
                ,   completion: nil
                )
            }
        }
        
        delay(allAnimationsDuration
        ,   closure: {
                for labelIndex in 0 ... plusOneLabels.count - 1 {
                    let label = plusOneLabels[labelIndex]
                    
                    if let topConstraint = labelTopConstraint[label] {
                        UIView.animateWithDuration(animationDuration
                        , 	animations: {
                                self.hideLabel(label)
                            }
                        , 	completion: { (finished: Bool) -> Void in
                                topConstraint.constant = topConstraintMax[topConstraint]!
                            
                                self.view.layoutIfNeeded()
                            }
                        )
                    }
                }
            
                delay(animationDuration) {
                    self.animatingPlusOneLabels = false
                }
            }
        )
    }
    
    private func showLabel(label: UILabel) {
        label.alpha = 1.0
    }
    
    private func hideLabel(label: UILabel) {
        label.alpha = 0.0
    }
}

extension HomeViewController: DappLinksVCDelegate {
    func getLinkAtIndex(index: Int) -> Link? {
        if index < self.links.count {
            let linkObj = self.links[index]
            let link = Link(linkObj: linkObj)
            
            return link
        }
        
        return nil
    }
    
    func getLinksCount() -> Int {
        return self.links.count
    }
    
    func canDeleteLinks() -> Bool {
        return false
    }
    
    func getNextState(currentState: DappLinkCellState) -> DappLinkCellState {
        return currentState
    }
    
    func getStateForNoLink() -> DappLinkCellState {
        return .Empty
    }
    
    func openURL(URL: NSURL) {
        self.linkView.hidden = false
        
        self.linkView.openURL(URL)
    }
    
    func openLinkOnTap() -> Bool {
        return true
    }
}

extension HomeViewController: LinkViewDelegate {
    func closeLinkView() {
        self.linkView.hidden = true
    }
}