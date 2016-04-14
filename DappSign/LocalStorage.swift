//
//  LocalDataStorage.swift
//  DappSign
//
//  Created by Oleksiy Kovtun on 4/14/16.
//  Copyright © 2016 DappSign. All rights reserved.
//

import UIKit

typealias Time = (Int, Int)

class LocalStorage {
    private static let _KeyDailyDappStartTime = "dailyDappStartTime"
    
    internal class func dailyDappStartTime() -> Time? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let timeString = userDefaults.objectForKey(_KeyDailyDappStartTime) as? String {
            print(timeString)
            
            let components = timeString.componentsSeparatedByString(":")
            
            if components.count == 2 {
                let hourString = components[0]
                let minuteString = components[1]
                
                if let hour = Int(hourString), minute = Int(minuteString) {
                    let time = (hour, minute)
                    
                    return time
                }
            }
        }
        
        return nil
    }
    
    internal class func saveDailyDappStartTime(time: Time) {
        let (hour, minute) = time
        let timeString = "\(hour):\(minute)"
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        userDefaults.setObject(timeString, forKey: _KeyDailyDappStartTime)
        userDefaults.synchronize()
    }
}
