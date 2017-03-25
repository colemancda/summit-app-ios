//
//  GeneralScheduleFilterViewController.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 3/24/17.
//  Copyright © 2017 OpenStack. All rights reserved.
//

import UIKit
import SwiftFoundation
import CoreSummit

final class GeneralScheduleFilterViewController: UITableViewController {
    
    // MARK: - Properties
    
    
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup table view
        tableView.estimatedRowHeight = 48
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // https://github.com/mac-cain13/R.swift/issues/144
        tableView.registerNib(R.nib.tableViewHeaderViewLight(), forHeaderFooterViewReuseIdentifier: TableViewHeaderView.resuseIdentifier)
    }
    
    // MARK: - Actions
    
    @IBAction func filterChanged(sender: UISwitch) {
        
        
    }
    
    // MARK: - Private Methods
    
    private func configureView() {
        
        
    }
}

// MARK: - Supporting Types

final class GeneralScheduleFilterTableViewCell: UITableViewCell {
    
    @IBOutlet private(set) weak var circleView: UIView!
    @IBOutlet private(set) weak var nameLabel: UILabel!
    @IBOutlet private(set) weak var enabledSwitch: UISwitch!
}
