# PetWalk 成就清单

本文档基于以下代码整理：

- `/Users/user/Desktop/code/mein/PetWalk/PetWalk/Core/Services/AchievementManager.swift`
- `/Users/user/Desktop/code/mein/PetWalk/PetWalk/Shared/Models/Achievement.swift`

当前共定义 `44` 个成就。

- `43` 个存在实际解锁路径或可正常统计进度
- `1` 个已定义但当前逻辑未实现
- 另有 `2` 个在成就检测逻辑中出现，但未在成就定义中注册，因此当前无法真正解锁

## 1. 里程类

| ID | 成就名称 | 达成条件 | 备注 |
| --- | --- | --- | --- |
| `distance_1` | 新手上路 | 累计遛狗 `1km` |  |
| `distance_10` | 小区巡逻员 | 累计遛狗 `10km` |  |
| `distance_50` | 街道探险家 | 累计遛狗 `50km` |  |
| `distance_100` | 城市漫步者 | 累计遛狗 `100km` |  |
| `distance_42` | 全马选手 | 累计遛狗 `42km` | 文案写 `42.195km`，代码按 `Int(totalDistance) >= 42` 判定 |
| `distance_500` | 日行千里 | 累计遛狗 `500km` |  |
| `distance_1000` | 万里长征 | 累计遛狗 `1000km` | 隐藏成就 |

## 2. 频率类

| ID | 成就名称 | 达成条件 | 备注 |
| --- | --- | --- | --- |
| `frequency_1` | 初次遛弯 | 完成 `1` 次遛狗 |  |
| `frequency_10` | 习惯养成 | 完成 `10` 次遛狗 |  |
| `frequency_50` | 遛狗达人 | 完成 `50` 次遛狗 |  |
| `frequency_100` | 百次纪念 | 完成 `100` 次遛狗 |  |

## 3. 连续打卡类

| ID | 成就名称 | 达成条件 | 备注 |
| --- | --- | --- | --- |
| `streak_3` | 三日坚持 | 连续 `3` 天遛狗打卡 |  |
| `streak_7` | 一周坚持 | 连续 `7` 天遛狗打卡 |  |
| `streak_30` | 月度坚持 | 连续 `30` 天遛狗打卡 |  |
| `streak_100` | 百日坚持 | 连续 `100` 天遛狗打卡 | 隐藏成就 |

## 4. 景点打卡类

| ID | 成就名称 | 达成条件 | 备注 |
| --- | --- | --- | --- |
| `landmark_park_1` | 公园初探 | 到访 `1` 个公园 |  |
| `landmark_park_5` | 公园巡逻员 | 累计到访 `5` 个不同公园 |  |
| `landmark_all_10` | 地标猎人 | 累计打卡 `10` 个不同景点 |  |
| `landmark_home_30` | 家门口的守护者 | 在同一地点遛狗 `30` 次 |  |

## 5. 速度 / 强度类

| ID | 成就名称 | 达成条件 | 备注 |
| --- | --- | --- | --- |
| `performance_speed_fast` | 闪电狗 | 单次平均配速 `>= 8km/h` | 隐藏成就 |
| `performance_speed_slow` | 养生步伐 | 单次时长 `>= 30分钟` 且距离 `< 0.5km` |  |
| `performance_steady_5` | 稳定输出 | 连续 `5` 次遛狗配速保持在 `4-6km/h` | 连续计数保存在 `UserDefaults` |
| `performance_long_walk` | 长途跋涉 | 单次距离 `>= 5km` |  |

## 6. 环境 / 天气类

| ID | 成就名称 | 达成条件 | 备注 |
| --- | --- | --- | --- |
| `environment_rooster` | 闻鸡起舞 | 开始时间在 `4:00-6:00` | 隐藏成就 |
| `environment_dark_knight` | 暗夜骑士 | 开始时间在 `23:00-2:00` | 隐藏成就 |
| `environment_early_bird` | 早起的鸟儿 | 开始时间在 `6:00-7:00` |  |
| `environment_night_owl` | 夜行侠 | 开始时间在 `22:00` 后 |  |
| `environment_rainy` | 风雨无阻 | 雨天遛狗且满足恶劣天气门槛 `>= 15分钟` | 隐藏成就 |
| `environment_frozen` | 冰雪奇缘 | 气温 `< -5°C` 且满足恶劣天气门槛 `>= 15分钟` | 隐藏成就 |
| `environment_summer` | 夏日战士 | 气温 `> 35°C`，开始时间在 `17:00-20:00`，且满足恶劣天气门槛 `>= 15分钟` | 隐藏成就 |
| `environment_weekend_4` | 周末狂欢 | 连续 `4` 个周末有遛狗记录 | 代码按周末累计逻辑统计 |

## 7. 复杂上下文类

| ID | 成就名称 | 达成条件 | 备注 |
| --- | --- | --- | --- |
| `context_iron_will` | 减肥特种兵 | 路过餐厅数 `>= 3` | 隐藏成就 |
| `context_restaurant_10` | 美食诱惑大师 | 路过餐厅数 `>= 10` | 隐藏成就 |
| `context_wanderer` | 三过家门而不入 | 绕起点 `>= 3` 圈 | 隐藏成就 |
| `context_dizzy` | 鬼打墙 | 原地转圈 `>= 5` 次 | 隐藏成就 |
| `context_artist` | 完美的圆 | 轨迹形成闭环 | 隐藏成就 |
| `context_homing` | 我想回家 | 返程速度与去程速度比值 `>= 2` | 隐藏成就 |
| `context_companion_100` | 长情陪伴 | 累计遛狗时长 `>= 100小时` | 隐藏成就；累计时长保存在 `UserDefaults` |
| `context_explorer` | 拓荒者 | 离起点最远距离 `>= 5km` | 隐藏成就 |
| `context_local_lord` | 地头蛇 | 以家为中心 `1km` 半径内累计探索 `50` 条不同轨迹 | 已定义，但当前检测逻辑未实现 |
| `context_sniffer` | 嗅探专家 | 单次时长 `>= 30分钟` 且距离 `< 0.5km` | 隐藏成就；与“养生步伐”条件重复 |

## 8. 社交互动类

| ID | 成就名称 | 达成条件 | 备注 |
| --- | --- | --- | --- |
| `social_nanny_10` | 金牌保姆 | 直播 / 代遛累计 `10` 次 |  |
| `social_trustworthy` | 使命必达 | 直播过程中累计收到 `5` 个赞 |  |
| `social_cloud_walker` | 云遛狗 | 观看直播累计 `1800` 秒，即 `30分钟` | 需调用观众端检测逻辑 |

## 当前代码中的异常项

以下成就在检测逻辑中存在，但在成就定义列表中不存在，因此当前无法真正解锁：

| ID | 成就名称 | 检测条件 | 问题 |
| --- | --- | --- | --- |
| `environment_snow` | 雪地行者 | 下雪天且满足恶劣天气门槛 `>= 15分钟` | `AchievementManager` 有检测，`Achievement.swift` 无定义 |
| `environment_foggy` | 大雾行者 | 大雾天且满足恶劣天气门槛 `>= 15分钟` | `AchievementManager` 有检测，`Achievement.swift` 无定义 |

## 说明

- 里程、次数、连续打卡类成就主要基于 `userData` 中的累计统计解锁。
- 部分复杂成就依赖 `UserDefaults` 持久化的辅助统计，例如稳定配速、连续周末、累计遛狗时长。
- `context_local_lord` 当前只在成就定义中存在，`AchievementManager` 注释说明“暂时跳过”。
- `performance_speed_slow` 和 `context_sniffer` 目前使用的是同一套判定条件：`时长 >= 30 分钟且距离 < 0.5km`。
