//
//  DappArraysIndexes.swift
//  DappSign
//
//  Created by Oleksiy Kovtun on 3/18/16.
//  Copyright © 2016 DappSign. All rights reserved.
//

import Foundation

struct DappIndex {
    let parseObjectID: String
    let dappID: String
    let dappsArrayName: String
    let index: Int
}

class DappIndexHelper {
    private static let dappIndexClassName   = "DappIndex"
    private static let dappIDColumn         = "dappID"
    private static let dappsArrayNameColumn = "dappsArrayName"
    private static let indexColumn          = "index"
    
    internal class func downloadDappIndexes(
        completion: (dappIndexes: [DappIndex]?, error: NSError?) -> Void
    ) {
        let query = PFQuery(className: dappIndexClassName)
        
        self.downloadDappIndexesWithQuery(query, downloadedDappIndexes: [], completion: completion)
    }
    
    internal class func downloadDappIndexesForArrayWithName(arrayName: String,
        completion: (dappIndexes: [DappIndex]?, error: NSError?) -> Void
    ) {
        let query = PFQuery(className: dappIndexClassName)
        
        query.whereKey(dappsArrayNameColumn, equalTo: arrayName)
        
        self.downloadDappIndexesWithQuery(query, downloadedDappIndexes: [], completion: completion)
    }
    
    internal class func addDappIndex(dappIndex: DappIndex, completion: (error: NSError?) -> Void
    ) {
        let dappIndexObject = PFObject(className: dappIndexClassName)
        
        dappIndexObject[dappIDColumn] = dappIndex.dappID
        dappIndexObject[dappsArrayNameColumn] = dappIndex.dappsArrayName
        dappIndexObject[indexColumn] = dappIndex.index
        
        dappIndexObject.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if success {
                completion(error: nil)
            } else {
                completion(error: error)
            }
        }
    }
    
    // MARK: -
    
    internal class func removeDappIndexesWithNonUniqueDappIDs(
        dappIndexes: [DappIndex],
        dappArray: DappArray
    ) -> [DappIndex] {
        let dappIDs = dappIndexes.map {
            dappIndex -> String in
            return dappIndex.dappID
        }
        let uniqueDappIDs = ArrayUtil.removeDuplicatesIn(dappIDs)
        let dappIndexesFilteredByArrayName = dappIndexes.filter {
            dappIndex -> Bool in
            return dappIndex.dappsArrayName == dappArray.rawValue
        }
        var newDappIndexes: [DappIndex] = []
        
        for uniqueDappID in uniqueDappIDs {
            let dappIndex = ArrayUtil.findElement({
                dappIndex -> Bool in
                return dappIndex.dappID == uniqueDappID
            }, inArray: dappIndexesFilteredByArrayName)
            
            if let dappIndex = dappIndex {
                newDappIndexes.append(dappIndex)
            }
        }
        
        return newDappIndexes
    }
    
    internal class func removeDappIndexesWithNonUniqueIndexes(
        dappIndexes: [DappIndex],
        dappArray: DappArray
    ) -> [DappIndex] {
        let indexes = dappIndexes.map {
            dappIndex -> Int in
            return dappIndex.index
        }
        let uniqueIndexes = ArrayUtil.removeDuplicatesIn(indexes)
        let dappIndexesFilteredByArrayName = dappIndexes.filter {
            dappIndex -> Bool in
            return dappIndex.dappsArrayName == dappArray.rawValue
        }
        var newDappIndexes: [DappIndex] = []
        
        for uniqueIndex in uniqueIndexes {
            let dappIndex = ArrayUtil.findElement({
                dappIndex -> Bool in
                return dappIndex.index == uniqueIndex
            }, inArray: dappIndexesFilteredByArrayName)
            
            if let dappIndex = dappIndex {
                newDappIndexes.append(dappIndex)
            }
        }
        
        return newDappIndexes
    }
    
    internal class func dappIndexesInSequence(dappIndexes: [DappIndex]) -> [DappIndex] {
        let sortedDappIndexes = dappIndexes.sort {
            (dappIndex1, dappIndex2) -> Bool in
            return dappIndex1.index < dappIndex2.index
        }
        var dappIndexesSequence: [DappIndex] = []
        var expectedIndex = 0
        
        for dappIndex in sortedDappIndexes {
            if dappIndex.index == expectedIndex {
                dappIndexesSequence.append(dappIndex)
                
                ++expectedIndex
            } else {
                break
            }
        }
        
        return dappIndexesSequence
    }
    
    // MARK: - private
    
    private class func downloadDappIndexesWithQuery(query: PFQuery,
        downloadedDappIndexes: [DappIndex],
        completion: (dappIndexes: [DappIndex]?, error: NSError?) -> Void
    ) {
        query.skip = downloadedDappIndexes.count
        query.limit = 1000
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if let dappIndexObjects = objects as? [PFObject] {
                if dappIndexObjects.count > 0 {
                    let dappIndexes = self.dappIndexesWithDappIndexObjects(dappIndexObjects)
                    
                    self.downloadDappIndexesWithQuery(query,
                        downloadedDappIndexes: downloadedDappIndexes + dappIndexes,
                        completion: completion
                    )
                } else {
                    completion(dappIndexes: downloadedDappIndexes, error: nil)
                }
            } else {
                completion(dappIndexes: nil, error: error)
            }
        }
    }
    
    private class func dappIndexesWithDappIndexObjects(
        dappIndexObjects: [PFObject]
    ) -> [DappIndex] {
        let dappIndexes = dappIndexObjects.map({
            (dappIndexObject: PFObject) -> DappIndex? in
            self.dappIndexWithDappIndexObject(dappIndexObject)
        }).filter ({
            (dappIndexOption: DappIndex?) -> Bool in
            if let _ = dappIndexOption {
                return true
            }
            
            return false
        }).map({
            (dappIndexOption: DappIndex?) -> DappIndex in
            dappIndexOption!
        })
        
        return dappIndexes
    }
    
    private class func dappIndexWithDappIndexObject(dappIndexObject: PFObject) -> DappIndex? {
        if let
            dappID = dappIndexObject[dappIDColumn] as? String,
            dappsArrayName = dappIndexObject[dappsArrayNameColumn] as? String,
            index = dappIndexObject[indexColumn] as? Int {
                let dappIndex = DappIndex(
                    parseObjectID: dappIndexObject.objectId,
                    dappID: dappID,
                    dappsArrayName: dappsArrayName,
                    index: index
                )
                
                return dappIndex
        }
        
        return nil
    }
}
