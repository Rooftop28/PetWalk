//
//  SplashView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import SwiftUI

/// 启动画面 - 展示 Logo、加载进度和状态文字
struct SplashView: View {
    @ObservedObject var initializer: AppInitializer
    
    // 动画状态
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var progressOpacity: Double = 0
    @State private var pawPrints: [PawPrint] = []
    
    var body: some View {
        ZStack {
            // 背景色
            Color.appBackground
                .ignoresSafeArea()
            
            // 装饰性爪印
            ForEach(pawPrints) { paw in
                Image(systemName: "pawprint.fill")
                    .font(.system(size: paw.size))
                    .foregroundColor(Color.appGreenMain.opacity(paw.opacity))
                    .rotationEffect(.degrees(paw.rotation))
                    .position(paw.position)
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo 区域
                VStack(spacing: 20) {
                    // 爪印 Logo
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appGreenMain, Color.appGreenMain.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.appGreenMain.opacity(0.3), radius: 20, y: 10)
                        
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // App 名称
                    Text("PetWalk")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(.appBrown)
                        .opacity(logoOpacity)
                    
                    // 副标题
                    Text("和毛孩子一起探索世界")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appBrown.opacity(0.6))
                        .opacity(textOpacity)
                }
                
                Spacer()
                
                // 加载动画区域
                VStack(spacing: 15) {
                    LemniscateBloomLoader()
                    
                    Text(initializer.statusText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appBrown.opacity(0.6))
                        .animation(.easeInOut(duration: 0.2), value: initializer.statusText)
                }
                .opacity(progressOpacity)
                .padding(.bottom, 80)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            // 启动入场动画
            startAnimations()
            
            // 生成装饰性爪印
            generatePawPrints()
            
            // 开始初始化任务
            Task {
                await initializer.initialize()
            }
        }
    }
    
    // MARK: - 动画
    
    private func startAnimations() {
        // Logo 入场
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // 副标题入场
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            textOpacity = 1.0
        }
        
        // 进度条入场
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            progressOpacity = 1.0
        }
    }
    
    private func generatePawPrints() {
        // 生成随机装饰性爪印
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for _ in 0..<6 {
            let paw = PawPrint(
                position: CGPoint(
                    x: CGFloat.random(in: 20...(screenWidth - 20)),
                    y: CGFloat.random(in: 50...(screenHeight - 150))
                ),
                size: CGFloat.random(in: 20...40),
                rotation: Double.random(in: -30...30),
                opacity: Double.random(in: 0.05...0.15)
            )
            pawPrints.append(paw)
        }
    }
}

// MARK: - 装饰性爪印模型

struct PawPrint: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let rotation: Double
    let opacity: Double
}

// MARK: - Lemniscate Bloom Loader (∞ 形加载动画)

struct LemniscateBloomLoader: View {
    private let progressDuration: TimeInterval = 5.6
    private let pulseDuration: TimeInterval = 5.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let progress = (now.truncatingRemainder(dividingBy: progressDuration)) / progressDuration
            let pulse = (now.truncatingRemainder(dividingBy: pulseDuration)) / pulseDuration
            
            Canvas { context, size in
                let baseA: CGFloat = 20.0
                let boost: CGFloat = 7.0
                let particleCount = 70
                let trailSpan: CGFloat = 0.4
                let TWO_PI = CGFloat.pi * 2
                
                let pulseAngle = CGFloat(pulse) * TWO_PI + 0.55
                let detailScale = 0.52 + ((sin(pulseAngle) + 1.0) / 2.0) * 0.48
                let a = baseA + detailScale * boost
                let scale = size.width / 100.0
                let center = CGPoint(x: 50 * scale, y: 50 * scale)
                
                var path = Path()
                for i in 0...480 {
                    let t = CGFloat(i) / 480.0 * TWO_PI
                    let denom = 1.0 + pow(sin(t), 2)
                    let x = center.x + (a * cos(t) * scale) / denom
                    let y = center.y + (a * sin(t) * cos(t) * scale) / denom
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                context.stroke(
                    path,
                    with: .color(Color.appGreenMain.opacity(0.15)),
                    style: StrokeStyle(lineWidth: 4.8, lineCap: .round)
                )
                
                for i in 0..<particleCount {
                    let tailOffset = CGFloat(i) / CGFloat(particleCount - 1)
                    var p = (CGFloat(progress) - tailOffset * trailSpan).truncatingRemainder(dividingBy: 1.0)
                    if p < 0 { p += 1.0 }
                    
                    let t = p * TWO_PI
                    let denom = 1.0 + pow(sin(t), 2)
                    let px = center.x + (a * cos(t) * scale) / denom
                    let py = center.y + (a * sin(t) * cos(t) * scale) / denom
                    
                    let fade = pow(1.0 - tailOffset, 0.56)
                    let radius = 0.9 + fade * 2.7
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: px - radius, y: py - radius, width: radius * 2, height: radius * 2)),
                        with: .color(Color.appGreenMain.opacity(0.06 + fade * 0.94))
                    )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(width: 120, height: 120)
    }
}

// MARK: - 预览

#Preview {
    SplashView(initializer: AppInitializer.shared)
}
