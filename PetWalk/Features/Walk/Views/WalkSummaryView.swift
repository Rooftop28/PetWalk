//
//  WalkSummaryView.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/7.
//

import SwiftUI
import PhotosUI
import UIKit

struct WalkSummaryView: View {
    // 输入参数：完整的遛狗会话数据
    let sessionData: WalkSessionData
    let routeCoordinates: [RoutePoint] // 轨迹数据
    
    // 回调：完成保存
    var onFinish: () -> Void
    
    // 便捷访问属性
    var duration: TimeInterval { sessionData.duration }
    var distance: Double { sessionData.distance }
    var walkStartTime: Date { sessionData.startTime }
    
    @StateObject private var dataManager = DataManager.shared
    
    // 表单状态
    @State private var mood: String = "happy" // happy, tired, normal
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    
    // 动画
    @State private var isVisible = false
    
    // 游戏化奖励状态
    @State private var earnedBones: Int = 0
    @State private var unlockedAchievements: [Achievement] = []
    @State private var showAchievementPopup = false
    @State private var currentAchievementIndex = 0
    
    // 初始化
    init(sessionData: WalkSessionData, routeCoordinates: [RoutePoint], onFinish: @escaping () -> Void) {
        self.sessionData = sessionData
        self.routeCoordinates = routeCoordinates
        self.onFinish = onFinish
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // 1. 标题
                    Text("遛弯完成！")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.appBrown)
                        .padding(.top, 40)
                    
                    // 2. 成绩卡片
                    HStack(spacing: 20) {
                        StatBox(title: "距离", value: String(format: "%.2f", distance), unit: "km")
                        StatBox(title: "时长", value: formatDuration(duration), unit: "min")
                    }
                    .padding(.horizontal)
                    
                    // 2.5 奖励展示区 (骨头币 + 成就)
                    VStack(spacing: 15) {
                        Text("本次收获")
                            .font(.headline)
                            .foregroundColor(.appBrown)
                        
                        HStack(spacing: 30) {
                            // 骨头币
                            VStack {
                                Text("🦴")
                                    .font(.system(size: 36))
                                Text("+\(earnedBones)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appBrown)
                                    .contentTransition(.numericText(value: Double(earnedBones)))
                            }
                            
                            // 成就解锁提示
                            if !unlockedAchievements.isEmpty {
                                VStack(spacing: 5) {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.yellow)
                                    Text("解锁 \(unlockedAchievements.count) 个成就")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.appBrown)
                                }
                                .onTapGesture {
                                    currentAchievementIndex = 0
                                    showAchievementPopup = true
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                        
                        // 成就列表预览
                        if !unlockedAchievements.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(unlockedAchievements) { achievement in
                                    HStack(spacing: 10) {
                                        Image(systemName: achievement.iconSymbol)
                                            .font(.title3)
                                            .foregroundColor(achievement.category.color)
                                            .frame(width: 30)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(achievement.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.appBrown)
                                            Text("+\(achievement.rewardBones) 🦴")
                                                .font(.caption)
                                                .foregroundColor(.appGreenMain)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.appGreenMain)
                                    }
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 10)
                                    .background(achievement.category.color.opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    .transition(.scale)
                    
                    // 3. 心情选择
                    VStack(alignment: .leading, spacing: 15) {
                        Text("狗狗心情如何？")
                            .font(.headline)
                            .foregroundColor(.appBrown)
                        
                        HStack(spacing: 25) {
                            MoodButton(mood: "happy", icon: "face.smiling.fill", color: .orange, selectedMood: $mood)
                            MoodButton(mood: "normal", icon: "pawprint.fill", color: .appGreenMain, selectedMood: $mood)
                            MoodButton(mood: "tired", icon: "zzz", color: .blue, selectedMood: $mood)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    
                    // 4. 照片记录
                    VStack(alignment: .leading, spacing: 15) {
                        Text("拍张照留念吧")
                            .font(.headline)
                            .foregroundColor(.appBrown)
                        
                        // 照片预览区域
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .frame(height: 200)
                                .shadow(color: .black.opacity(0.05), radius: 10)
                            
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            } else {
                                VStack(spacing: 10) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.appGreenMain)
                                    Text("从相册选择或拍照添加")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        // 从相册选择 / 拍照 两个入口
                        HStack(spacing: 20) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Label("从相册选择", systemImage: "photo.on.rectangle.angled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.appGreenMain)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .onChange(of: selectedItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        self.selectedImage = image
                                    }
                                }
                            }
                            
                            Button {
                                showCamera = true
                            } label: {
                                Label("拍照", systemImage: "camera.fill")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.appGreenMain)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                        }
                    }
                    .padding(.horizontal)
                    .fullScreenCover(isPresented: $showCamera) {
                        CameraImagePicker(image: $selectedImage, isPresented: $showCamera)
                    }
                    
                    Spacer(minLength: 50)
                    
                    // 5. 保存按钮
                    Button(action: saveRecord) {
                        Text("保存记录")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.appGreenMain)
                            .clipShape(Capsule())
                            .shadow(color: .appGreenMain.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            
            // 成就解锁弹窗
            if showAchievementPopup, currentAchievementIndex < unlockedAchievements.count {
                AchievementUnlockPopup(
                    achievement: unlockedAchievements[currentAchievementIndex],
                    onDismiss: {
                        if currentAchievementIndex < unlockedAchievements.count - 1 {
                            currentAchievementIndex += 1
                        } else {
                            showAchievementPopup = false
                        }
                    }
                )
            }
        }
        .onAppear {
            calculateRewards()
        }
    }
    
    // 计算奖励（骨头币 + 成就检测）
    private func calculateRewards() {
        // 计算骨头币
        let bones = GameSystem.shared.calculateBones(distanceKm: distance)
        
        // 检测成就（需要先获取副本，修改后再设置回去）
        // 使用完整的 sessionData 进行成就检测（包含天气、POI 等信息）
        var userData = dataManager.userData
        let achievements = AchievementManager.shared.checkAndUnlockAchievements(
            userData: &userData,
            sessionData: sessionData
        )
        
        // 计算成就奖励的骨头币
        let achievementBones = achievements.reduce(0) { $0 + $1.rewardBones }
        
        // 更新状态（带动画）
        withAnimation(.spring().delay(0.5)) {
            self.earnedBones = bones + achievementBones
            self.unlockedAchievements = achievements
        }
        
        // 如果有成就解锁，稍后显示弹窗
        if !achievements.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showAchievementPopup = true
            }
        }
        
        // 打印调试信息
        if let weather = sessionData.weather {
            print("WalkSummaryView: 天气 - \(weather.condition), \(Int(weather.temperature))°C")
        }
        print("WalkSummaryView: 路过餐厅 \(sessionData.passedRestaurantCount) 家, 绕圈 \(sessionData.homeLoopCount) 次")
    }
    
    // 保存逻辑
    private func saveRecord() {
        // 更新 UserData (累加骨头币，成就已在 calculateRewards 中处理)
        var currentUserData = dataManager.userData
        currentUserData.totalBones += earnedBones
        currentUserData.lastWalkDate = Date()
        
        // 再次调用成就检测以确保数据一致性（已经解锁的不会重复解锁）
        _ = AchievementManager.shared.checkAndUnlockAchievements(
            userData: &currentUserData,
            sessionData: sessionData
        )
        
        dataManager.updateUserData(currentUserData)
        
        // 1. 保存图片到本地
        var imageName: String?
        if let image = selectedImage {
            let fileName = "walk_\(UUID().uuidString).jpg"
            if let data = image.jpegData(compressionQuality: 0.8) {
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
                try? data.write(to: url)
                imageName = fileName
            }
        }
        
        // 2. 创建记录对象
        let now = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: now)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let record = WalkRecord(
            day: day,
            date: dateFormatter.string(from: now),
            time: timeFormatter.string(from: now),
            distance: distance,
            duration: Int(duration / 60),
            mood: mood,
            imageName: imageName,
            route: routeCoordinates,
            itemsFound: nil, // 不再使用物品系统
            bonesEarned: earnedBones
        )
        
        // 3. 存入 DataManager
        dataManager.addRecord(record)
        
        // 4. 关闭页面
        onFinish()
    }
    
    // 辅助格式化
    func formatDuration(_ interval: TimeInterval) -> String {
        return String(format: "%.0f", interval / 60)
    }
}

// MARK: - 成就解锁弹窗
struct AchievementUnlockPopup: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // 弹窗内容
            VStack(spacing: 20) {
                // 图标
                ZStack {
                    Circle()
                        .fill(achievement.category.color.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: achievement.iconSymbol)
                        .font(.system(size: 45))
                        .foregroundColor(achievement.category.color)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                Text("成就解锁！")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text(achievement.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.appBrown)
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 5) {
                    Text("奖励")
                        .foregroundColor(.gray)
                    Text("🦴 +\(achievement.rewardBones)")
                        .fontWeight(.bold)
                        .foregroundColor(.appGreenMain)
                }
                .font(.headline)
                
                Button(action: onDismiss) {
                    Text("太棒了！")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200)
                        .padding()
                        .background(achievement.category.color)
                        .cornerRadius(15)
                }
            }
            .padding(30)
            .background(Color.appBackground)
            .cornerRadius(25)
            .shadow(radius: 20)
            .padding(40)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// 子组件
struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title).font(.caption).foregroundColor(.gray)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 30, weight: .bold, design: .rounded)).foregroundColor(.appBrown)
                Text(unit).font(.caption).foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

struct MoodButton: View {
    let mood: String
    let icon: String
    let color: Color
    @Binding var selectedMood: String
    
    var isSelected: Bool { selectedMood == mood }
    
    var body: some View {
        Button(action: { selectedMood = mood }) {
            VStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(color: isSelected ? color.opacity(0.4) : .black.opacity(0.05), radius: 8)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : color)
                }
                Text(mood.capitalized)
                    .font(.caption)
                    .foregroundColor(isSelected ? color : .gray)
            }
        }
    }
}

// MARK: - 摄像头拍照 (UIImagePickerController 包装)
struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        
        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage {
                self.parent.image = img
            }
            DispatchQueue.main.async { [weak self] in
                self?.parent.isPresented = false
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.isPresented = false
            }
        }
    }
}

