//
//  EditDappLinksVC.swift
//  DappSign
//
//  Created by Oleksiy Kovtun on 9/22/15.
//  Copyright (c) 2015 DappSign. All rights reserved.
//

import UIKit

class EditDappLinksVC: UIViewController {
    private let embedDappLinksVCSegueID = "embedDappLinksVCSegue"
    
    internal var dapp: PFObject?
    
    private var links: [PFObject] = []
    
    private var dappLinkVC: DappLinksVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let font = UIFont(name: "Exo-Regular", size: 18.0) {
            self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: font]
        }
        
        self.dappLinkVC?.dappLinksView.userInteractionEnabled = false
        self.dappLinkVC?.dappLinksView.alpha = 0.5
        
        if let dapp = self.dapp {
            Requests.downloadLinksForDapp(dapp, completion: {
                (links: [PFObject]?, error: NSError?) -> Void in
                self.dappLinkVC?.dappLinksView.userInteractionEnabled = true
                self.dappLinkVC?.dappLinksView.alpha = 1.0
                
                if let links = links {
                    self.links = links
                    
                    self.dappLinkVC?.dappLinksView.linksTableView.reloadData()
                }
                
                if let error = error {
                    println("Error downloading links for dapp with ID \(dapp.objectId): \(error)")
                }
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == embedDappLinksVCSegueID {
            self.dappLinkVC = segue.destinationViewController as? DappLinksVC
            self.dappLinkVC?.delegate = self
        }
    }
}

extension EditDappLinksVC: DappLinksVCDelegate {
    func addLink(link: Link, completion: (success: Bool, error: NSError?) -> Void) {
        Requests.uploadLinks([link], completion: { (linkObjs: [PFObject], error: NSError?) -> Void in
            if let linkObj = linkObjs.first {
                let dappLinksRelation = self.dapp?.relationForKey("links")
                dappLinksRelation?.addObject(linkObj)
                
                self.dapp?.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) -> Void in
                    self.links.append(linkObj)
                    
                    completion(success: success, error: error)
                })
            } else {
                completion(success: false, error: nil)
            }
        })
    }
    
    func deleteLinkAtIndex(linkIndex: Int, completion: (success: Bool, error: NSError?) -> Void) {
        if linkIndex < self.links.count {
            if let dapp = self.dapp {
                let linkObj = self.links[linkIndex]
                
                let dappLinksRelation = self.dapp?.relationForKey("links")
                dappLinksRelation?.removeObject(linkObj)
                
                dapp.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) -> Void in
                    self.links.removeAtIndex(linkIndex)
                    
                    self.dappLinkVC?.dappLinksView.linksTableView.reloadData()
                    
                    completion(success: true, error: nil)
                })
            } else {
                completion(success: false, error: nil)
            }
        } else {
            completion(success: false, error: nil)
        }
    }
    
    func linkAtIndex(index: Int) -> Link? {
        if index < self.links.count {
            let linkObj = self.links[index]
            
            var linkURLStr = linkObj["URL"] as? String
            var linkTitle = linkObj["Title"] as? String
            
            if linkTitle == nil {
                linkTitle = ""
            }
            
            let link = Link(URLStr: linkURLStr, title: linkTitle!)
            
            return link
        }
        
        return nil
    }
    
    func linksCount() -> Int {
        return self.links.count
    }
    
    func canDeleteLinks() -> Bool {
        return true
    }
}
