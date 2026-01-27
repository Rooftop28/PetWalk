//
//  ShopView.swift
//  PetWalk
//
//  Created by Cursor AI on 2025/12/8.
//

import SwiftUI

struct ShopView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    
    // 抽奖状态
    @State private var drawnItem: TreasureItem?
    @State private var showDrawResult = false
    @State private var isDrawing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // 1. 余额大图显示
                    VStack(spacing: 10) {
                        Text("当前拥有")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 8) {
                            Text("🦴")
                                .font(.system(size: 40))
                            Text("\(dataManager.userData.totalBones)")
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundColor(.appBrown)
                                .contentTransition(.numericText(value: Double(dataManager.userData.totalBones)))
                        }
                    }
                    .padding(.top, 40)
                    
                    // 2. 宝箱/抽奖机 动画占位图
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 200, height: 200)
                            .shadow(color: .black.opacity(0.05), radius: 10)
                        
                        Image(systemName: "dice.fill")
                            .font(.system(size: 80))
                            .foregroundColor(isDrawing ? .gray : .appGreenMain)
                            .rotationEffect(.degrees(isDrawing ? 360 : 0))
                            .animation(isDrawing ? .linear(duration: 0.5).repeatForever(autoreverses: false) : .default, value: isDrawing)
                    }
                    
                    Text("消耗 100 骨头币\n随机获取稀有物品 (传说除外)")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .lineSpacing(5)
                    
                    Spacer()
                    
                    // 3. 抽奖按钮
                    Button(action: performDraw) {
                        HStack {
                            if isDrawing {
                                ProgressView().tint(.white)
                            } else {
                                Text("试试手气 ( -100 🦴 )")
                                    .fontWeight(.bold)
                            }
                        }
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            GameSystem.shared.canAffordDraw(userBones: dataManager.userData.totalBones)
                            ? Color.appGreenMain
                            : Color.gray
                        )
                        .clipShape(Capsule())
                        .shadow(color: GameSystem.shared.canAffordDraw(userBones: dataManager.userData.totalBones) ? .appGreenMain.opacity(0.4) : .clear, radius: 10, y: 5)
                    }
                    .disabled(isDrawing || !GameSystem.shared.canAffordDraw(userBones: dataManager.userData.totalBones))
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("神秘商店")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(.appBrown)
                }
            }
            // 结果弹窗
            .sheet(isPresented: $showDrawResult) {
                if let item = drawnItem {
                    DrawResultView(item: item, onDismiss: { showDrawResult = false })
                        // 改为全屏展示，视觉冲击力更强
                        .presentationDetents([.large])
                }
            }
        }
    }
    
    // MARK: - 抽奖逻辑
    func performDraw() {
        guard GameSystem.shared.canAffordDraw(userBones: dataManager.userData.totalBones) else { return }
        
        isDrawing = true
        
        // 模拟网络/动画延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 1. 扣费
            var currentUserData = dataManager.userData
            currentUserData.totalBones -= GameSystem.shared.drawCost
            
            // 2. 随机生成
            if let newItem = GameSystem.shared.drawItem() {
                // 3. 入库
                currentUserData.inventory[newItem.id, default: 0] += 1
                
                // 4. 保存数据
                dataManager.updateUserData(currentUserData)
                
                // 5. 显示结果
                self.drawnItem = newItem
                self.showDrawResult = true
            }
            
            isDrawing = false
        }
    }
}

