//
//  PagingTableViewController.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 2/6/17.
//  Copyright © 2017 OpenStack. All rights reserved.
//

import Foundation
import UIKit
import CoreSummit

protocol PagingTableViewController: class, UITableViewDataSource, ShowActivityIndicatorProtocol, MessageEnabledViewController {
    
    associatedtype Item
    
    associatedtype ItemCell: UITableViewCell
    
    associatedtype LoadingCell: UITableViewCell
    
    var pageController: PageController<Item> { get }
    
    var tableView: UITableView! { get }
    
    var refreshControl: UIRefreshControl? { get }
    
    func configure(cell cell: ItemCell, with item: Item)
    
    func configure(loadingCell cell: LoadingCell)
    
    func dequeueReusableItemCell(for indexPath: NSIndexPath) -> ItemCell
    
    func dequeueReusableLoadingCell(for indexPath: NSIndexPath) -> LoadingCell
    
    func willLoadData()
    
    func didLoadNextPage(response: ErrorValue<[PageControllerChange]>)
}

extension PagingTableViewController {
    
    func willLoadData() {
        
        if pageController.pages.isEmpty {
            
            showActivityIndicator()
        }
    }
    
    func didLoadNextPage(response: ErrorValue<[PageControllerChange]>) {
        
        hideActivityIndicator()
        
        refreshControl?.endRefreshing()
        
        switch response {
            
        case let .Error(error):
            
            showErrorMessage(error, fileName: #file, lineNumber: #line)
            
        case let .Value(changes):
            
            tableView.beginUpdates()
            
            for change in changes {
                
                let indexPath = NSIndexPath(forRow: change.index, inSection: 0)
                
                switch change.change {
                    
                case .delete:
                    
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    
                case .insert:
                    
                    tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    
                case .update:
                    
                    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                }
            }
            
            tableView.endUpdates()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return pageController.items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let data = pageController.items[indexPath.row]
        
        switch data {
            
        case let .item(item):
            
            let cell = dequeueReusableItemCell(for: indexPath)
            
            configure(cell: cell, with: item)
            
            return cell
            
        case .loading:
            
            pageController.loadNextPage()
            
            let cell = dequeueReusableLoadingCell(for: indexPath)
            
            configure(loadingCell: cell)
            
            return cell
        }
    }
}

#if os(iOS)

    extension PagingTableViewController {
                
        func dequeueReusableLoadingCell(for indexPath: NSIndexPath) -> LoadingTableViewCell {
            
            return tableView.dequeueReusableCellWithIdentifier(R.reuseIdentifier.loadingTableViewCell, forIndexPath: indexPath)!
        }
        
        func configure(loadingCell cell: LoadingTableViewCell) {
            
            cell.activityIndicator.hidden = false
            
            cell.activityIndicator.startAnimating()
        }
    }
    
#endif
