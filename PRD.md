这是一份经过更新的、包含了最新技术决策（如使用 JSON 存储、HealthKit 逻辑、Vision 抠图等）的完整 PRD。

你可以将此内容保存为 `PRD.md` 文件放在项目根目录下，或者直接复制给 Cursor，让它了解项目的全貌。

-----

# 📝 产品需求文档 (PRD) - PetWalk

| 项目名称 | PetWalk | 版本号 | v1.0 (MVP) |
| :--- | :--- | :--- | :--- |
| **项目代号** | CyberPup | **平台** | iOS & watchOS |
| **状态** | ✅ MVP 开发完成 | **核心技术** | SwiftUI, Vision, HealthKit, WatchConnectivity |

## 1. 产品概述 (Overview)

### 1.1 产品愿景

打造一款“把自家毛孩子装进 Apple Watch”的陪伴型工具应用。通过 Vision 技术自动提取用户宠物的形象，将其转化为电子宠物贴纸，结合真实的运动数据，让每一次遛狗都充满陪伴感和成就感。

### 1.2 核心价值主张 (USP)

  * **专属感**：使用用户真实宠物的照片（自动抠图），而非通用卡通形象。
  * **跨设备联动**：手机端管理形象与数据，手表端负责陪伴与记录。
  * **情感化记录**：足迹页面不仅是数据，更是结合了照片的回忆日历。

-----

## 2. 用户流程 (User Flow)

### 2.1 首次配置 (iOS)

1.  用户授权相册、健康、通知权限。
2.  用户上传一张宠物照片。
3.  **系统自动处理**：调用 Vision 框架去除背景，生成透明 PNG。
4.  **同步**：系统通过 `WCSession` 自动将处理好的图片发送至 Apple Watch。

### 2.2 遛狗循环 (The Loop)

1.  **开始**：用户在 Watch 或 iOS 点击“GO”按钮。
2.  **进行中**：记录时长、距离、心率。宠物形象伴随动画显示。
3.  **结束**：停止记录。
4.  **丰富记录 (iOS)**：用户可以在结束时（或稍后在足迹页）上传一张本次遛狗拍摄的照片。

### 2.3 回顾与成就 (History)

1.  用户进入“足迹” Tab。
2.  查看月度热力图：
      * 普通打卡日显示“绿色爪印”。
      * 上传了照片的日子显示“圆形缩略图”。
3.  点击缩略图可全屏查看当日回忆。

-----

## 3. 功能需求说明 (Functional Requirements)

### 3.1 iOS 端

| 模块 | 功能点 | 技术细节 | 状态 | 优先级 |
| :--- | :--- | :--- | :--- | :--- |
| **首页** | **智能抠图** | 使用 `VNGenerateForegroundInstanceMaskRequest` (iOS 17+) 实现一键去背。 | ✅ 已完成 | P0 |
| **首页** | **健康数据展示** | 集成 `HealthKit`，读取当天的步行距离 (`HKQuantityType.distanceWalkingRunning`) 和步数。实时更新进度环。 | ✅ 已完成 | P0 |
| **首页** | **地图轨迹** | 点击 GO 后进入地图模式，使用 MapKit 显示实时定位。宠物图标跟随移动，绘制红色轨迹线。 | ✅ 已完成 | P0 |
| **首页** | **Watch同步** | 使用 `WatchConnectivity` (`transferFile`) 将处理后的图片发送给手表。需处理图片压缩和传输队列。 | ✅ 已完成 | P0 |
| **首页** | **Tab导航** | 支持“陪伴”、“足迹”、“装扮”Tab 切换，使用 `MainTabView` 作为入口。 | ✅ 已完成 | P0 |
| **首页** | **开始/结束逻辑** | 实现 `WalkSessionManager`，支持计时器和模拟距离增长。UI 支持 `Walking` 状态切换。 | ✅ 已完成 | P0 |
| **足迹** | **数据持久化** | 使用 `Codable` + `FileManager` 将遛狗记录 (`WalkRecord`) 存为本地 JSON 文件 (`walk_history.json`)。 | ✅ 已完成 | P0 |
| **足迹** | **回忆日历** | 自定义 Grid 视图。支持“照片日历”和“热力图”两种模式切换，使用 3D 翻转动画。 | ✅ 已完成 | P0 |
| **足迹** | **轨迹回放** | 在历史详情页展示当次遛狗的静态地图轨迹。 | ✅ 已完成 | P0 |
| **足迹** | **本地图片加载** | 支持从 Documents 目录加载用户上传的历史图片。 | ✅ 已完成 | P0 |
| **其他** | **App Icon** | 正式配置 App Icon。 | ✅ 已完成 | P0 |
| **其他** | **实时活动** | (P1 待开发) 利用 `ActivityKit` 在灵动岛显示遛狗状态。 | ⏳ 待开发 | P1 |

### 3.2 WatchOS 端

| 模块 | 功能点 | 技术细节 | 状态 | 优先级 |
| :--- | :--- | :--- | :--- | :--- |
| **核心** | **接收图片** | 实现 `WCSessionDelegate` 接收 iOS 发来的文件，并更新 SwiftUI 视图。 | ✅ 已完成 | P0 |
| **核心** | **展示与动画** | 显示接收到的宠物图片。入场时播放弹性动画 (Spring Animation)，平时播放呼吸动画。 | ✅ 已完成 | P0 |
| **交互** | **开始/结束** | 极简界面，仅展示宠物和大号“GO”按钮。 | 🚧 待联调 | P0 |

-----

## 4. 数据模型 (Data Structure)

### 4.1 WalkRecord (Codable)

```swift
struct RoutePoint: Codable {
    let lat: Double
    let lon: Double
}

struct WalkRecord: Identifiable, Codable {
    var id: UUID
    let day: Int          // 日期 (用于日历定位)
    let date: String      // 完整日期字符串
    let time: String      // 开始时间
    let distance: Double  // 公里数
    let duration: Int     // 分钟数
    let mood: String      // 心情 (happy, normal, tired)
    let imageName: String? // 关联的本地图片文件名 (可选)
    let route: [RoutePoint]? // 轨迹坐标点
}
```

-----

## 5. UI/UX 设计规范 (Design Guidelines)

### 5.1 配色方案

  * **背景色**：`AppBackground` (#FFF9F0) - 温暖的奶油/米白色。
  * **主色调**：`AppGreenMain` (#8BC34A) - 活力草地绿，用于按钮、进度条、高亮。
  * **文字色**：`AppBrown` (#4A3021) - 深棕色，替代纯黑。
  * **辅助色**：`AppYellowBlob` (#FFE0B2) - 背景光晕。

### 5.2 视觉风格

  * **贴纸感**：宠物图片需添加白色描边 (`Shadow` trick) 和投影，模拟物理贴纸效果。
  * **圆润**：所有卡片、按钮使用大圆角 (Corner Radius 20+)。
  * **动效**：强调弹性 (Spring) 和 呼吸感，拒绝生硬的线性过渡。3D Flip 用于日历/热力图切换。

### 5.3 交互细节

  * **气泡对话**：宠物头顶常驻气泡，文案随机（如“去公园吗？”）。需要处理图层层级 (`ZStack`) 防止被遮挡。
  * **日历交互**：点击带图的日历格子，需使用 `MatchedGeometryEffect` 或 渐变动画 弹出大图。

-----

## 6. 技术栈与环境 (Tech Stack)

  * **IDE**: Xcode 15+
  * **Language**: Swift 5.9+
  * **Minimum OS**: iOS 17.0, watchOS 10.0
  * **Frameworks**:
      * SwiftUI (Life Cycle)
      * Vision (Background Removal)
      * HealthKit (Fitness Data)
      * MapKit & CoreLocation (Location & Route)
      * WatchConnectivity (Data Sync)
      * PhotosUI (Image Picker)
      * Combine (Data Binding)

-----

## 7. 待办事项 (Immediate Next Steps)

1.  **Watch 端完善**：处理真机连接问题，确保 HealthKit 在手表独立运行时也能记录。
2.  **真机测试**：实地测试 GPS 轨迹记录的稳定性和耗电量。
3.  **UI 细节打磨**：优化转场动画，适配不同尺寸屏幕。

-----

## 8. 调试与辅助工具 (Debug Tools)

> ⚠️ 注意：以下功能仅用于开发调试，发布 Release 版本前需移除或禁用。

1.  **地图模拟移动**：
    *   在地图模式下，**长按 (Long Press)** 地图任意位置。
    *   效果：触发模拟定位更新，宠物图标瞬移至该点，并绘制轨迹线。
    *   用途：在室内测试轨迹绘制和距离计算逻辑。
    *   代码位置：`WalkMapView.swift` (#if DEBUG), `LocationManager.swift` (#if DEBUG)
