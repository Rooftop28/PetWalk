//
//  UserAvatarView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import SwiftUI

/// 用户头像展示组件 - 显示头像和称号
struct UserAvatarView: View {
    @ObservedObject var avatarManager = AvatarManager.shared
    @ObservedObject var dataManager = DataManager.shared
    
    // 点击头像的回调（用于打开头像编辑器）
    var onTap: (() -> Void)?
    
    // 头像尺寸
    var avatarSize: CGFloat = 80
    
    // 是否显示称号
    var showTitle: Bool = true
    
    // 动画状态
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            // 头像
            Button(action: { onTap?() }) {
                ZStack {
                    // 背景圆圈
                    Circle()
                        .fill(Color.white)
                        .frame(width: avatarSize + 8, height: avatarSize + 8)
                        .shadow(color: Color.appGreenMain.opacity(0.3), radius: 8)
                    
                    // 头像内容
                    if avatarManager.isLoading {
                        // 加载中
                        ProgressView()
                            .frame(width: avatarSize, height: avatarSize)
                    } else if let image = avatarManager.avatarImage {
                        // 有头像
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: avatarSize, height: avatarSize)
                            .clipShape(Circle())
                    } else {
                        // 默认占位图
                        defaultAvatarView
                    }
                    
                    // 编辑图标（右下角）
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.appGreenMain)
                                .background(Circle().fill(Color.white).frame(width: 18, height: 18))
                        }
                    }
                    .frame(width: avatarSize, height: avatarSize)
                }
                .scaleEffect(isAnimating ? 1.02 : 0.98)
                .animation(
                    Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 称号标签
            if showTitle {
                titleLabel
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    // MARK: - 默认头像视图
    private var defaultAvatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.appGreenMain.opacity(0.3), Color.appGreenMain.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: avatarSize, height: avatarSize)
            
            Image(systemName: "person.fill")
                .font(.system(size: avatarSize * 0.4))
                .foregroundColor(.appGreenMain)
        }
    }
    
    // MARK: - 称号标签
    private var titleLabel: some View {
        let title = dataManager.userData.equippedTitle
        
        return HStack(spacing: 4) {
            Image(systemName: title.iconSymbol)
                .font(.system(size: 10))
            Text(title.name)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.appGreenMain)
                .shadow(color: Color.appGreenMain.opacity(0.3), radius: 3)
        )
    }
}

// MARK: - 紧凑版本（不显示称号，适用于小空间）
struct CompactUserAvatarView: View {
    @ObservedObject var avatarManager = AvatarManager.shared
    
    var size: CGFloat = 40
    var onTap: (() -> Void)?
    
    var body: some View {
        Button(action: { onTap?() }) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: size + 4, height: size + 4)
                    .shadow(color: .black.opacity(0.1), radius: 3)
                
                if let image = avatarManager.avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.5))
                        .foregroundColor(.appGreenMain)
                        .frame(width: size, height: size)
                        .background(Circle().fill(Color.appGreenMain.opacity(0.2)))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 40) {
        UserAvatarView()
        
        CompactUserAvatarView()
    }
    .padding()
    .background(Color.appBackground)
}
