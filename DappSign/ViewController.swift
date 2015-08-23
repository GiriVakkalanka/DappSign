//
//  ViewController.swift
//  DappSign
//
//  Created by Seshagiri Vakkalanka on 2/28/15.
//  Copyright (c) 2015 DappSign. All rights reserved.
//  Revisited on 8/23 to test.

import UIKit

class ViewController: UIViewController {
    
    var bIsZipCode : Bool = false
    var strUserID : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func facebookLoginButton(sender: AnyObject) {
        let loginWithFacebookButton = sender as! UIButton
        var permissions = ["public_profile", "email"]
        
        loginWithFacebookButton.userInteractionEnabled = false
        loginWithFacebookButton.alpha = 0.5
        
        PFFacebookUtils.logInWithPermissions(permissions, block: {
            (user: PFUser!, error: NSError!) -> Void in
            if let user = user {
                if user.isNew {
                    
                    println("User signed up and logged in through Facebook!")
                    self.bIsZipCode = true
                    self.strUserID = user.objectId
                    self.performSegueWithIdentifier("showZipCode", sender: self)
                    
                } else {
                    println("User logged in through Facebook!")
                    self.strUserID = user.objectId
                    self.performSegueWithIdentifier("showHomeViewController", sender: self)
                }
                
                Requests.addUserIdDappScore(user.objectId)
                
                
            } else {
                println("Uh oh. The user cancelled the Facebook login.")
            }
            
            loginWithFacebookButton.userInteractionEnabled = true
            loginWithFacebookButton.alpha = 1.0
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if bIsZipCode{
            var ZipCodeVC : ZipCodeViewController = segue.destinationViewController as! ZipCodeViewController
            ZipCodeVC.strUserID = strUserID
        }
    }
    
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}

