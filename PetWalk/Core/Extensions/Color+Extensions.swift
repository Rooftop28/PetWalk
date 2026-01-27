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
