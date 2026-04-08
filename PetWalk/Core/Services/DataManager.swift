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
    @Published var userData: UserData = UserData.initial
    
    // 文件保存的名字
    private let fileName = "walk_history.json"
    private let userDataFileName = "user_data.json"
    
    init() {
        loadData()
        loadUserData()
        
        #if DEBUG
        syncMockUserDataIfNeeded()
        #endif
    }
    
    // MARK: - UserData 管理
    func updateUserData(_ newData: UserData) {
        self.userData = newData
        // 编码和写盘都放到后台任务中，彻底释放主线程
        let url = getDocumentsDirectory().appendingPathComponent(userDataFileName)
        
        Task.detached(priority: .userInitiated) {
            do {
                let data = try JSONEncoder().encode(newData)
                try data.write(to: url, options: [.atomic, .completeFileProtection])
                print("💾 用户数据保存成功！")
            } catch {
                print("❌ 用户数据保存失败: \(error)")
            }
        }
    }
    
    func saveUserData() {
        let url = getDocumentsDirectory().appendingPathComponent(userDataFileName)
        let data: Data
        do {
            data = try JSONEncoder().encode(userData)
        } catch {
            print("❌ 用户数据编码失败: \(error)")
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try data.write(to: url, options: [.atomic, .completeFileProtection])
                print("💾 用户数据保存成功！")
            } catch {
                print("❌ 用户数据保存失败: \(error)")
            }
        }
    }
    
    func loadUserData() {
        let url = getDocumentsDirectory().appendingPathComponent(userDataFileName)
        do {
            let data = try Data(contentsOf: url)
            self.userData = try JSONDecoder().decode(UserData.self, from: data)
            print("📂 读取到用户数据: 骨头币 \(userData.totalBones)")
        } catch {
            print("⚠️ 还没有用户数据，使用默认初始值")
            self.userData = UserData.initial
        }
    }
    
    // MARK: - 核心功能：保存数据
    func addRecord(_ record: WalkRecord) {
        records.insert(record, at: 0) // 把最新的插到最前面
        saveData()
        
        // 更新最后遛狗时间
        userData.lastWalkDate = Date()
        saveUserData()
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
            print("⚠️ 还没有历史记录，使用 mock 数据")
            #if DEBUG
            self.records = DataManager.generateMockRecords()
            #else
            self.records = []
            #endif
        }
    }
    
    // 获取手机沙盒的文档目录路径
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Mock 数据生成器（DEBUG）
    
    #if DEBUG
    /// 如果使用了 mock 记录，同步 UserData 的统计数据
    private func syncMockUserDataIfNeeded() {
        guard !records.isEmpty, userData.totalWalks == 0 else { return }
        
        let validRecords = records.filter { ($0.duration) >= 5 && ($0.distance) >= 0.2 }
        let activeRecords = records.filter { ($0.duration) >= 10 && ($0.distance) >= 0.5 }
        
        userData.totalWalks = validRecords.count
        userData.totalDistance = validRecords.reduce(0) { $0 + $1.distance }
        userData.totalBones = 1000 + activeRecords.reduce(0) { $0 + ($1.bonesEarned ?? 0) }
        userData.lastWalkDate = records.first?.timestamp
        userData.currentStreak = 3
        userData.maxStreak = 12
        userData.lastStreakDate = Calendar.current.startOfDay(for: Date().addingTimeInterval(-86400))
        
        // 解锁一些基础成就
        userData.unlockedAchievements = [
            "distance_hello_world",
            "frequency_10",
            "frequency_50",
            "distance_marathon",
        ]
        
        print("📊 Mock UserData 同步完成: \(userData.totalWalks)次遛狗, \(String(format: "%.1f", userData.totalDistance))km, \(userData.totalBones)骨头币")
    }
    
    /// 生成覆盖过去约 60 天的模拟遛狗记录，用于测试分级系统和历史统计
    static func generateMockRecords() -> [WalkRecord] {
        var records: [WalkRecord] = []
        let calendar = Calendar.current
        let now = Date()
        let dateF = DateFormatter()
        dateF.dateFormat = "MM月dd日"
        let timeF = DateFormatter()
        timeF.dateFormat = "HH:mm"
        
        let moods = ["happy", "normal", "tired"]
        let diaries = [
            "今天天气不错，和主人在公园跑了好久，追了两只鸽子但没追上。",
            "下午遛弯闻到了隔壁家猫的味道，在那棵树下蹲了好久。",
            "主人今天走得特别快，害得我舌头都伸出来了，但好开心！",
            "晚上的风好舒服，路灯下有好多飞虫，我试着咬了几只。",
            nil
        ]
        
        // 模拟时间段配置：早上(6-8)、中午(11-13)、傍晚(17-19)、晚上(20-22)
        let timeSlots: [(Int, Int)] = [(6, 8), (11, 13), (17, 19), (20, 22)]
        
        for dayOffset in 1...60 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            
            // 每天 0-3 次遛狗（约 75% 的天有遛狗，符合真实场景）
            let weekday = calendar.component(.weekday, from: date)
            let isWeekend = weekday == 1 || weekday == 7
            let walkCount: Int
            let roll = Int.random(in: 0...100)
            if roll < 15 {
                walkCount = 0
            } else if roll < 45 {
                walkCount = 1
            } else if roll < 80 {
                walkCount = isWeekend ? 3 : 2
            } else {
                walkCount = isWeekend ? 3 : 2
            }
            
            let shuffledSlots = timeSlots.shuffled()
            
            for i in 0..<walkCount {
                let slot = shuffledSlots[i % shuffledSlots.count]
                let hour = Int.random(in: slot.0...slot.1)
                let minute = Int.random(in: 0...59)
                
                guard let walkDate = calendar.date(
                    bySettingHour: hour, minute: minute, second: 0, of: date
                ) else { continue }
                
                let day = calendar.component(.day, from: walkDate)
                
                // 距离和时长正态分布模拟
                let distKm: Double
                let durMin: Int
                let tierRoll = Int.random(in: 0...100)
                
                if tierRoll < 8 {
                    // ~8%: 低于基础门槛（invalid）
                    distKm = Double.random(in: 0.05...0.18)
                    durMin = Int.random(in: 1...4)
                } else if tierRoll < 18 {
                    // ~10%: 基础记录层（5分钟+200米 但不到有效运动层）
                    distKm = Double.random(in: 0.2...0.48)
                    durMin = Int.random(in: 5...9)
                } else {
                    // ~82%: 有效运动层
                    distKm = Double.random(in: 0.5...4.5)
                    durMin = Int.random(in: 10...55)
                }
                
                let bones = distKm >= 0.5 && durMin >= 10
                    ? max(1, Int(distKm * 10))
                    : 0
                
                let mood = moods.randomElement()!
                let diary = diaries.randomElement() ?? nil
                
                let record = WalkRecord(
                    day: day,
                    date: dateF.string(from: walkDate),
                    time: timeF.string(from: walkDate),
                    distance: Double(String(format: "%.2f", distKm))!,
                    duration: durMin,
                    mood: mood,
                    imageName: nil,
                    timestamp: walkDate,
                    route: generateMockRoute(distanceKm: distKm),
                    itemsFound: nil,
                    bonesEarned: bones,
                    isCloudWalk: false,
                    aiDiary: diary,
                    aiDiaryGeneratedAt: diary != nil ? walkDate : nil
                )
                records.append(record)
            }
        }
        
        // 按时间倒序
        records.sort { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }
        print("📋 生成了 \(records.count) 条 mock 遛狗记录，覆盖过去 60 天")
        return records
    }
    
    /// 生成简单的模拟轨迹
    private static func generateMockRoute(distanceKm: Double) -> [RoutePoint] {
        let baseLat = 31.2304 + Double.random(in: -0.01...0.01)
        let baseLon = 121.4737 + Double.random(in: -0.01...0.01)
        let points = max(5, Int(distanceKm * 20))
        var route: [RoutePoint] = []
        var lat = baseLat
        var lon = baseLon
        for _ in 0..<points {
            lat += Double.random(in: -0.0005...0.0005)
            lon += Double.random(in: -0.0005...0.0005)
            route.append(RoutePoint(lat: lat, lon: lon))
        }
        return route
    }
    #endif
}
