//
//  Color+Extensions.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//
import SwiftUI

extension Color {
    // MARK: - 动态主题颜色（从 ThemeManager 获取）
    // 注意：这些属性使用 MainActor.assumeIsolated 因为 SwiftUI 视图总是在主线程运行
    
    /// 背景色 - 跟随主题变化
    static var appBackground: Color {
        MainActor.assumeIsolated {
            ThemeManager.shared.backgroundColor
        }
    }
    
    /// 主色调（强调色/文字色）- 跟随主题变化
    static var appBrown: Color {
        MainActor.assumeIsolated {
            ThemeManager.shared.accentColor
        }
    }
    
    /// 主行动色（按钮、进度条等）- 跟随主题变化
    static var appGreenMain: Color {
        MainActor.assumeIsolated {
            ThemeManager.shared.primaryColor
        }
    }
    
    /// 主行动色深色版本 - 根据 primaryColor 计算
    static var appGreenDark: Color {
        MainActor.assumeIsolated {
            ThemeManager.shared.primaryColor.darker(by: 0.15)
        }
    }
    
    // MARK: - 静态颜色（不随主题变化）
    
    static let appYellowBlob = Color(hex: "FFE0B2") // 背景黄色光晕
    static let appTabSelected = Color(hex: "F57C00") // Tab选中黄/橙
    static let appTabUnselected = Color(hex: "9E9E9E") // Tab未选中灰
    
    // MARK: - Hex 初始化器
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - 颜色调整辅助方法
    
    /// 生成更深的颜色
    func darker(by percentage: Double = 0.2) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h), saturation: Double(s), brightness: max(0, Double(b) - percentage), opacity: Double(a))
    }
    
    /// 生成更浅的颜色
    func lighter(by percentage: Double = 0.2) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h), saturation: Double(s), brightness: min(1, Double(b) + percentage), opacity: Double(a))
    }
}

// MARK: - Liquid Glass 样式扩展

extension View {
    /// 主要玻璃卡片 (Island)：带 ambient 阴影的浮动卡片
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    /// 次要玻璃卡片：更轻的 Island
    func glassCardLight(cornerRadius: CGFloat = 24) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.thinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    /// 浮动按钮：胶囊形毛玻璃
    func glassButton() -> some View {
        self
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    /// 圆形图标按钮
    func glassCircle() -> some View {
        self
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
            )
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    /// 带品牌色调的 Island
    func glassTinted(_ color: Color, cornerRadius: CGFloat = 24) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(color.opacity(0.12))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    /// CTA 按钮：主操作按钮
    func primaryActionButton(gradient: [Color] = [.appGreenMain, .appGreenDark]) -> some View {
        self
            .background(
                Capsule()
                    .fill(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
            )
            .clipShape(Capsule())
            .shadow(color: gradient.first?.opacity(0.25) ?? .clear, radius: 10, x: 0, y: 4)
    }
}
