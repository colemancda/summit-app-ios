//
//  ScheduleInteractor.swift
//  OpenStackSummit
//
//  Created by Claudio on 10/14/15.
//  Copyright © 2015 OpenStack. All rights reserved.
//

import UIKit

@objc
public protocol IScheduleInteractor : IScheduleableInteractor {
    func getActiveSummit(completionBlock: (SummitDTO?, NSError?) -> Void)
    func getScheduleAvailableDates(startDate: NSDate, endDate: NSDate, eventTypes: [Int]?, summitTypes: [Int]?, tracks: [Int]?, trackGroups: [Int]?, tags: [String]?, levels: [String]?) -> [NSDate]
    func getScheduleEvents(startDate: NSDate, endDate: NSDate, eventTypes: [Int]?, summitTypes: [Int]?, tracks: [Int]?, trackGroups: [Int]?, tags: [String]?, levels: [String]?) -> [ScheduleItemDTO]
    func addEventToLoggedInMemberSchedule(eventId: Int, completionBlock: (NSError?) -> Void)
    func removeEventFromLoggedInMemberSchedule(eventId: Int, completionBlock: (NSError?) -> Void)
    func isEventScheduledByLoggedMember(eventId: Int) -> Bool
    func subscribeToPushChannelsUsingContextIfNotDoneAlready()
    func isDataLoaded() -> Bool
}

public class ScheduleInteractor: ScheduleableInteractor {
    var summitDataStore: ISummitDataStore!
    var summitDTOAssembler: ISummitDTOAssembler!
    var scheduleItemDTOAssembler: IScheduleItemDTOAssembler!
    var dataUpdatePoller: DataUpdatePoller!
    var pushNotificationsManager: IPushNotificationsManager!
    var pushRegisterInProgress = false
    
    public func subscribeToPushChannelsUsingContextIfNotDoneAlready() {        
        if pushRegisterInProgress {
            return
        }
        
        pushRegisterInProgress = true
        
        if NSUserDefaults.standardUserDefaults().objectForKey("registeredPushNotificationChannels") == nil {
            self.pushNotificationsManager.subscribeToPushChannelsUsingContext(){ (succeeded: Bool, error: NSError?) in
                if succeeded {
                    NSUserDefaults.standardUserDefaults().setObject("true", forKey: "registeredPushNotificationChannels")
                }
                self.pushRegisterInProgress = false
            }
        }
    }
    
    public func getActiveSummit(completionBlock: (SummitDTO?, NSError?) -> Void) {
        summitDataStore.getActive() { summit, error in
            self.dataUpdatePoller.startPollingIfNotPollingAlready()

            var summitDTO: SummitDTO?
            if (error == nil) {
                summitDTO = self.summitDTOAssembler.createDTO(summit!)
            }
            completionBlock(summitDTO, error)
        }
    }
    
    public func getScheduleAvailableDates(startDate: NSDate, endDate: NSDate, eventTypes: [Int]?, summitTypes: [Int]?, tracks: [Int]?, trackGroups: [Int]?, tags: [String]?, levels: [String]?) -> [NSDate] {
        let events = eventDataStore.getByFilterLocal(startDate, endDate: endDate, eventTypes: eventTypes, summitTypes: summitTypes, tracks: tracks, trackGroups: trackGroups, tags: tags, levels: levels)
        var activeDates: [NSDate] = []
        for event in events {
            let timeZone = NSTimeZone(name: event.summit.timeZone)!
            let startDate = event.start.mt_dateSecondsAfter(timeZone.secondsFromGMT).mt_startOfCurrentDay()
            if !activeDates.contains(startDate) {
                activeDates.append(startDate)
            }
            
        }
        return activeDates
    }
    
    public func getScheduleEvents(startDate: NSDate, endDate: NSDate, eventTypes: [Int]?, summitTypes: [Int]?, tracks: [Int]?, trackGroups: [Int]?, tags: [String]?, levels: [String]?) -> [ScheduleItemDTO] {
        let events = eventDataStore.getByFilterLocal(startDate, endDate: endDate, eventTypes: eventTypes, summitTypes: summitTypes, tracks: tracks, trackGroups: trackGroups, tags: tags, levels: levels)
        var scheduleItemDTO: ScheduleItemDTO
        var dtos: [ScheduleItemDTO] = []
        for event in events {
            scheduleItemDTO = scheduleItemDTOAssembler.createDTO(event)
            dtos.append(scheduleItemDTO)
        }
        return dtos
    }
    
    public func isDataLoaded() -> Bool {
        let summit = summitDataStore.getActiveLocal()
        return summit != nil
    }
}
