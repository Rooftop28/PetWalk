//
//  PetWalkApp.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//

import SwiftUI
import SwiftData

@main // 这个标记非常重要，它是 App 的入口
struct PetWalkApp: App {
    var body: some Scene {
        WindowGroup {
            // 🔴 以前这里写的是 ContentView()
            // 🟢 现在把它改成我们新写的 HomeView()
            HomeView()
        }
    }
}
