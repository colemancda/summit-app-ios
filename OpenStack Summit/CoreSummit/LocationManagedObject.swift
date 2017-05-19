//
//  LocationManagedObject.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 11/1/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

import Foundation
import CoreData

open class LocationManagedObject: Entity {
    
    @NSManaged open var name: String
    
    @NSManaged open var descriptionText: String?
    
    // Inverse Relationships
    
    @NSManaged open var events: Set<EventManagedObject>
    
    @NSManaged open var summit: SummitManagedObject
}

extension Location: CoreDataDecodable {
    
    public init(managedObject: LocationManagedObject) {
        
        if let venueManagedObject = managedObject as? VenueManagedObject {
            
            let venue = Venue(managedObject: venueManagedObject)
            
            self = .venue(venue)
            
            
        } else if let roomManagedObject = managedObject as? VenueRoomManagedObject {
            
            let room = VenueRoom(managedObject: roomManagedObject)
            
            self = .room(room)
            
        } else {
            
            fatalError("Invalid LocationManagedObject: \(managedObject)")
        }
    }
}

extension Location: CoreDataEncodable {
    
    public func save(_ context: NSManagedObjectContext) throws -> LocationManagedObject {
        
        switch self {
        case let .venue(venue): return try venue.save(context)
        case let .room(room): return try room.save(context)
        }
    }
}
