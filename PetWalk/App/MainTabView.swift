//
//  MainTabView.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/7.
//

import SwiftUI

enum Tab {
    case home
    case history
    case achievement  // 原 dress，改为 achievement
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 主内容区
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .history:
                    HistoryView()
                case .achievement:
                    AchievementView()  // 替换为成就页面
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 底部导航栏 (悬浮在最上方)
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    MainTabView()
}

