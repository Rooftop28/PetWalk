//
//  PetWalkWidgetsBundle.swift
//  PetWalkWidgets
//
//  Created by User on 2026/1/31.
//

import WidgetKit
import SwiftUI

@main
struct PetWalkWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PetWalkWidgets()
        PetWalkWidgetsControl()
        PetWalkLiveActivity()
    }
}
