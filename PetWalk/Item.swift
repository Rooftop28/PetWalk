//
//  Item.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
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
