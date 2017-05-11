//
//  PushNotificationManager.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 1/13/17.
//  Copyright © 2017 OpenStack. All rights reserved.
//

import Foundation
import CoreData
import Foundation
import CoreSummit
import FirebaseCore
import FirebaseMessaging

public final class PushNotificationManager: NSObject, NSFetchedResultsControllerDelegate, FIRMessagingDelegate {
    
    public static let shared = PushNotificationManager()
    
    public let store: Store
    
    public var log: ((String) -> ())?
    
    // Alerts for messages belonging to this team will be excluded.
    public var teamMessageAlertFilter: Identifier?
    
    fileprivate var summitObserver: Int!
    
    fileprivate var teamsFetchedResultsController: NSFetchedResultsController?
    
    fileprivate var teams: Set<Identifier> {
        
        return (teamsFetchedResultsController?.fetchedObjects as? [Entity] ?? []).identifiers
    }
    
    fileprivate var eventsFetchedResultsController: NSFetchedResultsController?
    
    fileprivate var events: Set<Identifier> {
        
        return (eventsFetchedResultsController?.fetchedObjects as? [Entity] ?? []).identifiers
    }
    
    private var notificationsFetchedResultsController: NSFetchedResultsController!
    
    private var notifications: Set<Identifier> {
        
        return (notificationsFetchedResultsController?.fetchedObjects as? [Entity] ?? []).identifiers
    }
    
    private(set) var subscribedTopics = Set<Notification.Topic>()
    
    fileprivate let userDefaults = UserDefaults.standard
    
    var unreadCount: Int { return unreadNotifications.value.count + unreadTeamMessages.value.count }
    
    lazy var unreadNotifications: Observable<Set<Identifier>> = self.initUnreadNotifications(.unreadNotifications)
    
    lazy var unreadTeamMessages: Observable<Set<Identifier>> = self.initUnreadNotifications(.unreadTeamMessages)
    
    // MARK: - Initialization
    
    deinit {
        
        SummitManager.shared.summit.remove(summitObserver)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate init(store: Store = Store.shared) {
        
        self.store = store
        
        super.init()
        
        self.summitObserver = SummitManager.shared.summit.observe(summitChanged)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loggedIn), name: Store.Notification.LoggedIn.rawValue, object: self.store)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loggedOut), name: Store.Notification.LoggedOut.rawValue, object: self.store)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(forcedLoggedOut), name: Store.Notification.ForcedLoggedOut.rawValue, object: self.store)
        
        self.notificationsFetchedResultsController = NSFetchedResultsController.init(Notification.self,
                                                                                delegate: self,
                                                                                context: Store.shared.managedObjectContext)
        
        try! self.notificationsFetchedResultsController.performFetch()
    }
    
    // MARK: - Methods
    
    public func setupNotifications(_ application: UIApplication) {
        
        var notificationCategories = Set<UIMutableUserNotificationCategory>()
        
        do {
            
            let replyAction = UIMutableUserNotificationAction()
            replyAction.identifier = TeamMessageNotificationAction.reply.rawValue
            replyAction.title = "Reply"
            replyAction.activationMode = .background
            replyAction.isAuthenticationRequired = true
            replyAction.isDestructive = false
            replyAction.behavior = .textInput
            
            let notificationCategory = UIMutableUserNotificationCategory()
            notificationCategory.identifier = TeamMessageNotificationAction.category.rawValue
            notificationCategory.setActions([replyAction], for: .default)
            notificationCategory.setActions([replyAction], for: .minimal)
            notificationCategories.insert(notificationCategory)
        }
        
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: notificationCategories)
        
        application.registerUserNotificationSettings(settings)
        
        application.registerForRemoteNotifications()
    }
    
    public func process(pushNotification: [String: AnyObject], unread: Bool = true) {
        
        let notification: PushNotification?
        
        let backgroundState = UIApplication.shared.applicationState == .background
        
        let context = store.privateQueueManagedObjectContext
        
        // parse
        
        if let teamMessageNotification = TeamMessageNotification(pushNotification: pushNotification) {
            
            notification = teamMessageNotification
            
            let teamMessage = TeamMessage(notification: teamMessageNotification)
            
            // cache
            context.performBlock {
                
                try! teamMessage.save(context)
                
                try! context.save()
            }
            
            let incomingMessage = teamMessage.from.identifier != store.authenticatedMember?.identifier
            
            if incomingMessage {
                
                // set as unread
                unreadTeamMessages.value.insert(teamMessage.identifier)
                
                let alertTitle = "\(teamMessageNotification.from.firstName) \(teamMessageNotification.from.lastName)"
                let alertBody = teamMessageNotification.body
                
                // schedule local notification
                if backgroundState {
                    
                    let userNotification = UILocalNotification()
                    userNotification.userInfo = [UserNotificationUserInfo.topic.rawValue: Notification.Topic.team(teamMessage.team.identifier).rawValue, UserNotificationUserInfo.identifier.rawValue : teamMessage.identifier]
                    userNotification.alertTitle = alertTitle
                    userNotification.alertBody = alertBody
                    userNotification.fireDate = Date()
                    userNotification.category = TeamMessageNotificationAction.category.rawValue
                    
                    UIApplication.shared.scheduleLocalNotification(userNotification)
                    
                } else if teamMessageAlertFilter != teamMessageNotification.team {
                    
                    SweetAlert().showAlert(alertTitle, subTitle: alertBody, style: .None)
                }
            }
            
        } else if let generalNotification = GeneralNotification(pushNotification:pushNotification) {
            
            notification = generalNotification
            
            guard try! NotificationManagedObject.find(generalNotification.identifier, context: context) == nil
                else { return } // already cached
            
            guard try! SummitManagedObject.find(generalNotification.summit, context: context) != nil else {
                
                log?("Invalid summit in push notification: \(generalNotification)")
                return
            }
            
            if let event = generalNotification.event?.identifier {
                
                guard try! EventManagedObject.find(event, context: context) != nil else {
                    
                    log?("Invalid event in push notification: \(generalNotification)")
                    return
                }
            }
            
            let encodable = Notification(notification: generalNotification)
            
            // cache
            context.performBlock {
                
                try! encodable.save(context)
                
                try! context.save()
            }
            
            if unread {
                
                // set as unread
                unreadNotifications.value.insert(generalNotification.identifier)
                
                // show notification if new
                if backgroundState == false
                    && generalNotification.created >= (Date() - 60 * 10) {
                    
                    let alertTitle = generalNotification.event?.title ?? "Notification"
                    
                    SweetAlert().showAlert(alertTitle, subTitle: generalNotification.body, style: .None)
                }
            }
            
        } else {
            
            notification = nil
        }
        
        if let notification = notification {
            
            log?("Got push notification: \(notification)")
            
        } else {
            
            log?("Could not parse push notification: \(pushNotification)")
        }
    }
    
    public func handleNotification(action identifier: String?, for notification: UILocalNotification, with response: [String: AnyObject], completion: () -> ()) {
        
        let category = UserNotificationCategory(rawValue: notification.category!)!
        
        switch category {
            
        case .teamMessage:
            
            let action = TeamMessageNotificationAction(rawValue: identifier!)!
            
            switch action {
                
            case .reply:
                
                guard let topicString = notification.userInfo?[UserNotificationUserInfo.topic.rawValue] as? String,
                    let topic = Notification.Topic(rawValue: topicString),
                    case let .team(team) = topic,
                    let messageIdentifier = notification.userInfo?[UserNotificationUserInfo.identifier.rawValue] as? Int
                    else { completion(); return }
                
                // mark message as read
                unreadTeamMessages.value.remove(messageIdentifier)
                
                if let replyText = response[UIUserNotificationActionResponseTypedTextKey] as? String {
                    
                    Store.shared.send(replyText, to: team, completion: { [weak self] (response) in
                        
                        switch response {
                            
                        case let .error(error):
                            
                            self?.log?("Could not send message from local notification: \(error)")
                            
                        case let .value(newMessage):
                            
                            self?.log?("Sent message from local notification: \(newMessage)")
                        }
                    })
                    
                    completion()
                    
                } else {
                    // Fallback on earlier versions
                    
                }
            }
            
        case .generalNotification:
            
            break
            
        }
    }
    
    public func reloadSubscriptions() {
        
        unsubscribeAll()
        
        subscribe(to: .everyone)
        
        let summit = SummitManager.shared.summit.value
        
        if summit > 0 {
            
            subscribe(to: .summit(summit))
        }
        
        startObservingUser()
        
        startObservingTeams()
    }
    
    @inline(__always)
    fileprivate func subscribe(to topic: Notification.Topic) {
        
        FIRMessaging.messaging().subscribeToTopic(topic.rawValue)
        
        subscribedTopics.insert(topic)
        
        log?("Subscribed to \(topic.rawValue)")
    }
    
    @inline(__always)
    fileprivate func unsubscribe(from topic: Notification.Topic) {
        
        FIRMessaging.messaging().unsubscribeFromTopic(topic.rawValue)
        
        subscribedTopics.remove(topic)
        
        log?("Unsubscribed from \(topic.rawValue)")
    }
    
    @inline(__always)
    fileprivate func unsubscribeAll() {
        
        log?("Will unsubscribe from all topics")
        
        subscribedTopics.forEach { unsubscribe(from: $0) }
    }
    
    fileprivate func startObservingTeams() {
        
        // fetch member's teams
        
        guard let member = self.store.authenticatedMember else {
            
            self.teamsFetchedResultsController = nil
            return
        }
        
        let predicate = NSPredicate(format: "owner == %@ || members.member CONTAINS %@", member, member)
        
        let sort = [NSSortDescriptor(key: "id", ascending: true)]
        
        teamsFetchedResultsController = NSFetchedResultsController(Team.self, delegate: self, predicate: predicate, sortDescriptors: sort, sectionNameKeyPath: nil, context: store.managedObjectContext)
        
        try! teamsFetchedResultsController!.performFetch()
        
        teams.forEach { subscribe(to: .team($0)) }
    }
    
    fileprivate func startObservingUser() {
        
        let member = self.store.authenticatedMember
        
        if let memberID = member?.identifier {
            
            subscribe(to: .member(memberID))
        }
        
        if member?.speakerRole != nil {
            
            subscribe(to: .speakers)
        }
        
        if let attendeeRole = member?.attendeeRole {
            
            subscribe(to: .attendees)
            
            let predicate = NSPredicate(format: "attendees CONTAINS %@", attendeeRole)
            
            let sort = [NSSortDescriptor(key: "id", ascending: true)]
            
            eventsFetchedResultsController = NSFetchedResultsController(Event.self, delegate: self, predicate: predicate, sortDescriptors: sort, sectionNameKeyPath: nil, context: store.managedObjectContext)
            
            try! eventsFetchedResultsController!.performFetch()
            
            events.forEach { subscribe(to: .event($0)) }
            
        } else {
            
            eventsFetchedResultsController = nil
        }
    }
    
    fileprivate func summitChanged(_ newValue: Identifier, oldValue: Identifier) {
        
        unsubscribe(from: .summit(oldValue))
        subscribe(to: .summit(newValue))
    }
    
    @inline(__always)
    fileprivate func initUnreadNotifications(_ preferenceKey: PreferenceKey) -> Observable<Set<Identifier>> {
        
        let storedValue = userDefaults.objectForKey(preferenceKey.rawValue) as? [Int] ?? []
        
        let observable = Observable<Set<Identifier>>(Set(storedValue))
        
        observable.observe { [weak self] in self?.unreadNotificationsChanged(new: $0.0, old: $0.1, key: preferenceKey) }
        
        return observable
    }
    
    fileprivate func unreadNotificationsChanged(new newValue: Set<Identifier>, old oldValue: Set<Identifier>, key preferenceKey: PreferenceKey) {
        
        userDefaults.setObject(Array(newValue), forKey: preferenceKey.rawValue)
        userDefaults.synchronize()
        
        updateAppBadge()
    }
    
    @inline(__always)
    public func updateAppBadge() {
        
        UIApplication.shared.applicationIconBadgeNumber = unreadCount
    }
    
    @inline(__always)
    fileprivate func resetUnreadNotifications() {
        
        unreadNotifications.value = []
        unreadTeamMessages.value = []
        
        assert(unreadCount == 0)
    }
    
    public func unreadMessages(in team: Identifier, context: NSManagedObjectContext) throws -> Int {
        
        let unreadTeamMessages = Array(self.unreadTeamMessages.value)
        
        //NSPredicate(format: "team.id == %@ AND id IN %@", NSNumber(longLong: Int64(team)), unreadTeamMessages)
        let predicate: CoreSummit.Predicate = "team.id" == Int64(team) &&& "id".`in`(unreadTeamMessages)
        
        return try context.count(TeamMessageManagedObject.self, predicate: predicate)
    }
    
    // MARK: - FIRMessagingDelegate
    
    public func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        
        process(remoteMessage.appData as! [String: AnyObject])
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        let identifier = (anObject as! Entity).identifier
        
        if controller == teamsFetchedResultsController
            || controller == eventsFetchedResultsController {
            
            let topic: Notification.Topic
            
            if controller === teamsFetchedResultsController {
                
                topic = .team(identifier)
                
            } else if controller == eventsFetchedResultsController {
                
                topic = .event(identifier)
                
            } else {
                
                fatalError("Unknown fetched results controller \(controller)")
            }
            
            switch type {
                
            case .Insert: subscribe(to: topic)
                
            case .Delete: unsubscribe(from: topic)
                
            case .Move, .Update: break
            }
            
        } else if controller == notificationsFetchedResultsController {
            
            switch type {
                
            case .Delete:
                
                // remove unread notification from set since it was deleted
                if unreadNotifications.value.contains(identifier) {
                    
                    unreadNotifications.value.remove(identifier)
                }
                
            case .Insert, .Move, .Update: break
            }
            
        } else {
            
            fatalError("Unknown fetched results controller \(controller)")
        }
        
        switch type {
            
        case .insert: subscribe(to: topic)
            
        case .delete: unsubscribe(from: topic)
            
        case .move, .update: break
        }
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func loggedIn(_ notification: Notification) {
        
        resetUnreadNotifications()
        reloadSubscriptions()
    }
    
    @objc fileprivate func loggedOut(_ notification: Notification) {
        
        resetUnreadNotifications()
        reloadSubscriptions()
    }
    
    @objc fileprivate func forcedLoggedOut(_ notification: Notification) {
        
        resetUnreadNotifications()
        reloadSubscriptions()
    }
}

// MARK: - Supporting Types

private extension PushNotificationManager {
    
    enum PreferenceKey: String {
        
        case unreadNotifications = "PushNotificationManager.unreadNotifications"
        case unreadTeamMessages = "PushNotificationManager.unreadTeamMessages"
    }
}

public enum UserNotificationCategory: String {
    
    case teamMessage
    case generalNotification
}

public enum TeamMessageNotificationAction: String {
    
    public static let category = UserNotificationCategory.teamMessage
    
    case reply
}

public enum UserNotificationUserInfo: String {
    
    case topic
    case identifier
}

public enum PushNotificationType: String {
    
    case team = "TEAM_MESSAGE"
    case notification = "PUSH_NOTIFICATION"
}

public protocol PushNotification {
    
    static var type: PushNotificationType { get }
    
    var identifier: Identifier { get }
    
    var body: String { get }
    
    var created: Date { get }
    
    init?(pushNotification: [String: AnyObject])
}

public struct TeamMessageNotification: PushNotification {
    
    fileprivate enum Key: String {
        
        case from, id, type, body, from_id, from_first_name, from_last_name, created_at
    }
    
    public static let type = PushNotificationType.team
    
    public let identifier: Identifier
    
    public let body: String
    
    public let created: Date
    
    public let team: Identifier
    
    public let from: (idenfitier: Identifier, firstName: String, lastName: String)
    
    public init?(pushNotification: [String: AnyObject]) {
        
        guard let topicString = pushNotification[Key.from.rawValue] as? String,
            let topic = Notification.Topic(rawValue: topicString),
            let typeString = pushNotification[Key.type.rawValue] as? String,
            let type = PushNotificationType(rawValue: typeString),
            case let .team(team) = topic,
            let identifierString = pushNotification[Key.id.rawValue] as? String,
            let identifier = Int(identifierString),
            let encodedBody = pushNotification[Key.body.rawValue] as? String,
            let body = String(openStackEncoded: encodedBody),
            let createdString = pushNotification[Key.created_at.rawValue] as? String,
            let created = Int(createdString),
            let fromIDString = pushNotification[Key.from_id.rawValue] as? String,
            let fromID = Int(fromIDString),
            let fromFirstName = pushNotification[Key.from_first_name.rawValue] as? String,
            let fromLastName = pushNotification[Key.from_last_name.rawValue] as? String
            where type == self.dynamicType.type
            else { return nil }
        
        self.identifier = identifier
        self.team = team
        self.body = body
        self.created = Date(timeIntervalSince1970: TimeInterval(created))
        self.from = (fromID, fromFirstName, fromLastName)
    }
}

public extension TeamMessage {
    
    init(notification: TeamMessageNotification) {
        
        self.identifier = notification.identifier
        self.body = notification.body
        self.created = notification.created
        self.from = .identifier(notification.from.idenfitier)
        self.team = .identifier(notification.team)
    }
}

public struct GeneralNotification: PushNotification {
    
    fileprivate enum Key: String {
        
        case from, to, id, type, body, summit_id, channel, created_at, event_id, title
    }
    
    public static let type = PushNotificationType.notification
    
    public let identifier: Identifier
    
    public let body: String
    
    public let created: Date
    
    public let from: Notification.Topic
    
    public let summit: Identifier
    
    public let channel: Notification.Channel
    
    public let event: (identifier: Identifier, title: String)?
    
    public init?(pushNotification: [String: AnyObject]) {
        
        guard let topicString = pushNotification[Key.from.rawValue] as? String ?? pushNotification[Key.to.rawValue] as? String,
            let topic = Notification.Topic(rawValue: topicString),
            let typeString = pushNotification[Key.type.rawValue] as? String,
            let type = PushNotificationType(rawValue: typeString),
            let identifierString = pushNotification[Key.id.rawValue] as? String,
            let identifier = Int(identifierString),
            let body = pushNotification[Key.body.rawValue] as? String,
            let createdString = pushNotification[Key.created_at.rawValue] as? String,
            let created = Int(createdString),
            let summitIDString = pushNotification[Key.summit_id.rawValue] as? String,
            let summitID = Int(summitIDString),
            let channelString = pushNotification[Key.channel.rawValue] as? String,
            let channel = Notification.Channel(rawValue: channelString)
            where type == self.dynamicType.type
            else { return nil }
        
        self.identifier = identifier
        self.from = topic
        self.body = body
        self.created = Date(timeIntervalSince1970: TimeInterval(created))
        self.summit = summitID
        self.channel = channel
        
        switch channel {
            
        case .event:
            
            guard let eventIDString = pushNotification[Key.event_id.rawValue] as? String,
                let eventID = Int(eventIDString),
                let eventTitle = pushNotification[Key.title.rawValue] as? String
                else { return nil }
            
            self.event = (eventID, eventTitle)
            
        default:
            
            self.event = nil
        }
    }
}

extension Notification {
    
    init(notification: GeneralNotification) {
        
        self.identifier = notification.identifier
        self.body = notification.body
        self.created = notification.created
        self.from = notification.from
        self.summit = notification.summit
        self.channel = notification.channel
        self.event = notification.event?.identifier
    }
}
