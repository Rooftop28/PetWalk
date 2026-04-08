//
//  DebugOverlay.swift
//  PetWalk
//

import SwiftUI

// MARK: - debugPageName extension (available in all builds, no-op in Release)

extension View {
    func debugPageName(_ name: String) -> some View {
        #if DEBUG
        return modifier(DebugPageTracking(pageName: name))
        #else
        return self
        #endif
    }
}

#if DEBUG

// MARK: - Debug 页面追踪器

@MainActor
class DebugPageTracker: ObservableObject {
    static let shared = DebugPageTracker()
    
    @Published var currentPageName: String = "Unknown"
    @Published var pageHistory: [(name: String, time: Date)] = []
    
    func track(_ pageName: String) {
        currentPageName = pageName
        pageHistory.insert((name: pageName, time: Date()), at: 0)
        if pageHistory.count > 20 {
            pageHistory.removeLast()
        }
    }
}

// MARK: - ViewModifier 自动追踪页面

struct DebugPageTracking: ViewModifier {
    let pageName: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                DebugPageTracker.shared.track(pageName)
            }
    }
}

// MARK: - Debug 悬浮球

struct DebugFloatingBubble: View {
    @ObservedObject private var tracker = DebugPageTracker.shared
    @State private var showDebugPanel = false
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 40, y: 120)
    @GestureState private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.85))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "ladybug.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                .position(
                    x: position.x + dragOffset.width,
                    y: position.y + dragOffset.height
                )
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            position.x += value.translation.width
                            position.y += value.translation.height
                            
                            let screenW = UIScreen.main.bounds.width
                            let screenH = UIScreen.main.bounds.height
                            position.x = min(max(20, position.x), screenW - 20)
                            position.y = min(max(60, position.y), screenH - 60)
                        }
                )
                .onTapGesture(count: 2) {
                    showDebugPanel = true
                }
        }
        .sheet(isPresented: $showDebugPanel) {
            DebugPanelView()
        }
    }
}

// MARK: - Debug 信息面板

struct DebugPanelView: View {
    @ObservedObject private var tracker = DebugPageTracker.shared
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("当前页面") {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                        Text(tracker.currentPageName)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
                
                Section("页面浏览历史") {
                    if tracker.pageHistory.isEmpty {
                        Text("暂无记录")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(Array(tracker.pageHistory.enumerated()), id: \.offset) { index, entry in
                            HStack {
                                Text(entry.name)
                                    .font(.system(.caption, design: .monospaced))
                                Spacer()
                                Text(formatTime(entry.time))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Section("用户数据快照") {
                    debugRow("petName", dataManager.userData.petName)
                    debugRow("ownerNickname", dataManager.userData.ownerNickname)
                    debugRow("totalBones", "\(dataManager.userData.totalBones)")
                    debugRow("totalWalks", "\(dataManager.userData.totalWalks)")
                    debugRow("totalDistance", String(format: "%.2f km", dataManager.userData.totalDistance))
                    debugRow("records.count", "\(dataManager.records.count)")
                    debugRow("hasCompletedOnboarding", "\(dataManager.userData.hasCompletedOnboarding)")
                    debugRow("aiDiaryEnabled", "\(dataManager.userData.aiDiaryEnabled)")
                }
                
                Section("Feature Flags") {
                    flagRow("enableAvatar", FeatureFlags.enableAvatar)
                    flagRow("enableLiveWalk", FeatureFlags.enableLiveWalk)
                    flagRow("enableFriendNudge", FeatureFlags.enableFriendNudge)
                    flagRow("enableVoiceRecording", FeatureFlags.enableVoiceRecording)
                    flagRow("enableLeaderboard", FeatureFlags.enableLeaderboard)
                    flagRow("enableCloudSync", FeatureFlags.enableCloudSync)
                    flagRow("enableGameCenter", FeatureFlags.enableGameCenter)
                    flagRow("enableTitleSystem", FeatureFlags.enableTitleSystem)
                }
            }
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    private func debugRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
    
    private func flagRow(_ name: String, _ enabled: Bool) -> some View {
        HStack {
            Text(name)
                .font(.system(.caption, design: .monospaced))
            Spacer()
            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(enabled ? .green : .red)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
#endif
