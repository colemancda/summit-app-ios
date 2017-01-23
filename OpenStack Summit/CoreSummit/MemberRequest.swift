//
//  LoggedInMemberRequest.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 7/31/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

import SwiftFoundation
import AeroGearHttp
import AeroGearOAuth2

public extension Store {
    
    func currentMember(for summit: Identifier, completion: (ErrorValue<MemberResponse.Member>) -> ()) {
        
        let URI = "/api/v1/summits/\(summit)/members/me/?expand=attendee,speaker,feedback,groups"
        
        let URL = environment.configuration.authenticationURL + URI
        
        let http = self.createHTTP(.OpenIDGetFormUrlEncoded)
        
        let context = privateQueueManagedObjectContext
        
        http.GET(URL, parameters: nil, completionHandler: { (responseObject, error) in
            
            // forward error
            guard error == nil
                else { completion(.Error(error!)); return }
            
            guard let json = JSON.Value(string: responseObject as! String),
                let member = MemberResponse.Member(JSONValue: json)
                else { completion(.Error(Error.InvalidResponse)); return }
            
            // cache
            try! context.performErrorBlockAndWait {
                
                try member.save(context)
                
                try context.save()
            }
            
            // success
            completion(.Value(member))
        })
    }
}

// MARK: - Supporting Types

public struct MemberResponse {
    
    public struct Member: Named {
        
        public let identifier: Identifier
        
        public let firstName: String
        
        public let lastName: String
        
        public let gender: Gender
        
        public let pictureURL: String
        
        public let twitter: String?
        
        public let linkedIn: String?
        
        public let irc: String?
        
        public let biography: String?
        
        public let speakerRole: Speaker?
        
        public let attendeeRole: Attendee?
        
        public let groupEvents: [Event]
        
        public let groups: [Group]
    }
    
    public struct Event: Named {
        
        public let identifier: Identifier
        
        public let name: String
        
        public let descriptionText: String?
        
        public let socialDescription: String?
        
        public let start: Date
        
        public let end: Date
        
        public let summit: Identifier
        
        public let track: Track?
        
        public let allowFeedback: Bool
        
        public let averageFeedback: Double
        
        public let type: EventType
        
        public let sponsors: [Company]
        
        public let tags: [Tag]
        
        public let location: Location
        
        public let presentation: Presentation
        
        public let videos: [Video]
        
        public let rsvp: String?
        
        public let groups: [Group]
    }
    
    public struct Track: Named {
        
        public let identifier: Identifier
        
        public var name: String
        
        public var groups: Set<Group>
    }
    
    public typealias Presentation = PresentationDataUpdate
}

// MARK: - Equatable

public func == (lhs: MemberResponse.Event, rhs: MemberResponse.Event) -> Bool {
    
    return lhs.identifier == rhs.identifier
        && lhs.summit == rhs.summit
        && lhs.name == rhs.name
        && lhs.summit == rhs.summit
        && lhs.descriptionText == rhs.descriptionText
        && lhs.socialDescription == rhs.socialDescription
        && lhs.start == rhs.start
        && lhs.end == rhs.end
        && lhs.track == rhs.track
        && lhs.allowFeedback == rhs.allowFeedback
        && lhs.averageFeedback == rhs.averageFeedback
        && lhs.type == rhs.type
        && lhs.sponsors == rhs.sponsors
        && lhs.tags == rhs.tags
        && lhs.location == rhs.location
        && lhs.presentation == rhs.presentation
        && lhs.videos == rhs.videos
        && lhs.rsvp == rhs.rsvp
        && lhs.groups == rhs.groups
}

public func == (lhs: MemberResponse.Member, rhs: MemberResponse.Member) -> Bool {
    
    return lhs.identifier == rhs.identifier
        && lhs.firstName == rhs.firstName
        && lhs.lastName == rhs.lastName
        && lhs.pictureURL == rhs.pictureURL
        && lhs.twitter == rhs.twitter
        && lhs.irc == rhs.irc
        && lhs.linkedIn == rhs.linkedIn
        && lhs.speakerRole == rhs.speakerRole
        && lhs.attendeeRole == rhs.attendeeRole
        && lhs.groups == rhs.groups
        && lhs.groupEvents == rhs.groupEvents
}

public func == (lhs: MemberResponse.Track, rhs: MemberResponse.Track) -> Bool {
    
    return lhs.identifier == rhs.identifier
        && lhs.name == rhs.name
        && lhs.groups == rhs.groups
}