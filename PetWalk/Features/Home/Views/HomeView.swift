//
//  HomeView.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//
import SwiftUI
import PhotosUI

struct HomeView: View {
    // 引入 ViewModel
    @StateObject private var viewModel = PetViewModel()
    
    // 引入健康数据管理器 (全天数据)
    @StateObject private var healthManager = HealthManager()
    
    // 引入遛狗会话管理器 (单次数据)
    @StateObject private var walkManager = WalkSessionManager()
    
    // 相册选择器的状态
    @State private var selectedItem: PhotosPickerItem?
    
    // 动画状态
    @State private var isDogVisible = false
    
    // 设定一个每日目标
    let dailyTarget: Double = 3.0
    
    // 是否显示结算页
    @State private var showSummary = false
    
    var body: some View {
        ZStack {
            // 背景色 (仅在非地图模式下显示)
            if !walkManager.isWalking {
                Color.appBackground.ignoresSafeArea()
            }
            
            // --- 状态分支 ---
            if walkManager.isWalking {
                // A. 遛狗中：全屏地图 + 悬浮控制板
                walkingModeView
            } else {
                // B. 待机中：原来的主页
                idleModeView
            }
        }
        // 监听 App 回到前台，刷新健康数据
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await healthManager.fetchTodayStats()
            }
        }
        // 弹出结算页
        .sheet(isPresented: $showSummary) {
            WalkSummaryView(
                duration: walkManager.duration,
                distance: walkManager.distance,
                // 将 CoreLocation 坐标转换为我们的 Codable 结构体
                routeCoordinates: walkManager.locationService.routeCoordinates.map { 
                    RoutePoint(lat: $0.latitude, lon: $0.longitude) 
                },
                onFinish: {
                    showSummary = false
                    // 可以在这里重置 walkManager 的数据，如果需要的话
                }
            )
        }
    }
    
    // MARK: - 待机模式视图 (原来的 UI)
    var idleModeView: some View {
        VStack(spacing: 0) {
            // Header
            Text("PetWalk")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(.appBrown)
                .padding(.top, 20)
            
            Spacer()
            
            // 中间核心交互区
            ZStack {
                // 1. 背景光晕
                BlobBackgroundView()
                    .frame(height: 350)
                    .offset(y: -20)
                
                // 2. 狗狗贴纸 (中间层)
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack {
                        if viewModel.isProcessing {
                            ProgressView()
                                .scaleEffect(2)
                                .tint(.appBrown)
                        } else {
                            if let image = viewModel.currentPetImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                // ⚠️ 确保 Assets 里有一张叫 "tongtong" 的图
                                Image("tongtong")
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                    }
                    .frame(height: 280)
                    .shadow(color: .white, radius: 0, x: 2, y: 0)
                    .shadow(color: .white, radius: 0, x: -2, y: 0)
                    .shadow(color: .white, radius: 0, x: 0, y: 2)
                    .shadow(color: .white, radius: 0, x: 0, y: -2)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
                    .scaleEffect(isDogVisible ? 1.0 : 0.8)
                    .opacity(isDogVisible ? 1.0 : 0)
                }
                .onChange(of: selectedItem) { _, newItem in
                    viewModel.selectAndProcessImage(from: newItem)
                }
                
                // 3. 气泡 (最上层)
                SpeechBubbleView(text: "今天天气不错，\n去公园吗？")
                    .offset(x: 80, y: -140)
                    .opacity(isDogVisible ? 1 : 0)
                    .animation(.easeIn.delay(0.6), value: isDogVisible)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0)) {
                    isDogVisible = true
                }
            }
            
            Spacer()
            
            // 仪表盘
            dashboardSection
            
            // 底部留白给 TabBar (因为现在 TabBar 是悬浮在上面的)
            Spacer().frame(height: 80)
        }
    }
    
    // MARK: - 遛狗模式视图 (新功能)
    var walkingModeView: some View {
        ZStack(alignment: .bottom) {
            // 1. 地图背景
            WalkMapView(
                locationManager: walkManager.locationService,
                petImage: viewModel.currentPetImage ?? UIImage(named: "tongtong")
            )
            .ignoresSafeArea()
            
            // 2. 悬浮数据面板
            VStack(spacing: 20) {
                HStack(spacing: 40) {
                    // 计时
                    VStack(spacing: 5) {
                        Text("时长")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(walkManager.formattedDuration)
                            .font(.system(size: 32, weight: .heavy, design: .monospaced))
                            .foregroundColor(.appBrown)
                    }
                    
                    // 距离
                    VStack(spacing: 5) {
                        Text("距离(km)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "%.2f", walkManager.distance))
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.appBrown)
                    }
                }
                
                // 结束按钮
                Button(action: {
                    withAnimation {
                        walkManager.stopWalk()
                        showSummary = true
                    }
                }) {
                    Text("结束遛狗")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.red.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(radius: 5)
                }
            }
            .padding(24)
            .background(
                Color.white
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 40) // 避开 Home Indicator
        }
        .transition(.move(edge: .bottom)) // 进场动画
    }
    
    // 把 dashboardSection 拆出来让代码更整洁
    var dashboardSection: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle().stroke(Color.appGreenMain.opacity(0.2), lineWidth: 15)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(healthManager.currentDistance / dailyTarget, 1.0)))
                    .stroke(
                        LinearGradient(colors: [.appGreenMain, .appGreenDark], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: healthManager.currentDistance)
                
                VStack(spacing: 5) {
                    Text("今日目标").font(.system(size: 14, weight: .medium)).foregroundColor(.appBrown.opacity(0.6))
                    
                    Text(String(format: "%.1fkm", healthManager.currentDistance))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.appBrown)
                        .contentTransition(.numericText(value: healthManager.currentDistance))
                    
                    Text("/ \(Int(dailyTarget))km").font(.system(size: 14, weight: .medium)).foregroundColor(.appBrown.opacity(0.6))
                }
            }
            .frame(width: 160, height: 160)
            
            Button(action: {
                // 点击开始遛狗
                withAnimation {
                    walkManager.startWalk()
                }
            }) {
                HStack {
                    Image(systemName: "pawprint.fill")
                    Text("GO! 出发遛弯")
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(LinearGradient(colors: [.appGreenMain, .appGreenDark], startPoint: .leading, endPoint: .trailing))
                .clipShape(Capsule())
                .shadow(color: .appGreenDark.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal, 50)
        }
        .padding(.bottom, 30)
    }
}

// 预览视图
#Preview {
    HomeView()
}
