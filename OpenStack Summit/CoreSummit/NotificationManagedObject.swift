//
//  NotificationManagedObject.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 12/5/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

import Foundation
import CoreData

public final class NotificationManagedObject: NSManagedObject {
    
    @NSManaged public var date: NSDate
    
    @NSManaged public var message: String
    
    @NSManaged public var user: NSNumber?
    
    @NSManaged public var uid: String
}