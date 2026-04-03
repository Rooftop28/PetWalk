//
//  CustomTabBar.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Namespace private var tabNamespace
    @State private var isTransitioning = false
    
    var body: some View {
        HStack(spacing: 0) {
            tabItem(icon: "pawprint.fill", text: "陪伴", tab: .home)
            tabItem(icon: "chart.bar.fill", text: "足迹", tab: .history)
            tabItem(icon: "trophy.fill", text: "成就", tab: .achievement)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.04), radius: 1, y: -1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 16, y: -4)
        .padding(.horizontal, 16)
        .padding(.bottom, 2)
        .onChange(of: selectedTab) { _, _ in
            isTransitioning = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeOut(duration: 0.15)) {
                    isTransitioning = false
                }
            }
        }
    }
    
    private func tabItem(icon: String, text: String, tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        
        return LiquidTabItem(
            icon: icon,
            text: text,
            isSelected: isSelected,
            isTransitioning: isTransitioning,
            tabNamespace: tabNamespace
        ) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                selectedTab = tab
            }
        }
    }
}

// MARK: - 单个 Tab 项，支持长按水滴形变

private struct LiquidTabItem: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let isTransitioning: Bool
    var tabNamespace: Namespace.ID
    let onTap: () -> Void
    
    @GestureState private var isPressed = false
    
    private var indicatorScaleX: CGFloat {
        if isPressed { return 1.25 }
        if isTransitioning { return 1.15 }
        return 1.0
    }
    
    private var indicatorScaleY: CGFloat {
        if isPressed { return 0.82 }
        if isTransitioning { return 0.92 }
        return 1.0
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    Capsule()
                        .fill(Color.appTabSelected.opacity(isPressed ? 0.20 : 0.12))
                        .frame(width: 56, height: 36)
                        .scaleEffect(x: indicatorScaleX, y: indicatorScaleY)
                        .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                }
                
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 22 : 20))
                    .foregroundColor(isSelected ? .appTabSelected : .appTabUnselected)
                    .scaleEffect(isPressed ? 0.85 : (isSelected ? 1.05 : 1.0))
            }
            .frame(height: 36)
            
            Text(text)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .appTabSelected : .appTabUnselected)
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    if !state {
                        state = true
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                }
                .onEnded { value in
                    let tapped = abs(value.translation.width) < 15 && abs(value.translation.height) < 15
                    if tapped {
                        onTap()
                    }
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
    }
}
