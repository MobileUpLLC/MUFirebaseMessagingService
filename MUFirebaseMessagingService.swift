//
//  FirebaseMessagingService.swift
//
//  Created by Ed on 18/10/2019.
//  Copyright © 2019 MobileUp. All rights reserved.
//

import Foundation

import Firebase
import FirebaseMessaging

public final class MUFirebaseMessagingService : NSObject {
    
    // MARK: - Public Properties
    
    open weak var delegate : MUPushService?
    
    public var apnsToken : Data? {
        
        get { return Messaging.messaging().apnsToken }
        
        set { Messaging.messaging().apnsToken = newValue }
    }
    
    public var fcmToken : String? { return Messaging.messaging().fcmToken }
    
    public var instanceIDToken : String?
    
    public func instanceIDToken( completion: @escaping (String?, Error?) -> Void) {
        
        guard
            
            let integrationConfiguration = CardsmobileTokenizationService.shared.initializationData?.integrationConfiguration,
            
            let authorizedEntity = integrationConfiguration?.mdesConfiguration?.sdkConfig?.mGcmIds?.first,
        
            let apnsToken = self.apnsToken
            
        else { return }
        
        InstanceID.instanceID().token(
        
                withAuthorizedEntity: authorizedEntity,
                scope: InstanceIDScopeFirebaseMessaging,
                options: ["apns_token":apnsToken, "apns_sandbox":"0"]) { [weak self] (token:String?, error:Error?) in
            
            self?.instanceIDToken = token
                    
                completion(token, error)
            
        }
    }
    
    // MARK: - Public Methods
    
    override init() {
        
        super.init()
        
    }
    
    public func configure() {
        
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        
    }
    
}

extension FirebaseMessagingService : MessagingDelegate {
    
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
        #if DEBUG
        
        print("fcmToken = \(fcmToken)")
        
        #endif
    }
    
    public func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        
        #if DEBUG
        
        print("firebase remoteMessage.appData = \(remoteMessage.appData)")
        
        #endif
        
        guard let appData = remoteMessage.appData as? [String:Any] else { return }
        
        let pushData : PushReceivedData? = MUSerializationManager.decode(item: appData, to: PushReceivedData.self)
        
        delegate?.action(from: pushData)
        
        delegate?.postFCMNotification()
    }
    
}

extension Notification.Name {
    
    public static let didReceivedFromFCM  = Notification.Name("didReceivedFromFCM")
}
