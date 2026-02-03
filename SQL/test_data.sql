-- =====================================================
-- PetWalk 测试数据生成脚本
-- =====================================================

-- 1. 模拟创建 3 个用户 (user_achievements)
-- 注意：插入后，触发器会自动在 profiles 表创建对应记录
INSERT INTO user_achievements (user_id) VALUES 
('test_user_001'),
('test_user_002'),
('test_user_003')
ON CONFLICT (user_id) DO NOTHING;

-- 2. 完善用户信息 (profiles)
-- 我们给他们起个名字，方便在排行榜上看
UPDATE profiles SET nickname = '⚡️ 闪电狗', region = 'Beijing', avatar_url = 'https://api.dicebear.com/7.x/adventurer/svg?seed=1' WHERE user_id = 'test_user_001';
UPDATE profiles SET nickname = '💤 呼噜王', region = 'Shanghai', avatar_url = 'https://api.dicebear.com/7.x/adventurer/svg?seed=2' WHERE user_id = 'test_user_002';
UPDATE profiles SET nickname = '🦴 捡屎官', region = 'Beijing', avatar_url = 'https://api.dicebear.com/7.x/adventurer/svg?seed=3' WHERE user_id = 'test_user_003';

-- 3. 给他们分配宠物 (pets)
INSERT INTO pets (user_id, name, breed, ai_persona) VALUES
('test_user_001', '旺财', '柯基', '{"traits": ["社牛", "腿短"], "voice_style": "sweet"}'),
('test_user_002', '奥利奥', '哈士奇', '{"traits": ["拆家", "二哈"], "voice_style": "grumpy"}'),
('test_user_003', '小白', '萨摩耶', '{"traits": ["微笑天使", "掉毛"], "voice_style": "poetic"}');

-- 4. 模拟遛狗记录 (walk_records)
-- 关键测试点：插入后，请检查 profiles 表的 total_distance 是否自动增加了！

-- 用户 1: 走了很远 (5km)
INSERT INTO walk_records (user_id, distance_meters, duration_seconds, start_time, end_time) 
VALUES ('test_user_001', 5000, 3600, NOW() - INTERVAL '1 day', NOW() - INTERVAL '23 hours');

-- 用户 1: 又走了一次 (2.5km) -> 总共应该是 7.5km
INSERT INTO walk_records (user_id, distance_meters, duration_seconds, start_time, end_time) 
VALUES ('test_user_001', 2500, 1800, NOW(), NOW() + INTERVAL '30 minutes');

-- 用户 2: 走了一点点 (1km)
INSERT INTO walk_records (user_id, distance_meters, duration_seconds, start_time, end_time) 
VALUES ('test_user_002', 1000, 900, NOW(), NOW() + INTERVAL '15 minutes');

-- 用户 3: 还没遛狗 (0km)
-- 不插入记录

-- 5. 模拟捡到一个物品 (inventory_items)
INSERT INTO inventory_items (user_id, item_id, item_name, rarity)
VALUES ('test_user_001', 'golden_bone', '黄金骨头', 'legendary');