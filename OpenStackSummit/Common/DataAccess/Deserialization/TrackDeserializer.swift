//
//  trackIdDeserializer.swift
//  OpenStackSummit
//
//  Created by Claudio on 8/17/15.
//  Copyright © 2015 OpenStack. All rights reserved.
//

import UIKit
import SwiftyJSON

public class TrackDeserializer: NamedEntityDeserializer, IDeserializer {
    var deserializerStorage: DeserializerStorage!
    
    public func deserialize(json : JSON) throws -> BaseEntity {
        
        let track: Track
        
        if let trackId = json.int {
            track = deserializerStorage.get(trackId)
        }
        else {
            try validateRequiredFields(["id", "name"], inJson: json)
            
            track = super.deserialize(json) as Track
            if(!deserializerStorage.exist(track)) {
                deserializerStorage.add(track)
            }
        }
        
        return track
    }
}