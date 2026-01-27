# 📅 开发日志 (Dev Log) - 2025/12/07

## 🎯 核心目标
实现 PetWalk 的核心 MVP 功能，包括地图遛狗记录、历史轨迹回放、热力图展示、App Icon 配置以及基础架构重构。

## ✅ 今日完成事项 (Completed)

### 1. 🏗 架构与基础设施
- **目录重构**: 将扁平的项目结构重构为 `Features/` (Home, History, Walk), `Core/`, `Shared/` 的清晰架构。
- **导航升级**: 实现了 `MainTabView`，替换了原有的单一视图入口，支持 Tab 切换。
- **配置修复**:
    - 补全 `Info.plist` 缺失的 Key，解决闪退问题。
    - 移除 `Entitlements` 中多余的 "Sign in with Apple"，解决签名报错。
    - 确认并开启 Background Modes (Location updates)。

### 2. 🐕 核心遛狗流程 (The Loop)
- **`LocationManager`**: 实现了基于 CoreLocation 的位置追踪，支持后台更新。
- **`WalkSessionManager`**: 实现了遛狗会话管理（计时、计步、状态流转）。
- **`WalkMapView`**:
    - 集成 MapKit，实时绘制绿色轨迹线。
    - **自定义 Annotation**: 使用 Vision 抠图后的宠物头像作为地图定位点，替代系统蓝点。
    - **Debug 工具**: 添加了长按地图模拟移动的功能 (`#if DEBUG`)，方便室内测试。
- **`WalkSummaryView`**: 实现了遛狗结束后的结算页，支持拍照、心情打分，并将数据（含轨迹）持久化。

### 3. 📅 历史与回顾 (History & Insights)
- **数据持久化**: 升级 `WalkRecord` 模型，新增 `route: [RoutePoint]?` 字段以存储轨迹。
- **`HistoryView`**:
    - **热力图 (Heatmap)**: 实现了 Github 风格的贡献度热力图，支持卡片 3D 翻转切换。
    - **Photo Grid**: 保留了原有的图片日历模式，支持翻转查看。
    - **数据优化**: 修复了“打卡天数”的去重逻辑，优化了“< 1分钟”的时长显示。
- **`WalkDetailView`**: 新增详情页，支持查看单次遛狗的静态轨迹图、照片和详细数据。

### 4. 🎨 UI/UX 与资源
- **App Icon**: 配置了正式的 App Icon (1024x1024)，并处理了 Xcode 的尺寸验证问题。
- **风格统一**: 统一了全 App 的米黄色背景 (`Color.appBackground`) 和圆角卡片风格。
- **本地图片**: 实现了完善的 `loadLocalImage` 逻辑，确保用户拍摄的照片能正确回显。

## 🚧 遗留/待办 (Pending)
1.  **Watch 端联动**: 目前 Watch 端仅能接收图片，尚未实现双向控制和独立计步。
2.  **代码清理**: 移除或规范化 Debug 工具代码。
3.  **测试**: 进行真机实地遛狗测试，验证 GPS 漂移处理和后台保活稳定性。

## 📝 总结
今日完成了从静态原型到功能完备 MVP 的关键跨越。核心的“遛狗-记录-回顾”闭环已经打通，地图轨迹和热力图功能极大地丰富了用户体验。解决了多个关键的工程化问题（签名、配置、图标），应用已具备 TestFlight 测试的基础条件。

---
*记录人: Cursor AI Assistant*
*时间: 2025-12-07*

<br>

# 📅 开发日志 (Dev Log) - 2025/12/08

## 🎯 核心目标
引入游戏化机制（Gamification）以提升用户留存，实现基于时间的动态宠物状态机，并优化系统架构以支持未来扩展。

## ✅ 今日完成事项 (Completed)

### 1. 🎮 游戏化系统 (Gamification)
- **数据模型**: 创建了 `TreasureItem` (宝藏物品) 和 `UserData` (用户数据)，更新了 `WalkRecord` 以记录单次收益。
- **经济系统**: 实现了 `GameSystem`，支持里程换算骨头币 (Bones) 和基于概率的物品掉落机制。
- **UI 实现**:
  - `WalkSummaryView`: 结算页增加“本次收获”展示。
  - `InventoryView`: 新增“收藏柜”页面，展示收集到的稀有物品。
  - `HomeView`: 首页右上角增加骨头币实时显示。

### 2. 🤖 动态宠物状态机 (Pet State Machine)
- **逻辑实现**: 根据 `lastWalkDate` 自动计算宠物心情 (Excited, Happy, Expecting, Depressed)。
- **架构重构**: 将庞大的状态配置解耦为独立的 Provider：
  - `PetAnimationProvider`: 管理动作 (如兴奋跳跃、郁闷趴下)。
  - `PetDialogueProvider`: 管理气泡文案。
  - `PetOverlayProvider`: 管理视觉贴纸 (如 ✨, 🎵, 💧)。
- **视觉优化**:
  - 实现了“郁闷”状态下眼泪流下的复合动画 (位移 + 淡出)。
  - 修复了 SwiftUI 视图复用导致的贴纸残留问题 (`.id()` 标识符)。

### 3. 🛠 调试与工具
- **Debug 菜单**: 在首页添加了 Debug 菜单，可强制切换宠物心情以测试动画和文案。
- **状态测试**: 验证了不同时间跨度下的心情变化逻辑。

## 📝 总结
今日成功将应用从单纯的“工具”升级为具有“养成”属性的产品。游戏化系统的加入赋予了遛狗行为更多的正反馈，而动态状态机让宠物显得更加鲜活。架构上的 Provider 模式重构为后续接入天气系统和节日活动打下了坚实基础。

---
*记录人: Cursor AI Assistant*
*时间: 2025-12-08*

<br>

# 📅 开发日志 (Dev Log) - 2026/01/28

## 🎯 核心目标
由于个人开发者难以获取游戏化系统所需的图画资源，将"寻宝收藏柜"系统替换为"成就系统"。成就系统以文字描述为主，减少对图片资源的依赖，同时保留骨头币作为奖励货币，新增称号和主题配色作为兑换内容。

## ✅ 今日完成事项 (Completed)

### 1. 🏆 成就系统 (Achievement System)
- **数据模型**: 创建了 `Achievement.swift`，定义了 4 大类成就：
  - **里程类**: 新手上路(1km)、小区巡逻员(10km)、街道探险家(50km)、城市漫步者(100km)、马拉松冠军(500km)
  - **频率类**: 初次遛弯(1次)、习惯养成(10次)、遛狗达人(50次)、百次纪念(100次)
  - **连续打卡类**: 三日坚持、一周坚持、月度坚持、百日坚持
  - **特殊成就**: 早起的鸟儿(6点前)、夜行侠(22点后)、长途跋涉(单次5km)、美食诱惑(预留POI接口)
- **检测逻辑**: 创建了 `AchievementManager.swift`，实现成就自动检测、连续打卡计算和进度追踪。
- **UI 实现**: 创建了 `AchievementView.swift`，包含：
  - 分类 Tab 切换（里程达人/坚持不懈/连续打卡/特殊成就）
  - 进度统计卡片（总里程、总次数、连续打卡天数）
  - 成就卡片列表（图标、名称、描述、进度条、奖励骨头币）
  - 成就详情弹窗

### 2. 🎁 奖励商店 (Reward Shop)
- **称号系统**: 创建了 `UserTitle` 模型，提供 6 个可购买称号：
  - 遛狗新手(免费)、散步达人(50币)、公园常客(100币)、马拉松狗爸/狗妈(200币)、城市探险家(300币)、传奇遛狗人(500币)
- **主题配色**: 创建了 `AppTheme` 模型，提供 6 套主题：
  - 默认奶油色(免费)、森林绿(100币)、夕阳橙(150币)、海洋蓝(150币)、深夜模式(200币)、樱花粉(200币)
- **UI 实现**: 创建了 `RewardShopView.swift`，支持：
  - 骨头币余额显示
  - 称号/主题分栏切换
  - 购买和装备功能
  - 主题颜色预览条

### 3. 🔄 系统改造
- **UserData 升级**: 新增字段：
  - `totalWalks`: 总遛狗次数
  - `totalDistance`: 总里程
  - `currentStreak` / `maxStreak`: 连续打卡天数
  - `unlockedAchievements`: 已解锁成就集合
  - `ownedTitleIds` / `equippedTitleId`: 称号系统
  - `ownedThemeIds` / `equippedThemeId`: 主题系统
- **WalkSummaryView 重构**: 
  - 移除物品掉落展示
  - 新增成就解锁弹窗和列表预览
  - 遛狗结束后自动检测并解锁成就
- **导航更新**:
  - Tab 枚举从 `dress` 改为 `achievement`
  - 底部导航栏第三个 Tab 改为"成就"(trophy.fill 图标)
  - 骨头币按钮点击打开奖励商店

### 4. 📦 旧代码归档
以下文件已标记为 `DEPRECATED` 并注释，保留代码以便后续参考：
- `TreasureItem.swift` - 宝藏物品模型
- `InventoryView.swift` - 收藏柜页面
- `ShopView.swift` - 抽奖商店页面
- `GameSystem.swift` - 注释了 `generateDrops()` 和抽奖相关方法，保留 `calculateBones()`

### 5. 🎨 主题系统实现 (Theme System)
- **ThemeManager**: 创建了 `ThemeManager.swift` 单例，管理全局主题切换：
  - 动态颜色属性（backgroundColor、primaryColor、accentColor）
  - 主题切换时自动保存到 UserData
  - 预留了 `specialEffectType` 接口用于未来特殊主题效果
- **Color+Extensions 改造**: 将静态颜色改为动态获取：
  - `Color.appBackground` / `Color.appGreenMain` / `Color.appBrown` 现在跟随主题变化
  - 使用 `MainActor.assumeIsolated` 确保线程安全
- **RewardShopView 集成**: 购买主题后调用 `ThemeManager.applyTheme()` 立即生效
- **PetWalkApp 集成**: 观察 ThemeManager，主题变化时自动刷新 UI

### 6. 👤 用户形象系统 (User Avatar System)
- **AvatarManager**: 创建了 `AvatarManager.swift`，处理 Ready Player Me 头像：
  - 头像 URL 存储和本地图片缓存
  - 自动将 GLB 模型 URL 转换为 2D 渲染图 URL
  - 支持从缓存加载和刷新下载
- **UserAvatarView**: 创建了用户头像展示组件：
  - 显示头像图片 + 当前装备的称号标签
  - 点击可打开头像编辑器
  - 呼吸动画效果
- **AvatarCreatorView**: 集成 Ready Player Me WebView：
  - 支持使用预热的 WebView 加速加载
  - 监听头像导出事件并保存
- **HomeView 布局调整**: 
  - 宠物贴纸向左偏移 30pt
  - 用户头像（70x70）显示在右下方，营造"反差萌"效果
  - 称号标签显示在头像下方

### 7. 🚀 启动画面与预加载 (Splash Screen & Preloading)
- **AppInitializer**: 创建了启动任务管理器：
  - 协调用户数据、主题、HealthKit 数据的加载
  - 进度追踪和状态文字更新
  - 最小显示时间 1.5 秒，确保用户能看清启动画面
- **SplashView**: 创建了启动画面 UI：
  - Logo + 应用名称 + 副标题
  - 动态进度条和加载状态文字
  - 装饰性爪印背景
  - 入场动画效果
- **WebViewPreloader**: 创建了 WebView 预热器：
  - 启动时后台预加载 Ready Player Me 页面
  - 10 秒超时机制，避免阻塞启动流程
  - 用户打开头像编辑器时直接使用预热的 WebView
  - 编辑器关闭后自动开始新一轮预热
- **PetWalkApp 改造**: 集成启动流程，先显示 SplashView，完成后过渡到 MainTabView

### 8. 🔧 技术优化
- **@MainActor 适配**: 为 ThemeManager、AvatarManager 添加 @MainActor 标注，解决 Swift 并发检查错误
- **UserData 扩展**: 新增 `avatarURL` 和 `avatarImageCachePath` 字段
- **AppTheme 扩展**: 新增 `specialEffectType` 和 `specialEffectConfig` 预留字段

## 🚧 遗留/待办 (Pending)
1. ~~**主题配色应用**~~: ✅ 已实现 ThemeManager，主题切换即时生效。
2. ~~**称号展示**~~: ✅ 已在首页用户头像下方展示当前装备的称号。
3. **POI 成就**: "美食诱惑"等基于地点的成就接口已预留，待接入 MapKit POI 服务。
4. **Ready Player Me 头像显示问题**: 创建头像后点击 Next，头像未能正确显示到首页，需排查 WebView 消息监听和 URL 解析逻辑。

## 📝 总结
今日完成了游戏化系统的重大改造，从依赖图片资源的"寻宝收藏"转向以文字为主的"成就系统"。新系统更适合个人开发者维护，同时保留了骨头币经济和奖励机制的核心玩法。

此外，还实现了完整的主题切换系统和用户形象系统。主题系统支持 6 种配色方案，购买后即时生效；用户形象系统集成了 Ready Player Me SDK，支持创建 3D 头像并在首页展示。

为了提升用户体验，新增了启动画面和资源预加载机制，包括 WebView 后台预热，减少用户等待时间。

---
*记录人: Cursor AI Assistant*
*时间: 2026-01-28*
