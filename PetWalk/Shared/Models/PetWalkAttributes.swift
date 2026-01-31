//
//  PetWalkAttributes.swift
//  PetWalk
//
//  Created by Cursor AI Assistant on 2026/01/31.
//

import ActivityKit
import Foundation

struct PetWalkAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state
        var distance: Double // km
        var duration: TimeInterval
        var currentSpeed: Double // km/h
        var isMoving: Bool
        var petMood: String // e.g. "happy", "tired"
    }

    // Static data
    var petName: String
    var avatarImageName: String? // If using local shared file
}
