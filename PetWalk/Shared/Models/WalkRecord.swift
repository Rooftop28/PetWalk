//
//  WalkRecord.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/7.
//

import Foundation

// 1. 加上 Codable 协议，这样它才能被转换成 JSON 存进文件里
// 为了支持 Codable，我们需要一个简单的结构体来存坐标
struct RoutePoint: Codable {
    let lat: Double
    let lon: Double
}

struct WalkRecord: Identifiable, Codable {
    var id = UUID()
    let day: Int
    let date: String
    let time: String
    let distance: Double
    let duration: Int
    let mood: String
    let imageName: String?
    
    // 新增：轨迹数据
    let route: [RoutePoint]?
}
