-- =====================================================
-- PetWalk 测试数据生成脚本 (v3.0)
-- 适配新架构：使用 UUID 格式的 user_id
-- =====================================================

-- 0. 清理旧的测试数据（可选，取消注释执行）
-- DELETE FROM inventory_items WHERE user_id LIKE 'test_%';
-- DELETE FROM walk_records WHERE user_id LIKE 'test_%';
-- DELETE FROM pets WHERE user_id LIKE 'test_%';
-- DELETE FROM profiles WHERE user_id LIKE 'test_%';
-- DELETE FROM user_achievements WHERE user_id LIKE 'test_%';

-- 1. 创建测试用户 (user_achievements)
-- 使用 UUID 格式，模拟 Supabase Auth 生成的 ID
INSERT INTO user_achievements (user_id, total_bones, total_walks, total_distance) VALUES 
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 500, 15, 25.5),
('b1ffcd00-ad1c-5fg9-cc7e-7cca0e491b22', 200, 8, 12.3),
('c2ggde11-be2d-6gh0-dd8f-8ddb1f502c33', 50, 3, 5.0)
ON CONFLICT (user_id) DO UPDATE SET
    total_bones = EXCLUDED.total_bones,
    total_walks = EXCLUDED.total_walks,
    total_distance = EXCLUDED.total_distance;

-- 2. 完善用户信息 (profiles)
-- 包含 game_center_id 关联字段
INSERT INTO profiles (user_id, nickname, region, avatar_url, game_center_id, total_distance, total_walks) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '闪电狗', '北京', 'https://api.dicebear.com/7.x/adventurer/svg?seed=dog1', 'GC_TEST_001', 25.5, 15),
('b1ffcd00-ad1c-5fg9-cc7e-7cca0e491b22', '呼噜王', '上海', 'https://api.dicebear.com/7.x/adventurer/svg?seed=dog2', 'GC_TEST_002', 12.3, 8),
('c2ggde11-be2d-6gh0-dd8f-8ddb1f502c33', '捡屎官', '北京', 'https://api.dicebear.com/7.x/adventurer/svg?seed=dog3', 'GC_TEST_003', 5.0, 3)
ON CONFLICT (user_id) DO UPDATE SET
    nickname = EXCLUDED.nickname,
    region = EXCLUDED.region,
    avatar_url = EXCLUDED.avatar_url,
    game_center_id = EXCLUDED.game_center_id,
    total_distance = EXCLUDED.total_distance,
    total_walks = EXCLUDED.total_walks;

-- 3. 给他们分配宠物 (pets)
-- 包含 voice_url 用于测试排行榜声音功能
INSERT INTO pets (user_id, name, breed, voice_url, ai_persona) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '旺财', '柯基', NULL, '{"traits": ["社牛", "腿短"], "voice_style": "sweet"}'),
('b1ffcd00-ad1c-5fg9-cc7e-7cca0e491b22', '奥利奥', '哈士奇', NULL, '{"traits": ["拆家", "二哈"], "voice_style": "grumpy"}'),
('c2ggde11-be2d-6gh0-dd8f-8ddb1f502c33', '小白', '萨摩耶', NULL, '{"traits": ["微笑天使", "掉毛"], "voice_style": "poetic"}')
ON CONFLICT DO NOTHING;

-- 4. 模拟遛狗记录 (walk_records)
-- 注意：这些记录的距离已经在上面的 user_achievements 和 profiles 中体现
-- 这里只是为了有历史记录可查

-- 用户 1: 多次遛狗
INSERT INTO walk_records (user_id, distance_meters, duration_seconds, start_time, end_time, bones_earned) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 5000, 3600, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days' + INTERVAL '1 hour', 50),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 3500, 2400, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '40 minutes', 35),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 2000, 1800, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '30 minutes', 20);

-- 用户 2: 几次遛狗
INSERT INTO walk_records (user_id, distance_meters, duration_seconds, start_time, end_time, bones_earned) VALUES
('b1ffcd00-ad1c-5fg9-cc7e-7cca0e491b22', 4000, 2700, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days' + INTERVAL '45 minutes', 40),
('b1ffcd00-ad1c-5fg9-cc7e-7cca0e491b22', 2300, 1500, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '25 minutes', 23);

-- 用户 3: 刚开始遛狗
INSERT INTO walk_records (user_id, distance_meters, duration_seconds, start_time, end_time, bones_earned) VALUES
('c2ggde11-be2d-6gh0-dd8f-8ddb1f502c33', 2000, 1200, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '20 minutes', 20);

-- 5. 模拟捡到的物品 (inventory_items)
INSERT INTO inventory_items (user_id, item_id, item_name, rarity) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'golden_bone', '黄金骨头', 'legendary'),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'old_tennis_ball', '破旧网球', 'common'),
('b1ffcd00-ad1c-5fg9-cc7e-7cca0e491b22', 'dry_branch', '干树枝', 'common')
ON CONFLICT DO NOTHING;

-- 6. 验证数据
-- 运行以下查询检查数据是否正确
-- SELECT * FROM leaderboard_distance;
-- SELECT * FROM leaderboard_by_region WHERE region = '北京';
