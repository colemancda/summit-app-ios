//
//  Person.swift
//  OpenStackSummit
//
//  Created by Alsey Coleman Miller on 5/31/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

public protocol Person: Named, Equatable {
    
    var firstName: String { get }
    
    var lastName: String { get }
        
    var pictureURL: String { get }
    
    var title: String? { get }
    
    var twitter: String? { get }
    
    var irc: String? { get }
    
    var biography: String? { get }
}

public extension Person {
    
    var name: String { return firstName + " " + lastName }
}
