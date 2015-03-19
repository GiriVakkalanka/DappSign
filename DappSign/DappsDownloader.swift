//
//  DappsDownloader.swift
//  DappSign
//
//  Created by Oleksiy Kovtun on 3/17/15.
//  Copyright (c) 2015 DappSign. All rights reserved.
//

import Foundation

class DappsDownloader {
    typealias downloadCompletionClosureWithError = (error: NSError!) -> Void
    typealias downloadCompletionClosureWithDappsAndError = (dapps: [PFObject], error: NSError!) -> Void
    
    private var dappsType: DappType!
    private var dapps: [PFObject]
    
    init(type: DappType) {
        self.dappsType = type
        self.dapps = []
    }
    
    internal func downloadDappsNotSwipedByUser(user: PFUser, completion: downloadCompletionClosureWithDappsAndError) {
        self.dapps = []
        
        var query = DappQueriesBuilder.queryForAllDapsNotSwipedByUser(self.dappsType, user: user)
        
        self.downloadDappsWithQuery(query, completion: {
            (dapps: [PFObject], error: NSError!) -> Void in
            completion(dapps: self.dapps, error: error)
        })
    }
    
    internal func downloadAllDapps(completion: downloadCompletionClosureWithDappsAndError) {
        self.dapps = []
        
        var query = DappQueriesBuilder.queryForAllDappsOfType(self.dappsType)
        
        self.downloadDappsWithQuery(query, completion: {
            (dapps: [PFObject], error: NSError!) -> Void in
            completion(dapps: self.dapps, error: error)
        })
    }
    
    private func downloadDappsWithQuery(query: PFQuery?, completion: downloadCompletionClosureWithDappsAndError) {
        if let dappsType = self.dappsType {
            switch dappsType {
            case .Primary:
                self.downloadDappsWithLimit(primaryDappsMaxCount,
                    query: query,
                    completion: {
                        (error: NSError!) -> Void in
                        self.dapps = PrimaryDapps.sortDapps(self.dapps)
                        
                        completion(dapps: self.dapps, error: error)
                    }
                )
            case .Secondary:
                self.downloadAllDappsWithQuery(query, {
                    (error: NSError!) -> Void in
                    
                    sort(&self.dapps, {
                        (dapp1: PFObject, dapp2: PFObject) -> Bool in
                        return dapp1["dappScore"] as? Int > dapp2["dappScore"] as? Int
                    })
                    
                    completion(dapps: self.dapps, error: error)
                })
            case .Unapproved:
                self.downloadAllDappsWithQuery(query, {
                    (error: NSError!) -> Void in
                    completion(dapps: self.dapps, error: error)
                })
            }
        } else {
            let error = NSError(
                domain: "Dapps type",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Dapps type is not set."])
            
            completion(dapps: self.dapps, error: error)
        }
    }
    
    private func downloadDappsWithLimit(limit: Int, query: PFQuery?, completion: downloadCompletionClosureWithError) {
        query?.limit = limit
        
        query?.orderByAscending("createdAt")
        query?.findObjectsInBackgroundWithBlock({
            (objects: [AnyObject]!, error: NSError!) -> Void in
            if error != nil {
                completion(error: error)
                
                return
            }
            
            self.dapps = objects as [PFObject]
            
            completion(error: nil)
        })
    }
    
    private func downloadAllDappsWithQuery(query: PFQuery?, completion: downloadCompletionClosureWithError) {
        query?.orderByAscending("createdAt")
        
        query?.skip = self.dapps.count
        query?.limit = 1000
        
        query?.findObjectsInBackgroundWithBlock({
            (objects: [AnyObject]!, error: NSError!) -> Void in
            if error != nil {
                completion(error: error)
                
                return
            }
            
            let dapps = objects as [PFObject]
            
            for dapp in dapps {
                self.dapps.append(dapp)
            }
            
            if dapps.count == query?.limit {
                self.downloadAllDappsWithQuery(query, completion: completion)
            } else {
                completion(error: nil)
            }
        })
    }
}
