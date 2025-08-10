//
//  BubbleChatMessageFromDatabase.swift
//  Bubble
//
//  Created by Shah Mirza on 3/14/20.
//  Copyright © 2020 Shah Mirza. All rights reserved.
//

import UIKit
import Firebase

struct BubbleChatMessageFromDatabase
{
    var name: String
    var message: String
    var timestamp: Double
    var key: String
    
    init(snap: DataSnapshot)
    {
        self.name = snap.childSnapshot(forPath: "name").value as? String ?? "No name"
        self.message = snap.childSnapshot(forPath: "message").value as? String ?? "No message"
        self.timestamp = snap.childSnapshot(forPath: "timestamp").value as? Double ?? 0
        self.key = snap.key
    }
}
