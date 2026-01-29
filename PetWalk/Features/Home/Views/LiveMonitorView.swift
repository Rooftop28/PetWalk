//
//  LiveMonitorView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/29.
//

import SwiftUI
import MapKit

/// “云遛狗” 监控页面
struct LiveMonitorView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var liveManager = LiveSessionManager.shared
    @State private var inputCode: String = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074), // 默认北京
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        ZStack {
            // 背景
            Color.appBackground.ignoresSafeArea()
            
            if !liveManager.isWatching {
                // 1. 输入房间号界面
                entryView
            } else {
                // 2. 也是地图监控界面
                monitorView
            }
        }
        .onDisappear {
            // 页面消失时自动退出
            liveManager.leaveSession()
        }
        // 添加右滑返回手势
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 { // 向右滑
                        dismiss()
                    }
                    if value.translation.height > 100 { // 向下滑 (虽然sheet自带，但加一个保险)
                        dismiss()
                    }
                }
        )
    
        // 监听会话结束 (新增)
        .onChange(of: liveManager.sessionEnded) { _, ended in
            if ended {
                // 延迟一点退出，给用户一个提示感
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
        // 弹窗提示 (可选)
        .overlay {
            if liveManager.sessionEnded {
                VStack {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    Text("本次遛狗已结束")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(40)
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
                .transition(.scale)
            }
        }
    }
    
    // MARK: - 入口视图
    var entryView: some View {
        ZStack(alignment: .topTrailing) {
            // 关闭按钮
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray.opacity(0.6))
                    .padding()
            }
            .padding(.top, 40) // 适配安全区域
            
            VStack(spacing: 30) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 80))
                    .foregroundColor(.appGreenMain)
                
                Text("加入云遛狗")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.appBrown)
                
                Text("输入对方提供的 6 位房间码\n实时查看狗狗的位置")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                // 验证码输入框样式
                TextField("Room Code", text: $inputCode)
                    .font(.system(size: 32, weight: .heavy, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .frame(maxWidth: 200)
                    .onChange(of: inputCode) { _, newValue in
                        if newValue.count > 6 {
                            inputCode = String(newValue.prefix(6))
                        }
                    }
                
                Button(action: joinRoom) {
                    Text("连接")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(inputCode.count == 6 ? Color.appGreenMain : Color.gray)
                        .clipShape(Capsule())
                        .shadow(radius: 5)
                }
                .disabled(inputCode.count != 6)
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.top, 60)
        }
    }
    
    // MARK: - 监控视图
    var monitorView: some View {
        ZStack(alignment: .bottom) {
            // 地图
            Map(coordinateRegion: $region, showsUserLocation: false, annotationItems: [liveManager.remoteLocation].compactMap { $0 }) { payload in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: payload.lat, longitude: payload.lon)) {
                    ZStack {
                        Circle()
                            .fill(Color.appGreenMain.opacity(0.3))
                            .frame(width: 40, height: 40)
                        Image("tongtong") // 用狗狗头像
                            .resizable()
                            .scaledToFill()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }
            }
            .ignoresSafeArea()
            .onChange(of: liveManager.remoteLocation?.timestamp) { _, _ in
                // 异步更新，修复 View Update Cycle 问题
                DispatchQueue.main.async {
                    updateRegion()
                }
            }
            
            // 顶部信息栏
            VStack {
                HStack {
                    Button(action: {
                        liveManager.leaveSession()
                        dismiss() // 同时关闭页面
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("ROOM: \(liveManager.currentRoomCode ?? "---")")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                        
                        Text(liveManager.connectionStatus)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    
                    Spacer()
                    
                    // 占位
                    Image(systemName: "circle")
                        .hidden()
                }
                .padding()
                Spacer()
            }
            
            // 底部数据面板
            VStack(spacing: 10) {
                if let payload = liveManager.remoteLocation {
                    HStack(spacing: 30) {
                        VStack {
                            Text("速度")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(String(format: "%.1f km/h", payload.speed * 3.6))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appBrown)
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack {
                            Text("状态")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("正在遛狗")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appGreenMain)
                        }
                    }
                } else {
                    Text("等待信号中...")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .padding()
            .shadow(radius: 10)
        }
    }
    
    private func joinRoom() {
        guard inputCode.count == 6 else { return }
        liveManager.joinSession(code: inputCode)
    }
    
    // 收到新坐标时自动移动地图
    private func updateRegion() {
        guard let payload = liveManager.remoteLocation else { return }
        let newCenter = CLLocationCoordinate2D(latitude: payload.lat, longitude: payload.lon)
        withAnimation {
            region.center = newCenter
            // 保持缩放比例不变，或者可以设置默认比例
            // region.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        }
    }
}

// 扩展 WalkPayload 以便用于 MapAnnotation
extension WalkPayload: Identifiable {
    var id: Double { timestamp }
}

#Preview {
    LiveMonitorView()
}
