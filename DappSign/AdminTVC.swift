//
//  AdminTVC.swift
//  DappSign
//
//  Created by Oleksiy Kovtun on 3/13/15.
//  Copyright (c) 2015 DappSign. All rights reserved.
//

import UIKit

class AdminTVC: UITableViewController {
    var dappArrayDappsCount: [DappArray: Int32?] = [
        .Primary:      nil,
        .Secondary:    nil,
        .Introductory: nil,
        .Scoreboard:   nil
    ]
    
    let rowDappArray: [Int: DappArray] = [
        0: .Primary,
        1: .Secondary,
        2: .Introductory,
        3: .Scoreboard
    ]
    
    enum SegueIdentifier: String {
        case ShowPrimaryDapps      = "showPrimaryDapps"
        case ShowSecondaryDapps    = "showSecondaryDapps"
        case ShowIntroductoryDapps = "showIntroductoryDapps"
        case ShowScoreboardDapps   = "showScoreboardDapps"
    }
    
    enum Section: Int {
        case Dapps = 0
        case DailyDappTime = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let font = UIFont(name: "Exo-Regular", size: 18.0) {
            self.navigationController?.navigationBar.titleTextAttributes = [
                NSFontAttributeName: font
            ]
        }
        
        if let font = UIFont(name: "Exo-Regular", size: 16.0) {
            self.navigationItem.leftBarButtonItem?.setTitleTextAttributes(
                [NSFontAttributeName: font],
                forState: .Normal
            )
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        for (dappArray, _) in self.dappArrayDappsCount {
            self.dappArrayDappsCount[dappArray] = nil
        }
        
        self.refreshTableViewContent()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - <UITableViewDataSource>
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return super.numberOfSectionsInTableView(tableView)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath
    ) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        
        if (indexPath.section == Section.Dapps.rawValue) {
            if let dappArray = self.rowDappArray[indexPath.row] {
                self.showDappCountInCell(cell, dappArray: dappArray)
            }
        } else {
            if let dailyDappStartTime = LocalStorage.dailyDappStartTime() {
                let (hour, minute) = dailyDappStartTime
                
                let dateFormatter = NSDateFormatter()
                
                dateFormatter.dateFormat = "HH:mm"
                
                if let date = dateFormatter.dateFromString("\(hour):\(minute)") {
                    dateFormatter.dateFormat = "hh:mm a"
                    
                    let dateString = dateFormatter.stringFromDate(date)
                    
                    cell.textLabel?.text = "\(dateString) (\(hour):\(minute))"
                } else {
                    cell.textLabel?.text = "\(hour):\(minute)"
                }
            } else {
                cell.textLabel?.text = "12:00"
            }
        }
        
        return cell
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        switch identifier {
        case SegueIdentifier.ShowPrimaryDapps.rawValue:
            return self.shouldPerformSegueToShowDappsWithType(.Primary)
        case SegueIdentifier.ShowSecondaryDapps.rawValue:
            return self.shouldPerformSegueToShowDappsWithType(.Secondary)
        case SegueIdentifier.ShowIntroductoryDapps.rawValue:
            return self.shouldPerformSegueToShowDappsWithType(.Introductory)
        default:
            return true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segueIdentifier = segue.identifier {
            var dappsType: DappArray?
            
            switch segueIdentifier {
            case SegueIdentifier.ShowPrimaryDapps.rawValue:
                dappsType = .Primary
            case SegueIdentifier.ShowSecondaryDapps.rawValue:
                dappsType = .Secondary
            case SegueIdentifier.ShowIntroductoryDapps.rawValue:
                dappsType = .Introductory
            case SegueIdentifier.ShowScoreboardDapps.rawValue:
                dappsType = .Scoreboard
            default:
                break
            }
            
            if let dappsType = dappsType {
                let dappsTVC = segue.destinationViewController as! DappsTableViewController
                
                dappsTVC.dappsArray = dappsType
            }
        }
    }
    
    // MARK: - 
    
    private func shouldPerformSegueToShowDappsWithType(dappType: DappArray) -> Bool {
        if let count = self.dappArrayDappsCount[dappType] {
            if count > 0 {
                return true
            }
        }
        
        return false
    }
    
    private func showDappCountInCell(cell: UITableViewCell, dappArray: DappArray?) -> Void {
        if let
            dappArray = dappArray,
            dappsCount = self.dappArrayDappsCount[dappArray],
            count = dappsCount {
                if count > 0 {
                    cell.detailTextLabel?.text = String(count)
                } else if count == 0 {
                    cell.detailTextLabel?.text = "0"
                } else if count < 0 {
                    cell.detailTextLabel?.text = "-"
                }
                
                if count > 0 {
                    cell.accessoryType = .DisclosureIndicator
                    cell.selectionStyle = .Default
                } else {
                    cell.accessoryType = .None
                    cell.selectionStyle = .None
                }
        } else {
            cell.detailTextLabel?.text = "-"
            cell.accessoryType = .None
            cell.selectionStyle = .None
        }
    }
    
    private func refreshTableViewContent() -> Void {
        self.tableView.reloadData()
        
        self.refreshTableViewContentForDappArray(.Primary)
        self.refreshTableViewContentForDappArray(.Secondary)
        self.refreshTableViewContentForDappArray(.Introductory)
        self.refreshTableViewContentForDappArray(.Scoreboard)
    }
    
    private func refreshTableViewContentForDappArray(dappArray: DappArray) -> Void {
        DappArraysHelper.countDappsInArray(dappArray) {
            (dappsCount: Int32?, error: NSError?) -> Void in
            if let dappsCount = dappsCount {
                self.dappArrayDappsCount[dappArray] = dappsCount
                
                if let row = self.rowForDappArray(dappArray) {
                    let cellIndexPath = NSIndexPath(forRow: row, inSection: 0)
                    
                    self.tableView.reloadRowsAtIndexPaths([cellIndexPath], withRowAnimation: .None)
                }
            } else {
                print(error)
            }
        }
    }
    
    private func rowForDappArray(dappArray: DappArray) -> Int? {
        for (rowKey, dappArrayValue) in rowDappArray {
            if dappArrayValue == dappArray {
                return rowKey
            }
        }
        
        return nil
    }
}
