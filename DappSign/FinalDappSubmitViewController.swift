//
//  FinalDappSubmitViewController.swift
//  DappSign
//
//  Created by Seshagiri Vakkalanka on 3/4/15.
//  Copyright (c) 2015 DappSign. All rights reserved.
//

import UIKit

class FinalDappSubmitViewController: UIViewController, SwipeableViewDelegate {
    @IBOutlet weak var containerView: SwipeableView!
    @IBOutlet weak var dappView: UIView!
    @IBOutlet weak var dappHeaderView: UIView!
    @IBOutlet weak var headerImage: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var dappFooterView: UIView!
    @IBOutlet weak var footerImage: UIImageView!
    @IBOutlet weak var footerLabel: UILabel!
    @IBOutlet weak var dappScoreView: UIView!
    @IBOutlet weak var dappLogoView: UIView!
    @IBOutlet weak var scoreLabelText: UILabel!
    @IBOutlet weak var logoLabel: UILabel!
    @IBOutlet weak var dappStatementLabel: UILabel!
    @IBOutlet weak var shareOnFacebookButton: UIButton!
    @IBOutlet weak var tweetThisCardButton: UIButton!
    
    //design
    var dappColors = DappColors()
    var dappFonts = DappFonts()
    
    internal var dapp: Dapp?
    internal var links: [Link]?
    
    private var dappObj: PFObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.shareOnFacebookButton?.layer.cornerRadius = 8.0
        self.tweetThisCardButton?.layer.cornerRadius = 8.0
        
        var user = PFUser.currentUser()
        
        dappView.alpha = 0
        
        let scale = CGAffineTransformMakeScale(0.5, 0.5)
        let translate = CGAffineTransformMakeTranslation(0, -200)
        dappView.transform = CGAffineTransformConcat(scale, translate)
        
        spring(0.5) {
            let scale = CGAffineTransformMakeScale(1, 1)
            let translate = CGAffineTransformMakeTranslation(0, 0)
            self.dappView.transform = CGAffineTransformConcat(scale, translate)
        }
        
        if let dappBackgroundColor = self.dapp?.dappBackgroundColor {
            self.dappStatementLabel.backgroundColor = dappColors.dappColorWheel[dappBackgroundColor]
        }
        
        if let dappStatement = self.dapp?.dappStatement {
            self.dappStatementLabel.text = dappStatement
        } else {
            self.dappStatementLabel.text = ""
        }
        
        if let dappFont = self.dapp?.dappFont {
            self.dappStatementLabel.font = self.dappFonts.dappFontBook[dappFont]
        }
        
        self.dappStatementLabel.textColor = UIColor.whiteColor()
        self.dappScoreView.backgroundColor = self.dappStatementLabel.backgroundColor
        self.dappLogoView.backgroundColor = self.dappStatementLabel.backgroundColor
        self.dappView.backgroundColor = self.dappStatementLabel.backgroundColor
        
        if let name = self.dapp?.name {
            self.footerLabel.text = name
        } else {
            self.footerLabel.text = ""
        }
        
        if let imageData = user["image"] as? NSData {
            self.footerImage.image = UIImage(data: imageData)
        }
        
        self.dappView.alpha = 1
        
        self.containerView.minTranslationX = 150.0
        self.containerView.delegate = self
        
        self.disableViews([self.shareOnFacebookButton, self.tweetThisCardButton])
        
        if let dapp = self.dapp {
            self.submitDapp(dapp)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func postCurrentDappCardToFacebook(sender: AnyObject) {
        if let dappObj = self.dappObj {
            let currentDappCardAsImage = self.dappView.toImage()
            
            FacebookHelper.postImageToFacebook(currentDappCardAsImage,
                dapp: dappObj,
                completion: {
                    (success, error) -> Void in
                    if success {
                        self.showAlertViewWithOKButtonAndMessage("The card has been successfully posted.")
                    } else {
                        if error != nil {
                            self.showAlertViewWithOKButtonAndMessage("Failed to post the card. Error: \(error)")
                        } else {
                            self.showAlertViewWithOKButtonAndMessage("Failed to post the card. Unknown error.")
                        }
                    }
            })
        }
    }
    
    @IBAction func tweetCurrentDappCard(sender: AnyObject) {
        if let dappObj = self.dappObj {
            let currentDappCardAsImage = self.dappView.toImage()
            
            TwitterHelper.tweetDapp(dappObj,
                image: currentDappCardAsImage,
                completion: {
                    (success, error) -> Void in
                    if success {
                        self.showAlertViewWithOKButtonAndMessage("The card has been successfully tweeted.")
                    } else {
                        if error != nil {
                            self.showAlertViewWithOKButtonAndMessage("Failed to tweet the card. Error: \(error)")
                        } else {
                            self.showAlertViewWithOKButtonAndMessage("Failed to tweet the card. Unknown error.")
                        }
                    }
            })
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK: -
    
    func submitDapp(dapp: Dapp) {
        var dappObj = PFObject(className: "Dapps")
        
        if let dappStatement = dapp.dappStatement {
            dappObj["dappStatement"] = dappStatement
        }
        
        if let lowercaseDappStatement = dapp.lowercaseDappStatement {
            dappObj["lowercaseDappStatement"] = lowercaseDappStatement
        }
        
        if let dappFont = dapp.dappFont {
            dappObj["dappFont"] = dappFont
        }
        
        if let dappBackgroundColor = dapp.dappBackgroundColor {
            dappObj["dappBackgroundColor"] = dappBackgroundColor
        }
        
        if let name = dapp.name {
            dappObj["name"] = name
        }
        
        if let userid = dapp.userid {
            dappObj["userid"] = userid
        }
        
        dappObj["dappScore"] = dapp.dappScore
        dappObj["isDeleted"] = dapp.isDeleted
        
        if let dappTypeId = dapp.dappTypeId {
            dappObj["dappTypeId"] = dappTypeId
        }
        
        dappObj.saveInBackgroundWithBlock({ (succeeded: Bool, error: NSError!) -> Void in
            if !succeeded {
                println("%@" , error)
                
                return
            }
            
            self.dappObj = dappObj
            
            self.enableViews([self.shareOnFacebookButton, self.tweetThisCardButton])
            
            println("Dapp created with id: \(dappObj.objectId)")
            println(dappObj)
            
            Requests.uploadHashtags(dapp.hashtagNames, completion: {
                (hashtags: [PFObject]?, error: NSError!) -> Void in
                if error != nil {
                    println("Failed to upload hashtags \(dapp.hashtagNames). Error: \(error)")
                }
                
                if let hashtags = hashtags {
                    let hashtagsRelation = dappObj.relationForKey("hashtags")
                    
                    for hashtag in hashtags {
                        hashtagsRelation.addObject(hashtag)
                    }
                    
                    dappObj.saveInBackgroundWithBlock({ (success: Bool, error: NSError!) -> Void in
                        if success {
                            println("Successfully added hashtags to dapp.")
                        } else {
                            println("Failed to add hashtags to dapp. Error: \(error)")
                        }
                    })
                }
            })
            
            if let links = self.links {
                Requests.uploadLinks(links, completion: {
                    (linkObjs: [PFObject], error: NSError?) -> Void in
                    println("Finished uploading links.")
                    
                    if let error = error {
                        println("Links uploading error: \(error)")
                    }
                    
                    if linkObjs.count > 0 {
                        let linksRelation = dappObj.relationForKey("links")
                        
                        for linkObj in linkObjs {
                            linksRelation.addObject(linkObj)
                        }
                        
                        dappObj.saveInBackgroundWithBlock({
                            (success: Bool, error: NSError!) -> Void in
                            if success {
                                println("Successfully added links to dapp.")
                            } else {
                                println("Failed to add links to dapp. Error: \(error)")
                            }
                        })
                    }
                })
            }
            
            if let userId = dappObj["userid"] as? String {
                Requests.incrementDappScoreForUserWithId(userId, completion: {
                    (succeeded: Bool, error: NSError?) -> Void in
                    if !succeeded {
                        if let error = error {
                            println(error.localizedDescription)
                        }
                    }
                })
            }
            
            let currentUserId = PFUser.currentUser().objectId
            
            Requests.incrementDappScoreForUserWithId(currentUserId, completion: {
                (succeeded: Bool, error: NSError?) -> Void in
                if !succeeded {
                    if let error = error {
                        println(error.localizedDescription)
                    }
                }
            })
        })
    }
    
    // MARK: - UI
    
    private func disableViews(views: [UIView]) {
        for view in views {
            view.userInteractionEnabled = false
            view.alpha = 0.5
        }
    }
    
    private func enableViews(views: [UIView]) {
        for view in views {
            view.userInteractionEnabled = true
            view.alpha = 1.0
        }
    }
}

extension FinalDappSubmitViewController: SwipeableViewDelegate {
    func didSwipe(swipeDirection: SwipeDirection) {
        self.performSegueWithIdentifier("showHomeViewControllerAfterSubmit", sender: self)
    }
}
