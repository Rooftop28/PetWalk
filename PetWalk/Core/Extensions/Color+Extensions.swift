//
//  Color+Extensions.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//
import SwiftUI

extension Color {
    // 设计系统颜色
    static let appBackground = Color(hex: "FFF9F0") // 奶油白背景
    static let appBrown = Color(hex: "4A3021")      // 深棕色文字
    static let appGreenMain = Color(hex: "8BC34A")  // 主行动绿 (浅)
    static let appGreenDark = Color(hex: "689F38")  // 主行动绿 (深)
    static let appYellowBlob = Color(hex: "FFE0B2") // 背景黄色光晕
    static let appTabSelected = Color(hex: "F57C00") // Tab选中黄/橙
    static let appTabUnselected = Color(hex: "9E9E9E") // Tab未选中灰
    
    // Hex 初始化器
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
}
