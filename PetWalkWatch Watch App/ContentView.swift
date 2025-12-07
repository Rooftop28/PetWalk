//
//  ContentView.swift
//  PetWalkWatch Watch App
//
//  Created by 熊毓敏 on 2025/12/2.
//

import SwiftUI

struct ContentView: View {
    // 监听接收器
    @StateObject private var connector = PhoneConnector()
    
    // 动画状态
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            // 1. 宠物展示区
            ZStack {
                // 背景光晕 (简化版)
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                if let image = connector.receivedImage {
                    // 如果收到了 iOS 发来的图
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .scaleEffect(isAnimating ? 1.05 : 0.95) // 呼吸动画
                } else {
                    // 还没收到图时的占位符
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("请在手机上\n上传照片")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .padding(.top, 5)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
            
            Spacer()
            
            // 2. 简单的开始按钮
            Button(action: {
                print("开始 Watch 运动")
            }) {
                Text("GO")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
            }
            .background(Color.green)
            .clipShape(Circle()) // 胶囊或圆形按钮在手表上更常见
            .frame(height: 45)
        }
        .padding()
    }
}
