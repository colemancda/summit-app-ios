//
//  VenueDetailPresenter.swift
//  OpenStackSummit
//
//  Created by Claudio on 9/4/15.
//  Copyright © 2015 OpenStack. All rights reserved.
//

import UIKit

@objc
public protocol IVenueDetailPresenter {
    func viewLoad(venueId: Int)
    func showVenueLocationDetail()
    func getVenueRoomsCount() -> Int
    func buildVenueRoomCell(cell: IVenueListTableViewCell, index: Int)
}

public class VenueDetailPresenter: NSObject, IVenueDetailPresenter {
    var venueId = 0
    var interactor: IVenueDetailInteractor!
    var viewController: IVenueDetailViewController!
    var wireframe: IVenueDetailWireframe!
    var venue: VenueDTO!
    
    public func viewLoad(venueId: Int) {
        self.venueId = venueId
        venue = interactor.getVenue(venueId)
        viewController.name = venue.name
        viewController.location = venue.address

        if venue.maps.count > 0 {
            viewController.maps = venue.maps
            viewController.slideshowEnabled = true
        } else {
            viewController.addMarker(venue)
            viewController.slideshowEnabled = false
        }
        
        viewController.reloadRoomsData()
    }
    
    public func showVenueLocationDetail() {
        wireframe.presentVenueLocationDetailView(venueId, viewController: viewController.navigationController!)
    }
    
    public func getVenueRoomsCount() -> Int {
        return venue.rooms.count
    }
    
    public func buildVenueRoomCell(cell: IVenueListTableViewCell, index: Int) {
        let venueRoom = venue.rooms[index]
        cell.name = venueRoom.name
    }
    
}
