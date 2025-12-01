//
//  HomeView.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//
import SwiftUI
import PhotosUI // 👈 1. 引入 PhotosUI

struct HomeView: View {
    // 👈 2. 引入 ViewModel
    @StateObject private var viewModel = PetViewModel()
    
    // 相册选择器的状态
    @State private var selectedItem: PhotosPickerItem?
    
    // 动画状态
    @State private var isDogVisible = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("PetWalk")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(.appBrown)
                    .padding(.top, 20)
                
                Spacer()
                
                ZStack {
                    BlobBackgroundView()
                        .frame(height: 350)
                        .offset(y: -20)
                    
                    
                    // ------------------------------------------------
                    // 👇 3. 核心修改区域：点击狗狗换图
                    // ------------------------------------------------
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        ZStack {
                            if viewModel.isProcessing {
                                // 如果正在抠图，显示转圈圈
                                ProgressView()
                                    .scaleEffect(2)
                                    .tint(.appBrown)
                            } else {
                                // 显示图片逻辑
                                if let image = viewModel.currentPetImage {
                                    // A. 显示用户上传并抠图后的图片
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                } else {
                                    // B. 显示默认素材图片 (如果没有上传过)
                                    Image("tongtong")
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                        }
                        .frame(height: 280) // 统一高度
                        // 下面是之前的特效代码，保持不变
                        .shadow(color: .white, radius: 0, x: 2, y: 0)
                        .shadow(color: .white, radius: 0, x: -2, y: 0)
                        .shadow(color: .white, radius: 0, x: 0, y: 2)
                        .shadow(color: .white, radius: 0, x: 0, y: -2)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
                        .scaleEffect(isDogVisible ? 1.0 : 0.8)
                        .opacity(isDogVisible ? 1.0 : 0)
                    }
                    // 监听相册选择，一旦选了图，就交给 ViewModel 处理
                    .onChange(of: selectedItem) { newItem in
                        viewModel.selectAndProcessImage(from: newItem)
                    }
                    // ------------------------------------------------
                    
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
                
                dashboardSection // 这里的 dashboardSection 代码保持不变
                
                CustomTabBar()
            }
        }
    }
    
    // ... dashboardSection 的代码保持不变 ...
    var dashboardSection: some View {
         // (代码略，和你原来的一样)
         VStack(spacing: 30) {
            ZStack {
                Circle().stroke(Color.appGreenMain.opacity(0.2), lineWidth: 15)
                Circle()
                    .trim(from: 0, to: 0.4)
                    .stroke(
                        LinearGradient(colors: [.appGreenMain, .appGreenDark], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 5) {
                    Text("今日目标").font(.system(size: 14, weight: .medium)).foregroundColor(.appBrown.opacity(0.6))
                    Text("1.2km").font(.system(size: 32, weight: .bold)).foregroundColor(.appBrown)
                    Text("/ 3km").font(.system(size: 14, weight: .medium)).foregroundColor(.appBrown.opacity(0.6))
                }
            }
            .frame(width: 160, height: 160)
            
            Button(action: { print("Go") }) {
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
