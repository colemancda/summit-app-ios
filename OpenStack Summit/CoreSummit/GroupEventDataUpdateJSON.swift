//
//  GroupEventDataUpdateJSON.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 1/26/17.
//  Copyright © 2017 OpenStack. All rights reserved.
//

import struct Foundation.Date
import JSON

private extension GroupEventDataUpdate {
    
    typealias JSONKey = Event.JSONKey
}

extension GroupEventDataUpdate: JSONDecodable {
    
    public init?(json JSONValue: JSON.Value) {
        
        guard let JSONObject = JSONValue.objectValue,
            let identifier = JSONObject[JSONKey.id.rawValue]?.integerValue,
            let summit = JSONObject[JSONKey.summit_id.rawValue]?.integerValue,
            let title = JSONObject[JSONKey.title.rawValue]?.rawValue as? String,
            let startDate = JSONObject[JSONKey.start_date.rawValue]?.integerValue,
            let endDate = JSONObject[JSONKey.end_date.rawValue]?.integerValue,
            let eventType = JSONObject[JSONKey.type_id.rawValue]?.integerValue,
            let tagsJSONArray = JSONObject[JSONKey.tags.rawValue]?.arrayValue,
            let tags = Tag.from(json: tagsJSONArray),
            let allowFeedback = JSONObject[JSONKey.allow_feedback.rawValue]?.rawValue as? Bool,
            let sponsorsJSONArray = JSONObject[JSONKey.sponsors.rawValue]?.arrayValue,
            let sponsors = Company.from(json: sponsorsJSONArray),
            let presentation = Presentation.DataUpdate(json: JSONValue),
            let averageFeedbackJSON = JSONObject[JSONKey.avg_feedback_rate.rawValue],
            let groupsJSONArray = JSONObject[JSONKey.groups.rawValue]?.arrayValue,
            let groups = Identifier.from(json: groupsJSONArray)
            else { return nil }
        
        self.identifier = identifier
        self.summit = summit
        self.name = title
        self.start = Date(timeIntervalSince1970: TimeInterval(startDate))
        self.end = Date(timeIntervalSince1970: TimeInterval(endDate))
        self.type = eventType
        self.allowFeedback = allowFeedback
        self.presentation = presentation
        self.tags = Set(tags)
        self.sponsors = Set(sponsors)
        self.groups = Set(groups)
        
        if let doubleValue = averageFeedbackJSON.rawValue as? Double {
            
            self.averageFeedback = doubleValue
            
        } else if let integerValue = averageFeedbackJSON.integerValue {
            
            self.averageFeedback = Double(integerValue)
            
        } else {
            
            return nil
        }
        
        // optional
        self.descriptionText = JSONObject[JSONKey.description.rawValue]?.rawValue as? String
        self.socialDescription = JSONObject[JSONKey.social_description.rawValue]?.rawValue as? String
        self.rsvp = JSONObject[JSONKey.rsvp_link.rawValue]?.rawValue as? String
        
        if let track = JSONObject[JSONKey.track_id.rawValue]?.integerValue, track > 0 {
            
            self.track = track
            
        } else {
            
            self.track = nil
        }
        
        if let location = JSONObject[JSONKey.location_id.rawValue]?.integerValue, location > 0 {
            
            self.location = location
            
        } else {
            
            self.location = nil
        }
        
        if let videosJSONArray = JSONObject[JSONKey.videos.rawValue]?.arrayValue {
            
            guard let videos = Video.from(json: videosJSONArray)
                else { return nil }
            
            self.videos = Set(videos)
            
        } else {
            
            self.videos = []
        }
    }
}
