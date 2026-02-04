-- =====================================================
-- PetWalk - Supabase Storage Policy for pet-voices bucket
-- 适配匿名访问模式（使用 Game Center ID 而非 Supabase Auth）
-- =====================================================

-- 0. 清理旧策略
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "User Upload" ON storage.objects;
DROP POLICY IF EXISTS "User Modify" ON storage.objects;
DROP POLICY IF EXISTS "User Delete" ON storage.objects;
DROP POLICY IF EXISTS "Allow Upload to pet-voices" ON storage.objects;
DROP POLICY IF EXISTS "Allow Update in pet-voices" ON storage.objects;
DROP POLICY IF EXISTS "Allow Delete in pet-voices" ON storage.objects;
DROP POLICY IF EXISTS "Give public access to pet-voices" ON storage.objects;

-- ========================================================
-- 策略 1: 允许所有人下载 (SELECT)
-- ========================================================
-- 逻辑: 只要是 'pet-voices' 桶里的文件，谁都能读取(播放)
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'pet-voices');

-- ========================================================
-- 策略 2: 允许任何人上传 (INSERT)
-- ========================================================
-- 逻辑: 
-- 1. 必须传到 'pet-voices' 桶
-- 2. 文件路径格式为 {userId}/voice.m4a，由 App 端控制
-- 注意: 因为使用 Game Center ID 而非 Supabase Auth，
--       无法使用 auth.uid() 验证，改为开放上传
CREATE POLICY "Allow Upload to pet-voices"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'pet-voices');

-- ========================================================
-- 策略 3: 允许更新 (UPDATE)
-- ========================================================
CREATE POLICY "Allow Update in pet-voices"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'pet-voices');

-- ========================================================
-- 策略 4: 允许删除 (DELETE)
-- ========================================================
CREATE POLICY "Allow Delete in pet-voices"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'pet-voices');
