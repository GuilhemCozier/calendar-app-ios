//
//  Item.swift
//  OpenCalendar
//
//  Created by Guilhem Cozier on 24/11/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
