//
//  DailyDappHelper.swift
//  DappSign
//
//  Created by Oleksiy Kovtun on 3/9/16.
//  Copyright © 2016 DappSign. All rights reserved.
//

import Foundation

class DailyDappHelper {
    private static let dailyDappClass   = "DailyDapp"
    private static let dateKey          = "date"
    private static let timeZoneKey      = "timeZone"
    private static let dappsRelationKey = "dapps"
    
    internal class func addDapp(
        dapp: PFObject,
        completion: (error: NSError?) -> Void
    ) {
        let localTimeZone = NSTimeZone.localTimeZone()
        
        if let localTimeZoneName = localTimeZone.localizedName(.ShortStandard, locale: nil) {
            let dateString = self.currentDateString()
            
            self.findDailyDappWithDate(dateString, timeZone: localTimeZoneName) {
                (dailyDapp: PFObject?, error: NSError?) -> Void in
                if let dailyDapp = dailyDapp {
                    self.addDapp(dapp, toDailyDapp: dailyDapp, completion: completion)
                } else if let error = error {
                    completion(error: error)
                } else {
                    self.addDailyDappWithDate(dateString, timeZone: localTimeZoneName) {
                        (dailyDapp: PFObject?, error: NSError?) -> Void in
                        if let dailyDapp = dailyDapp {
                            self.addDapp(dapp, toDailyDapp: dailyDapp, completion: completion)
                        } else {
                            completion(error: error)
                        }
                    }
                }
            }
        } else {
            let userInfo = [NSLocalizedDescriptionKey: "Unknown time zone."]
            let error = NSError(domain: "DailyDapp", code: 0, userInfo: userInfo)
            
            completion(error: error)
        }
    }
    
    private class func currentDateString() -> String {
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let dateString = dateFormatter.stringFromDate(date)
        
        return dateString
    }
    
    private class func addDapp(
        dapp: PFObject,
        toDailyDapp dailyDapp: PFObject,
        completion: (error: NSError?) -> Void
    ) {
        let dappsRelation = dailyDapp.relationForKey(dappsRelationKey)
        
        dappsRelation.addObject(dapp)
        
        dailyDapp.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                completion(error: nil)
            } else {
                completion(error: error)
            }
        }
    }
    
    private class func findDailyDappWithDate(
        date: String,
        timeZone: String,
        completion: (dailyDapp: PFObject?, error: NSError?) -> Void
    ) {
        let query = PFQuery(className: dailyDappClass)
        
        query.whereKey(dateKey, equalTo: date)
        query.whereKey(timeZoneKey, equalTo: timeZone)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if let dailyDapps = objects as? [PFObject] {
                if let dailyDapp = dailyDapps.first {
                    completion(dailyDapp: dailyDapp, error: error)
                } else {
                    completion(dailyDapp: nil, error: error)
                }
            } else {
                completion(dailyDapp: nil, error: error)
            }
        }
    }
    
    private class func addDailyDappWithDate(
        date: String,
        timeZone: String,
        completion: (dailyDapp: PFObject?, error: NSError?) -> Void
    ) {
        let dailyDapp = PFObject(className: dailyDappClass)
        
        dailyDapp[dateKey] = date
        dailyDapp[timeZoneKey] = timeZone
        
        dailyDapp.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                completion(dailyDapp: dailyDapp, error: nil)
            } else {
                completion(dailyDapp: nil, error: error)
            }
        }
    }
}
