//
//  DataManager.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/7.
//

import Foundation

@MainActor
class DataManager: ObservableObject {
    // 全局单例，方便在任何地方访问 (可选)
    static let shared = DataManager()
    
    // 发布给 UI 的数据源
    @Published var records: [WalkRecord] = []
    
    // 文件保存的名字
    private let fileName = "walk_history.json"
    
    init() {
        loadData()
    }
    
    // MARK: - 核心功能：保存数据
    func addRecord(_ record: WalkRecord) {
        records.insert(record, at: 0) // 把最新的插到最前面
        saveData()
    }
    
    func saveData() {
        do {
            // 1. 找到手机里的文档目录
            let url = getDocumentsDirectory().appendingPathComponent(fileName)
            
            // 2. 把数组编码成 JSON
            let data = try JSONEncoder().encode(records)
            
            // 3. 写入文件
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            print("💾 数据保存成功！路径: \(url)")
        } catch {
            print("❌ 数据保存失败: \(error)")
        }
    }
    
    // MARK: - 核心功能：读取数据
    func loadData() {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            let data = try Data(contentsOf: url)
            let decodedRecords = try JSONDecoder().decode([WalkRecord].self, from: data)
            self.records = decodedRecords
            print("📂 读取到 \(records.count) 条记录")
        } catch {
            print("⚠️ 还没有历史记录，或者读取失败 (这是正常的如果是第一次运行)")
            // 如果没数据，我们给几个假数据测试一下 (上线前记得删掉)
            self.records = [
                // 12月1日 (3次, 总计 ~4.5km)
                WalkRecord(day: 1, date: "12月1日", time: "07:30", distance: 1.5, duration: 20, mood: "happy", imageName: nil, route: nil),
                WalkRecord(day: 1, date: "12月1日", time: "12:15", distance: 1.0, duration: 15, mood: "normal", imageName: nil, route: nil),
                WalkRecord(day: 1, date: "12月1日", time: "19:00", distance: 2.0, duration: 30, mood: "tired", imageName: "dog_cutout", route: nil),
                
                // 12月2日 (1次, 1.2km)
                WalkRecord(day: 2, date: "12月2日", time: "18:45", distance: 1.2, duration: 18, mood: "happy", imageName: nil, route: nil),
                
                // 12月3日 (2次, 总计 3.0km)
                WalkRecord(day: 3, date: "12月3日", time: "08:00", distance: 1.5, duration: 25, mood: "normal", imageName: nil, route: nil),
                WalkRecord(day: 3, date: "12月3日", time: "20:30", distance: 1.5, duration: 25, mood: "happy", imageName: nil, route: nil),
                
                // 12月4日 (1次, 0.5km)
                WalkRecord(day: 4, date: "12月4日", time: "21:00", distance: 0.5, duration: 8, mood: "tired", imageName: nil, route: nil)
            ]
        }
    }
    
    // 获取手机沙盒的文档目录路径
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
