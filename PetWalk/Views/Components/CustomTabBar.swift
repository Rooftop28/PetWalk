//
//  CustomTabBar.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//

import SwiftUI

struct CustomTabBar: View {
    var body: some View {
        HStack {
            Spacer()
            // 陪伴 (选中)
            tabItem(icon: "pawprint.fill", text: "陪伴", color: .appTabSelected, size: 24)
            Spacer()
            // 足迹
            tabItem(icon: "chart.bar.fill", text: "足迹", color: .appTabUnselected, size: 22)
            Spacer()
            // 装扮
            tabItem(icon: "tshirt.fill", text: "装扮", color: .appTabUnselected, size: 22)
            Spacer()
        }
        .padding(.top, 15)
        .padding(.bottom, 5)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
    }
    
    // 提取一个小组件函数，让代码更整洁
    private func tabItem(icon: String, text: String, color: Color, size: CGFloat) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
        }
    }
}
