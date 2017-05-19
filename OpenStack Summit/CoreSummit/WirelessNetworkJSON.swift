//
//  WirelessNetworkJSON.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 2/6/17.
//  Copyright © 2017 OpenStack. All rights reserved.
//

import JSON

private extension WirelessNetwork {
    
    enum JSONKey: String {
        
        case id, ssid, password, description, summit_id
    }
}

extension WirelessNetwork: JSONDecodable {
    
    public init?(json JSONValue: JSON.Value) {
        
        guard let JSONObject = JSONValue.objectValue,
            let identifier = JSONObject[JSONKey.id.rawValue]?.integerValue,
            let name = JSONObject[JSONKey.ssid.rawValue]?.rawValue as? String,
            let password = JSONObject[JSONKey.password.rawValue]?.rawValue as? String,
            let summit = JSONObject[JSONKey.summit_id.rawValue]?.integerValue
            else { return nil }
        
        self.identifier = identifier
        self.name = name
        self.password = password
        self.summit = summit
        
        self.descriptionText = JSONObject[JSONKey.description.rawValue]?.rawValue as? String
    }
}
