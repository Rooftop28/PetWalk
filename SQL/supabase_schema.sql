-- =====================================================
-- PetWalk 云同步 - Supabase 数据库完整结构 (修正版 v2.1)
-- 修复了 "Trigger already exists" 错误
-- =====================================================

-- 1. 表结构 (如果表存在，跳过创建)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_achievements (
    user_id TEXT PRIMARY KEY,
    unlocked_achievements JSONB DEFAULT '[]',
    revealed_hints JSONB DEFAULT '[]',
    total_bones INTEGER DEFAULT 0,
    total_walks INTEGER DEFAULT 0,
    total_distance DOUBLE PRECISION DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    max_streak INTEGER DEFAULT 0,
    owned_title_ids JSONB DEFAULT '["title_default"]',
    owned_theme_ids JSONB DEFAULT '["theme_default"]',
    equipped_title_id TEXT DEFAULT 'title_default',
    equipped_theme_id TEXT DEFAULT 'theme_default',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_user_achievements_updated_at ON user_achievements(updated_at DESC);

CREATE TABLE IF NOT EXISTS profiles (
    user_id TEXT PRIMARY KEY REFERENCES user_achievements(user_id) ON DELETE CASCADE,
    nickname TEXT,
    avatar_url TEXT,
    bio TEXT,
    region TEXT,
    total_distance DOUBLE PRECISION DEFAULT 0,
    total_walks INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_profiles_region ON profiles(region);
CREATE INDEX IF NOT EXISTS idx_profiles_distance ON profiles(total_distance DESC);

CREATE TABLE IF NOT EXISTS pets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT REFERENCES user_achievements(user_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    breed TEXT,
    birth_date DATE,
    gender TEXT,
    avatar_url TEXT,
    ai_persona JSONB DEFAULT '{}',
    is_primary BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_pets_user_id ON pets(user_id);

CREATE TABLE IF NOT EXISTS walk_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT REFERENCES user_achievements(user_id) ON DELETE CASCADE,
    pet_id UUID REFERENCES pets(id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_seconds INTEGER,
    distance_meters DOUBLE PRECISION,
    step_count INTEGER,
    route_image_url TEXT,
    route_polyline TEXT,
    weather_info JSONB,
    ai_diary_content TEXT,
    ai_diary_generated_at TIMESTAMPTZ,
    poop_count INTEGER DEFAULT 0,
    pee_count INTEGER DEFAULT 0,
    avg_speed DOUBLE PRECISION,
    max_speed DOUBLE PRECISION,
    calories_burned INTEGER,
    bones_earned INTEGER DEFAULT 0,
    achievements_unlocked JSONB DEFAULT '[]',
    mood TEXT,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_walk_records_user_id ON walk_records(user_id);
CREATE INDEX IF NOT EXISTS idx_walk_records_start_time ON walk_records(start_time DESC);

CREATE TABLE IF NOT EXISTS inventory_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT REFERENCES user_achievements(user_id) ON DELETE CASCADE,
    walk_id UUID REFERENCES walk_records(id) ON DELETE SET NULL,
    item_id TEXT NOT NULL,
    item_name TEXT,
    item_category TEXT,
    rarity TEXT DEFAULT 'common',
    acquired_at TIMESTAMPTZ DEFAULT NOW(),
    is_new BOOLEAN DEFAULT TRUE,
    is_favorite BOOLEAN DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_inventory_user_id ON inventory_items(user_id);


-- 2. 函数 (使用 CREATE OR REPLACE，自动覆盖旧的)
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sync_walk_stats_to_user()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE user_achievements
    SET 
        total_distance = total_distance + COALESCE(NEW.distance_meters, 0) / 1000.0,
        total_walks = total_walks + 1,
        total_bones = total_bones + COALESCE(NEW.bones_earned, 0),
        updated_at = NOW()
    WHERE user_id = NEW.user_id;
    
    UPDATE profiles
    SET 
        total_distance = (SELECT total_distance FROM user_achievements WHERE user_id = NEW.user_id),
        total_walks = (SELECT total_walks FROM user_achievements WHERE user_id = NEW.user_id),
        updated_at = NOW()
    WHERE user_id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (user_id)
    VALUES (NEW.user_id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- 3. 触发器 (关键修复：先删除旧的，再创建新的)
-- =====================================================

-- 修复: update_user_achievements_updated_at
DROP TRIGGER IF EXISTS update_user_achievements_updated_at ON user_achievements;
CREATE TRIGGER update_user_achievements_updated_at
    BEFORE UPDATE ON user_achievements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 修复: update_profiles_updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 修复: after_walk_record_insert
DROP TRIGGER IF EXISTS after_walk_record_insert ON walk_records;
CREATE TRIGGER after_walk_record_insert
    AFTER INSERT ON walk_records
    FOR EACH ROW EXECUTE FUNCTION sync_walk_stats_to_user();

-- 修复: after_user_achievement_insert
DROP TRIGGER IF EXISTS after_user_achievement_insert ON user_achievements;
CREATE TRIGGER after_user_achievement_insert
    AFTER INSERT ON user_achievements
    FOR EACH ROW EXECUTE FUNCTION create_profile_for_new_user();


-- 4. RLS 策略 (关键修复：先删除旧的，再创建新的)
-- =====================================================
-- 策略如果重复创建也会报错，所以这里也加了防护

ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read" ON user_achievements;
CREATE POLICY "Allow public read" ON user_achievements FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert" ON user_achievements;
CREATE POLICY "Allow public insert" ON user_achievements FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow public update" ON user_achievements;
CREATE POLICY "Allow public update" ON user_achievements FOR UPDATE USING (true);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Profiles are publicly readable" ON profiles;
CREATE POLICY "Profiles are publicly readable" ON profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (true);

ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Pets are publicly readable" ON pets;
CREATE POLICY "Pets are publicly readable" ON pets FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can insert own pets" ON pets;
CREATE POLICY "Users can insert own pets" ON pets FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Users can update own pets" ON pets;
CREATE POLICY "Users can update own pets" ON pets FOR UPDATE USING (true);
DROP POLICY IF EXISTS "Users can delete own pets" ON pets;
CREATE POLICY "Users can delete own pets" ON pets FOR DELETE USING (true);

ALTER TABLE walk_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Walk records are publicly readable" ON walk_records;
CREATE POLICY "Walk records are publicly readable" ON walk_records FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can insert own walks" ON walk_records;
CREATE POLICY "Users can insert own walks" ON walk_records FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Users can update own walks" ON walk_records;
CREATE POLICY "Users can update own walks" ON walk_records FOR UPDATE USING (true);

ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Inventory publicly readable" ON inventory_items;
CREATE POLICY "Inventory publicly readable" ON inventory_items FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can insert own items" ON inventory_items;
CREATE POLICY "Users can insert own items" ON inventory_items FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Users can update own items" ON inventory_items;
CREATE POLICY "Users can update own items" ON inventory_items FOR UPDATE USING (true);


-- 5. 视图 (CREATE OR REPLACE 会自动处理)
-- =====================================================

CREATE OR REPLACE VIEW leaderboard_distance AS
SELECT 
    p.user_id,
    p.nickname,
    p.avatar_url,
    p.region,
    p.total_distance,
    p.total_walks,
    RANK() OVER (ORDER BY p.total_distance DESC) as global_rank
FROM profiles p
WHERE p.total_distance > 0
ORDER BY p.total_distance DESC;

CREATE OR REPLACE VIEW leaderboard_by_region AS
SELECT 
    p.user_id,
    p.nickname,
    p.avatar_url,
    p.region,
    p.total_distance,
    p.total_walks,
    RANK() OVER (PARTITION BY p.region ORDER BY p.total_distance DESC) as regional_rank
FROM profiles p
WHERE p.total_distance > 0 AND p.region IS NOT NULL
ORDER BY p.region, p.total_distance DESC;