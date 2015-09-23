//
//  Requests.swift
//  DappSign
//
//  Created by Oleksiy Kovtun on 3/19/15.
//  Copyright (c) 2015 DappSign. All rights reserved.
//

import Foundation

class Requests {
    class func uploadHashtags(hashtagNames: [String], completion: (hashtags: [PFObject]?, error: NSError!) -> Void) {
        let lowercaseHashtagNames = hashtagNames.map({ $0.lowercaseString })
        let hashtagsQuery = PFQuery(className: "DappHashtag")
        
        hashtagsQuery.whereKey("lowercaseName", containedIn: lowercaseHashtagNames)
        hashtagsQuery.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            if error != nil {
                completion(hashtags: nil, error: error)
                
                return
            }
            
            var hashtagsOnTheServer = objects as! [PFObject]
            
            let hashtagsOnTheServerLowercaseNames = hashtagsOnTheServer.filter({
                $0["lowercaseName"] != nil
            }).map({
                $0["lowercaseName"]! as! String
            })
            
            let hashtagNamesForUploading = hashtagNames.filter({
                !hashtagsOnTheServerLowercaseNames.contains($0.lowercaseString)
            })
            
            if hashtagNamesForUploading.count > 0 {
                self.uploadHashtags(hashtagNamesForUploading, successfullyUploadedHashtag: {
                    (hashtag: PFObject) -> Void in
                    hashtagsOnTheServer.append(hashtag)
                }, finishedUploadingHashtags: {
                    () -> Void in
                    completion(hashtags: hashtagsOnTheServer, error: nil)
                })
            } else {
                completion(hashtags: hashtagsOnTheServer, error: nil)
            }
        }
    }
    
    class func uploadLinks(links: [Link], completion: (linkObjs: [PFObject], error: NSError?) -> Void) {
        var linksUploaded = 0
        var linksError: NSError? = nil
        var linksObjs: [PFObject] = []
        
        for link in links {
            let dappLink = PFObject(className: "DappLink")
            dappLink["Title"] = link.title
            dappLink["URL"] = link.URLStr
            
            dappLink.saveInBackgroundWithBlock({ (success: Bool, error: NSError!) -> Void in
                if success {
                    linksObjs.append(dappLink)
                } else {
                    linksError = error
                }
                
                ++linksUploaded
                
                if linksUploaded == links.count {
                    completion(linkObjs: linksObjs, error: linksError)
                }
            })
        }
    }
    
    class func downloadHashtagsWithNameWhichContains(nameSubstring: String, completion: (hashtags: [PFObject], error: NSError!) -> Void) {
        let hashtagsQuery = PFQuery(className: "DappHashtag")
        hashtagsQuery.limit = 1000
        
        hashtagsQuery.whereKey("lowercaseName", containsString: nameSubstring.lowercaseString)
        
        hashtagsQuery.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            completion(hashtags: objects as! [PFObject], error: error)
        }
    }
    
    class func downloadDappsWithStatementWhichContains(statementSubstring: String, notSwipedByUser user: PFUser, completion: (dapps: [PFObject], error: NSError!) -> Void) {
        let query = DappQueriesBuilder.queryForAllDappsNotSwipedByUser(user,
            dappStatementSubstring: statementSubstring
        )
        query?.limit = 1000
        
        query?.whereKey("lowercaseDappStatement", containsString: statementSubstring.lowercaseString)
        
        query?.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            completion(dapps: objects as! [PFObject], error: error)
        }
    }
    
    class func downloadUsersWithNameWhichContains(nameSubstring: String, completion: (users: [PFUser], error: NSError!) -> Void) {
        let usersQuery = PFUser.query()
        usersQuery.limit = 1000
        
        usersQuery.whereKey("lowercaseName", containsString: nameSubstring.lowercaseString)
        
        usersQuery.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            completion(users: objects as! [PFUser], error: error)
        }
    }
    
    class func downloadUsersWhoDapped(dapp: PFObject, completion: (objects: [AnyObject]!, error: NSError!) -> Void) {
        let query = PFUser.query()
        query.whereKey("dappsDapped", equalTo: dapp)
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            completion(objects: objects, error: error)
        }
    }
    
    class func downloadDappsCreatedByUserWithId(userId: String, completion: (dapps: [PFObject], error: NSError!) -> Void) {
        let query = PFQuery(className: "Dapps")
        
        query.whereKey("userid", equalTo: userId)
        query.whereKey("isDeleted", notEqualTo: true)
        query.orderByDescending("createdAt")
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            completion(dapps: objects as! [PFObject], error: error)
        }
    }
    
    class func downloadDappsSwipedByUser(user: PFUser, completion: (dapps: [PFObject], error: NSError!) -> Void) {
        let relation = user.relationForKey("dappsSwiped")
        let query = relation.query()
        
        query.limit = 1000
        
        query.whereKey("isDeleted", notEqualTo: true)
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            completion(dapps: objects as! [PFObject], error: error)
        }
    }
    
    class func userWithID(userID: String, completion: (user: PFUser?, error: NSError?) -> Void) {
        let userQuery = PFUser.query()
        
        userQuery.whereKey("objectId", equalTo: userID)
        userQuery.findObjectsInBackgroundWithBlock({
            (objects: [AnyObject]!, error: NSError!) -> Void in
            let user = objects.first as? PFUser
            
            completion(user: user, error: error);
        })
    }
    
    class func downloadDappsDappedByUser(user: PFUser, completion: (dapps: [PFObject], error: NSError!) -> Void) {
        let relation = user.relationForKey("dappsDapped")
        
        let query = relation.query()
        query.whereKey("isDeleted", notEqualTo: true)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            completion(dapps: objects as! [PFObject], error: error)
        }
    }
    
    class func addDappToDappsSwipedArray(dapp: PFObject, user: PFUser, completion: (succeeded: Bool, error: NSError?) -> Void) -> Void {
        let dappsSwipedRelation = user.relationForKey(dappsSwipedRelationKey)
        
        dappsSwipedRelation.addObject(dapp)
        
        user.saveInBackgroundWithBlock {
            (succeeded: Bool, error: NSError!) -> Void in
            completion(succeeded: succeeded, error: error)
        }
    }
    
    class func addDappToDappsDappedArray(dapp: PFObject, user: PFUser, completion: (succeeded: Bool, error: NSError?) -> Void) -> Void {
        let dappsDappedRelation = user.relationForKey(dappsDappedRelationKey)
        
        dappsDappedRelation.addObject(dapp)
        
        user.saveInBackgroundWithBlock {
            (succeeded: Bool, error: NSError!) -> Void in
            completion(succeeded: succeeded, error: error)
        }
    }
    
    class func incrementScoreOfTheDapp(dapp: PFObject, completion: (succeeded: Bool, error: NSError!) -> Void) {
        if let dappScore = dapp["dappScore"] as? Int {
            dapp["dappScore"] = dappScore + 1
        } else {
            dapp["dappScore"] = 2 // (undefined) + 1
        }
        
        dapp.saveInBackgroundWithBlock({
            (succeeded: Bool, error: NSError!) -> Void in
            completion(succeeded: succeeded, error: error)
        })
    }
    
    class func downloadDappsNotSwipedByUser(user: PFUser, hashtag: PFObject, completion: (dapps: [PFObject]?, error: NSError?) -> Void) {
        if let dappsQuery = DappQueriesBuilder.queryForDownloadingDappsNotSwipedByUser(user, withHashtag: hashtag) {
            dappsQuery.whereKey("hashtags", containedIn: [hashtag])
            
            dappsQuery.findObjectsInBackgroundWithBlock({
                (objects: [AnyObject]!, error: NSError!) -> Void in
                if error != nil {
                    completion(dapps: nil, error: error)
                    
                    return
                }
                
                let dapps = objects as! [PFObject]
                
                completion(dapps: dapps, error: nil)
            })
        } else {
            var userInfo: [String: String]
            
            if let hashtagName = hashtag["name"] as? String {
                userInfo = [NSLocalizedDescriptionKey: "Failed to create query for downloading dapps with hashtag #\(hashtagName)."]
            } else {
                userInfo = [NSLocalizedDescriptionKey: "Failed to create query for downloading dapps with hashtag #<unknown name>."]
            }
            
            let error = NSError(
                domain: "Dapps type",
                code: 0,
                userInfo: userInfo
            )
            
            completion(dapps: nil, error: error)
        }
    }
    
    class func downloadDappScoreForUserWithId(userId: String, completion: (dappScore: Int?, error: NSError?) -> Void) {
        let query = PFQuery(className: "UserIdDappScore")
        
        query.whereKey("userId", equalTo: userId)
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            if error != nil {
                completion(dappScore: nil, error: error)
                
                return
            }
            
            if let userIdDappScore = objects.first as? PFObject {
                let dappScore = userIdDappScore["dappScore"] as? Int
                
                completion(dappScore: dappScore, error: error)
            } else {
                let userInfo = [NSLocalizedDescriptionKey: "UserIdDappScore array is nil or empty."]
                let error = NSError(
                    domain: "UserIdDappScore",
                    code: 0,
                    userInfo: userInfo
                )
                
                completion(dappScore: nil, error: error)
            }
        }
    }
    
    class func addUserIdDappScore(userId: String) {
        let query = PFQuery(className: "UserIdDappScore")
        
        query.whereKey("userId", equalTo: userId)
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            if error != nil || objects.count > 0 {
                return
            }
            
            let userIdDappScore = PFObject(className: "UserIdDappScore")
            
            userIdDappScore["userId"] = userId
            userIdDappScore["dappScore"] = 0
            
            userIdDappScore.saveInBackgroundWithBlock({
                (succeeded: Bool, error: NSError!) -> Void in
            })
        }
    }
    
    class func addRepresentative(userId: String, imgUrl: String, strName : String, strTitle : String, strParty : String) {
        
        let userIdDappScore = PFObject(className: "UserRepresentatives")
        
        userIdDappScore["UserID"] = userId
        userIdDappScore["imgUrl"] = imgUrl
        userIdDappScore["Name"] = strName
        userIdDappScore["Title"] = strTitle
        userIdDappScore["Party"] = strParty
        
        userIdDappScore.saveInBackgroundWithBlock({
            (succeeded: Bool, error: NSError!) -> Void in
        })
    }
    
    class func incrementDappScoreForUserWithId(userId: String, completion: (succeeded: Bool, error: NSError?) -> Void) {
        let query = PFQuery(className: "UserIdDappScore")
        
        query.whereKey("userId", equalTo: userId)
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            if error != nil {
                completion(succeeded: false, error: error)
                
                return
            }
            
            if let userIdDappScore = objects.first as? PFObject {
                let dappScoreKey = "dappScore"
                
                if let dappScore = userIdDappScore[dappScoreKey] as? Int {
                    userIdDappScore[dappScoreKey] = dappScore + 1
                } else {
                    userIdDappScore[dappScoreKey] = 1
                }
                
                userIdDappScore.saveInBackgroundWithBlock({
                    (succeeded: Bool, error: NSError!) -> Void in
                    completion(succeeded: succeeded, error: error)
                })
            } else {
                let userInfo = [NSLocalizedDescriptionKey: "UserIdDappScore array is nil."]
                let error = NSError(
                    domain: "Users",
                    code: 0,
                    userInfo: userInfo
                )
                
                completion(succeeded: false, error: error)
            }
        }
    }
    
    class func downloadCongressialDistrictsForZipCode(zipCode: String, completion: (data: NSData!, error: NSError!) -> Void) {
        let APIKey = "a01b4a2e39e044d78d8e5cd18e78fefb"
        let URLStr = "http://congress.api.sunlightfoundation.com/districts/locate?zip=\(zipCode)&apikey=\(APIKey)"
        
        if let URL = NSURL(string: URLStr) {
            let request = NSURLRequest(URL: URL)
            let queue = NSOperationQueue.mainQueue()
            
            NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: {
                (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                completion(data: data, error: error)
            })
        }
    }
    
    class func addUserToUsersWhoSaw(dapp: PFObject, user: PFUser, completion: (succeeded: Bool, error: NSError!) -> Void) {
        let relation = dapp.relationForKey("usersWhoSawIt")
        
        relation.addObject(user)
        
        dapp.saveInBackgroundWithBlock {
            (succeeded: Bool, error: NSError!) -> Void in
            completion(succeeded: succeeded, error: error)
        }
    }
    
    class func percents(dapp: PFObject, completion: (usersDapped: [PFUser:Bool]?, error: NSError?) -> Void) {
        let relation = dapp.relationForKey("usersWhoSawIt")
        
        let query = relation.query()
        query.limit = 1000
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            if let err = error {
                print("error = \(err)")
                
                completion(usersDapped: nil, error: error)
                
                return
            }
            
            if let users = objects as? [PFUser] {
                self.downloadDappsDapped(dapp, users: users, userIndex: 0, usersDapped: [:], completion: {
                    (usersDapped: [PFUser:Bool]) -> Void in
                    completion(usersDapped: usersDapped, error: nil)
                })
            } else {
                completion(usersDapped: nil, error: nil)
            }
        }
    }
    
    class func downloadDappsDapped(dapp: PFObject, users: [PFUser], userIndex: Int, var usersDapped: [PFUser:Bool], completion: (usersDapped: [PFUser:Bool]) -> Void) {
        if (userIndex > users.count - 1 || userIndex < 0) {
            completion(usersDapped: usersDapped)
            
            return
        }
        
        let user = users[userIndex]
        
        Requests.downloadDappsDappedByUser(user, completion: {
            (dapps: [PFObject], error: NSError!) in
            var dappSwiped = false
            
            if let dappStatement1 = dapp["dappStatement"] as? String {
                for dapp in dapps {
                    if let dappStatement2 = dapp["dappStatement"] as? String {
                        if dappStatement1 == dappStatement2 {
                            dappSwiped = true
                            
                            break
                        }
                    }
                }
            }
            
            usersDapped[user] = dappSwiped
            
            self.downloadDappsDapped(
                dapp
            ,   users: users
            ,   userIndex: userIndex + 1
            ,   usersDapped: usersDapped
            ,   completion: completion
            )
        })
    }
    
    class func downloadRepresentativesForUserWithID(userID: String, completion: (representatives: [PFObject]?, error: NSError?) -> Void) {
        let query = PFQuery(className: "UserRepresentatives")
        query.whereKey("UserID", equalTo: userID)
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            completion(representatives: objects as? [PFObject], error: error)
        }
    }
    
    class func downloadImageFromURL(URL: NSURL, completion: (image: UIImage?, error: NSError?) -> Void) {
        let request = NSURLRequest(URL: URL)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
            (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
            if let data = data {
                let image = UIImage(data: data)
                
                completion(image: image, error: nil)
            } else {
                completion(image: nil, error: error)
            }
        }
    }
    
    class func downloadDataFromURL(URL: NSURL, completion: (data: NSData?, error: NSError?) -> Void) {
        let request = NSURLRequest(URL: URL)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
            (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
            completion(data: data, error: error)
        }
    }
    
    class func downloadLinksForDapp(dapp: PFObject
    ,   completion: (links: [PFObject]?, error: NSError?) -> Void) -> Void {
        let query = dapp.relationForKey("links").query()
        query.orderByAscending("createdAt")
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            let links = objects as? [PFObject]
            
            completion(links: links, error: error)
        }
    }
    
    // MARK: -
    
    private class func downloadHashtagWthName(name: String, completion: (hashtag: PFObject?, error: NSError!) -> Void) {
        let hashtagQuery = PFQuery(className: "DappHashtag")
        
        hashtagQuery.whereKey("lowercaseName", equalTo: name.lowercaseString)
        
        hashtagQuery.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            let hashtags = objects as? [PFObject]
            let hashtag = hashtags?.first
            
            completion(hashtag: hashtag, error: error)
        }
    }
    
    private class func uploadHashtags(hashtagNames: [String], successfullyUploadedHashtag: (hashtag: PFObject) -> Void, finishedUploadingHashtags: () -> Void) {
        var hashtagsLeft = hashtagNames.count
        
        for hashtagName in hashtagNames {
            self.uploadHashtagWithName(hashtagName, completion: {
                (hashtag: PFObject?, error: NSError!) -> Void in
                --hashtagsLeft
                
                if error != nil {
                    print(error)
                } else {
                    if let hashtag = hashtag {
                        successfullyUploadedHashtag(hashtag: hashtag)
                    }
                }
                
                if hashtagsLeft == 0 {
                    finishedUploadingHashtags()
                }
            })
        }
    }
    
    private class func uploadHashtagWithName(hashtagName: String, completion: (hashtag: PFObject?, error: NSError!) -> Void) {
        let hashtag = PFObject(className: "DappHashtag")
        hashtag["name"] = hashtagName
        hashtag["lowercaseName"] = hashtagName.lowercaseString
        
        hashtag.saveInBackgroundWithBlock {
            (succeded: Bool, error: NSError!) -> Void in
            if error != nil {
                completion(hashtag: nil, error: error)
                
                return
            }
            
            completion(hashtag: hashtag, error: nil)
        }
    }
}
