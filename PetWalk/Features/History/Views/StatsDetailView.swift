//
//  StatsDetailView.swift
//  PetWalk
//
//  Created by Cursor AI on 2025/12/10.
//

import SwiftUI

enum StatsType {
    case distance  // 里程
    case duration  // 时长
    
    var title: String {
        switch self {
        case .distance: return "每日里程"
        case .duration: return "每日时长"
        }
    }
    
    var unit: String {
        switch self {
        case .distance: return "km"
        case .duration: return "分钟"
        }
    }
}

struct StatsDetailView: View {
    let type: StatsType
    @ObservedObject var dataManager = DataManager.shared
    
    @State private var weekOffset: Int = 0  // 0 = 本周，-1 = 上周，-2 = 上上周...
    @Environment(\.dismiss) var dismiss
    
    // 获取本周的开始日期（周一）
    var currentWeekStart: Date {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday == 1 ? 6 : weekday - 2)  // 周日是1，需要特殊处理
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: now)!
        return calendar.startOfDay(for: monday)
    }
    
    // 根据 weekOffset 获取目标周的开始日期
    var targetWeekStart: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart)!
    }
    
    // 获取本周7天的数据
    var weekData: [(day: String, value: Double)] {
        let calendar = Calendar.current
        var result: [(day: String, value: Double)] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: targetWeekStart)!
            let dayName = getDayName(for: date)
            
            // 筛选这一天的所有记录
            let dayRecords = dataManager.records.filter { record in
                let recordDay = record.day
                let targetDay = calendar.component(.day, from: date)
                return recordDay == targetDay
            }
            
            // 计算总值
            let value: Double
            switch type {
            case .distance:
                value = dayRecords.reduce(0.0) { $0 + $1.distance }
            case .duration:
                value = Double(dayRecords.reduce(0) { $0 + $1.duration }) / 60.0  // 转换为分钟
            }
            
            result.append((day: dayName, value: value))
        }
        
        return result
    }
    
    // 获取周标题
    var weekTitle: String {
        if weekOffset == 0 {
            return "本周"
        } else if weekOffset == -1 {
            return "上周"
        } else {
            let calendar = Calendar.current
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            let start = targetWeekStart
            let end = calendar.date(byAdding: .day, value: 6, to: start)!
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
    
    // 获取最大值（用于归一化条形图高度）
    var maxValue: Double {
        let values = weekData.map { $0.value }
        return values.max() ?? 1.0
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部标题栏
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.appBrown)
                    }
                    Spacer()
                    Text(type.title)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.appBrown)
                    Spacer()
                    // 占位，保持标题居中
                    Color.clear.frame(width: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)  // 为状态栏留出空间
                .padding(.bottom, 20)
                .background(Color.appBackground)  // 确保标题栏有背景
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 周选择器
                        HStack {
                            Button(action: { weekOffset -= 1 }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.appBrown)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.05), radius: 5)
                            }
                            
                            Spacer()
                            
                            Text(weekTitle)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.appBrown)
                            
                            Spacer()
                            
                            Button(action: { weekOffset += 1 }) {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundColor(weekOffset < 0 ? .appBrown : .gray.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.05), radius: 5)
                            }
                            .disabled(weekOffset >= 0)
                        }
                        .padding(.horizontal, 20)
                        
                        // 条形图
                        VStack(spacing: 20) {
                            // 图表区域
                            HStack(alignment: .bottom, spacing: 12) {
                                ForEach(weekData, id: \.day) { data in
                                    VStack(spacing: 8) {
                                        // 数值
                                        if data.value > 0 {
                                            Text(String(format: type == .distance ? "%.1f" : "%.0f", data.value))
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.appBrown)
                                        } else {
                                            Text(" ")
                                                .font(.system(size: 12))
                                        }
                                        
                                        // 条形
                                        let height = maxValue > 0 ? (data.value / maxValue) * 200 : 0
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(data.value > 0 ? Color.appGreenMain : Color.gray.opacity(0.2))
                                            .frame(height: max(height, 8))
                                            .frame(maxWidth: .infinity)
                                        
                                        // 星期
                                        Text(data.day)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.05), radius: 10)
                            .padding(.horizontal, 20)
                            
                            // 统计摘要
                            HStack(spacing: 20) {
                                let totalValue = weekData.reduce(0.0) { $0 + $1.value }
                                let avgValue = totalValue / 7.0
                                
                                WeekStatBox(title: "总计", value: String(format: type == .distance ? "%.1f" : "%.0f", totalValue), unit: type.unit)
                                WeekStatBox(title: "日均", value: String(format: type == .distance ? "%.1f" : "%.0f", avgValue), unit: type.unit)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .ignoresSafeArea(edges: .top)  // 整个视图忽略顶部安全区域
    }
    
    // 辅助函数：获取星期名称
    func getDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).replacingOccurrences(of: "周", with: "")
    }
}

// 小统计框
struct WeekStatBox: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.appBrown)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
