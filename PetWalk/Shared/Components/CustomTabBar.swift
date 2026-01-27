//
//  CustomTabBar.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack {
            Spacer()
            // 陪伴 (Home)
            tabItem(icon: "pawprint.fill", text: "陪伴", tab: .home)
            Spacer()
            // 足迹 (History)
            tabItem(icon: "chart.bar.fill", text: "足迹", tab: .history)
            Spacer()
            // 成就 (Achievement) - 原收藏
            tabItem(icon: "trophy.fill", text: "成就", tab: .achievement)
            Spacer()
        }
        .padding(.top, 15)
        .padding(.bottom, 5)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
    }
    
    // 提取一个小组件函数
    private func tabItem(icon: String, text: String, tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        let color: Color = isSelected ? .appTabSelected : .appTabUnselected
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 24 : 22))
                    .foregroundColor(color)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                Text(text)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
            }
        }
    }
}
