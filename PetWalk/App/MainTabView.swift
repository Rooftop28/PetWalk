//
//  MainTabView.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/7.
//

import SwiftUI

enum Tab: Int, CaseIterable {
    case home = 0
    case history = 1
    case achievement = 2
}

struct MainTabView: View {
    @ObservedObject private var router = DeepLinkRouter.shared
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeView()
                .debugPageName("HomeView")
                .tabItem {
                    Label("陪伴", systemImage: "pawprint.fill")
                }
                .tag(Tab.home)
            
            HistoryView()
                .debugPageName("HistoryView")
                .tabItem {
                    Label("足迹", systemImage: "chart.bar.fill")
                }
                .tag(Tab.history)
            
            AchievementView()
                .debugPageName("AchievementView")
                .tabItem {
                    Label("成就", systemImage: "trophy.fill")
                }
                .tag(Tab.achievement)
        }
        .tint(.appTabSelected)
    }
}

#Preview {
    MainTabView()
}
