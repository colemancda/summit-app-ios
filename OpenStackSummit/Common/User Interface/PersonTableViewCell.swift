////
////  PersonTableViewCell.swift
////  OpenStackSummit
////
////  Created by Claudio on 10/22/15.
////  Copyright © 2015 OpenStack. All rights reserved.
////
//
//import UIKit
//
//@objc
//public protocol IPersonTableViewCell : class {
//    var name: String! { get set }
//    var title: String! { get set }
//    var picUrl: String! { get set }
//}
//
//class PersonTableViewCell: UITableViewCell, IPersonTableViewCell {
//    var name: String!{
//        get {
//            return nameLabel.text
//        }
//        set {
//            nameLabel.text = newValue
//        }
//    }
//    
//    var title: String!{
//        get {
//            return titleLabel.text
//        }
//        set {
//            titleLabel.text = newValue
//        }
//    }
//    
//    var picUrl: String! {
//        get {
//            return picUrlInternal
//        }
//        set {
//            //picUrlInternal = newValue
//            picUrlInternal = newValue.stringByReplacingOccurrencesOfString("https", withString: "http", options: NSStringCompareOptions.LiteralSearch, range: nil)
//            if (!picUrlInternal.isEmpty) {
//                pictureImageView.hnk_setImageFromURL(NSURL(string: picUrlInternal)!)
//            }
//            else {
//                pictureImageView.hnk_setImageFromURL(NSURL(string: "https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcQsKM4aXdIlZmlLHSonqBq9UsESy4WQidH3Dqa3NeeL4qgPzAq70w")!)
//            }
//            pictureImageView.layer.cornerRadius = pictureImageView.frame.size.width / 2
//            pictureImageView.clipsToBounds = true;
//        }
//    }
//    
//    @IBOutlet weak var nameLabel : UILabel!
//    @IBOutlet weak var titleLabel : UILabel!
//    @IBOutlet weak var pictureImageView: UIImageView!
//    private var picUrlInternal: String!
//    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//    }
//    
//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//        
//        // Configure the view for the selected state
//    }
//}
