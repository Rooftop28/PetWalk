//
//  LeaderboardView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import SwiftUI

/// 排行榜视图 (Supabase 版)
struct LeaderboardView: View {
    @ObservedObject var gameCenter = GameCenterManager.shared
    @ObservedObject var leaderboardManager = SupabaseLeaderboardManager.shared
    @State private var selectedTab: SupabaseLeaderboardType = .global
    @State private var showRegionPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标签页选择器
                leaderboardTabPicker
                
                // 排行榜内容
                if gameCenter.isAuthenticated {
                    leaderboardContent
                } else {
                    notAuthenticatedView
                }
            }
            .navigationTitle("排行榜")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        gameCenter.showGameCenter()
                    } label: {
                        Image(systemName: "gamecontroller.fill")
                    }
                }
            }
            .onAppear {
                if !gameCenter.isAuthenticated {
                    gameCenter.authenticate()
                } else {
                    // 已认证，加载排行榜
                    Task {
                        await leaderboardManager.initializeUserProfile()
                        await leaderboardManager.loadAllLeaderboards()
                    }
                }
            }
            .onChange(of: gameCenter.isAuthenticated) { _, isAuth in
                if isAuth {
                    Task {
                        await leaderboardManager.initializeUserProfile()
                        await leaderboardManager.loadAllLeaderboards()
                    }
                }
            }
            .sheet(isPresented: $showRegionPicker) {
                RegionPickerView { region in
                    Task {
                        await leaderboardManager.updateUserRegion(region)
                    }
                }
            }
        }
    }
    
    // MARK: - 标签页选择器
    
    private var leaderboardTabPicker: some View {
        HStack(spacing: 0) {
            ForEach(SupabaseLeaderboardType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = type
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: type.iconSymbol)
                            .font(.system(size: 20))
                        Text(type.displayName)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == type ?
                        Color.appGreenMain.opacity(0.2) :
                        Color.clear
                    )
                    .foregroundColor(selectedTab == type ? .appGreenMain : .gray)
                }
            }
        }
        .background(Color.appBackground)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - 排行榜内容
    
    private var leaderboardContent: some View {
        VStack {
            // 当前玩家排名卡片
            currentPlayerCard
            
            // 同城榜地区选择提示
            if selectedTab == .city {
                cityLeaderboardHeader
            }
            
            // 排行榜列表
            if leaderboardManager.isLoading {
                Spacer()
                ProgressView("加载中...")
                Spacer()
            } else {
                leaderboardList
            }
        }
    }
    
    private var currentPlayerCard: some View {
        let userData = DataManager.shared.userData
        let rank: Int? = {
            switch selectedTab {
            case .global: return leaderboardManager.currentPlayerGlobalRank
            case .city: return leaderboardManager.currentPlayerCityRank
            case .friends: return nil
            }
        }()
        
        return HStack(spacing: 16) {
            // 排名
            if let rank = rank {
                Text("#\(rank)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appGreenMain)
            } else {
                Text("--")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("我的排名")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(gameCenter.localPlayer?.displayName ?? "玩家")
                    .font(.headline)
            }
            
            Spacer()
            
            // 里程
            VStack(alignment: .trailing, spacing: 4) {
                Text("累计里程")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(String(format: "%.1f km", userData.totalDistance))
                    .font(.headline)
                    .foregroundColor(.appGreenMain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appGreenMain.opacity(0.1))
        )
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    private var cityLeaderboardHeader: some View {
        HStack {
            if let region = leaderboardManager.currentUserRegion {
                Label(region, systemImage: "location.fill")
                    .font(.subheadline)
                    .foregroundColor(.appGreenMain)
            } else {
                Text("未设置地区")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button {
                showRegionPicker = true
            } label: {
                Text("切换城市")
                    .font(.caption)
                    .foregroundColor(.appGreenMain)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var currentLeaderboard: [SupabaseLeaderboardEntry] {
        switch selectedTab {
        case .global:
            return leaderboardManager.globalLeaderboard
        case .city:
            return leaderboardManager.cityLeaderboard
        case .friends:
            return leaderboardManager.friendsLeaderboard
        }
    }
    
    // MARK: - 排行榜列表
    
    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if currentLeaderboard.isEmpty {
                    emptyLeaderboardView
                } else {
                    ForEach(currentLeaderboard) { entry in
                        SupabaseLeaderboardEntryRow(
                            entry: entry,
                            showMedal: entry.rank <= 3,
                            showRegion: selectedTab == .city
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
        .refreshable {
            switch selectedTab {
            case .global:
                await leaderboardManager.loadGlobalLeaderboard()
            case .city:
                await leaderboardManager.loadCityLeaderboard()
            case .friends:
                await leaderboardManager.loadFriendsLeaderboard()
            }
        }
    }
    
    private var emptyLeaderboardView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            Text("暂无数据")
                .font(.headline)
                .foregroundColor(.gray)
            
            if selectedTab == .friends {
                Text("好友功能开发中...")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
            } else {
                Text("完成遛狗后，你的成绩将显示在这里")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 60)
    }
    
    // MARK: - 未认证视图
    
    private var notAuthenticatedView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("登录 Game Center")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("登录 Game Center 后，你可以查看全球排行榜，\n与好友一较高下！")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            // 根据状态显示不同按钮
            if gameCenter.isLoading {
                ProgressView()
                    .padding()
            } else if gameCenter.needsSystemLogin || 
                      (gameCenter.errorMessage?.contains("not been authenticated") == true) {
                // 需要去系统设置登录
                VStack(spacing: 12) {
                    Text("请先在系统设置中登录 Game Center")
                        .font(.callout)
                        .foregroundColor(.orange)
                    
                    Button {
                        gameCenter.openSettings()
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                            Text("打开设置")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button {
                        gameCenter.authenticate()
                    } label: {
                        Text("我已登录，重试")
                            .font(.subheadline)
                            .foregroundColor(.appGreenMain)
                    }
                    .padding(.top, 8)
                }
            } else {
                // 显示错误信息（如果不是需要系统登录的错误）
                if let error = gameCenter.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button {
                    gameCenter.authenticate()
                } label: {
                    Text("登录 Game Center")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(Color.appGreenMain)
                        .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Supabase 排行榜条目行
struct SupabaseLeaderboardEntryRow: View {
    let entry: SupabaseLeaderboardEntry
    var showMedal: Bool = false
    var showRegion: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 排名
            rankView
            
            // 头像
            avatarView
            
            // 玩家信息
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.subheadline)
                    .fontWeight(entry.isCurrentPlayer ? .semibold : .regular)
                    .foregroundColor(entry.isCurrentPlayer ? .appGreenMain : .primary)
                
                if showRegion, let region = entry.region {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(region)
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // 分数
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedDistance)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(entry.totalWalks) 次遛狗")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(entry.isCurrentPlayer ? Color.appGreenMain.opacity(0.1) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(entry.isCurrentPlayer ? Color.appGreenMain : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var rankView: some View {
        Group {
            if showMedal {
                medalView
            } else {
                Text("#\(entry.rank)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                    .frame(width: 36)
            }
        }
    }
    
    private var medalView: some View {
        ZStack {
            Circle()
                .fill(medalColor)
                .frame(width: 36, height: 36)
            
            Text("\(entry.rank)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var medalColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .gray
        }
    }
    
    private var avatarView: some View {
        Group {
            if let urlString = entry.avatarUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}

// MARK: - 地区选择器
struct RegionPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void
    
    let regions = [
        "北京", "上海", "广州", "深圳", "杭州", "成都", "南京", "武汉",
        "西安", "重庆", "苏州", "天津", "青岛", "厦门", "长沙", "郑州",
        "东莞", "佛山", "宁波", "合肥", "昆明", "沈阳", "大连", "无锡"
    ]
    
    var body: some View {
        NavigationView {
            List(regions, id: \.self) { region in
                Button {
                    onSelect(region)
                    dismiss()
                } label: {
                    Text(region)
                        .foregroundColor(.primary)
                }
            }
            .navigationTitle("选择城市")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LeaderboardView()
}
