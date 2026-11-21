-- ============================================================
-- TRADEXA — الطلبات اليدوية + إدارة المستخدمين + باركود الدخول
-- نفّذ هذا الملف كاملاً بـ Supabase SQL Editor
-- ============================================================

-- ------------------------------------------------------------
-- القسم ١: جدول الطلبات
-- ------------------------------------------------------------

-- فك ارتباط الطلبات بالمتاجر الملغية
ALTER TABLE orders DROP COLUMN IF EXISTS store_id;

-- الطلب اليدوي ما إله مشتري مسجّل — نخلي buyer_id اختياري
ALTER TABLE orders ALTER COLUMN buyer_id DROP NOT NULL;

-- بيانات العميل للطلبات اليدوية
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS customer_name text,
  ADD COLUMN IF NOT EXISTS customer_phone text,
  ADD COLUMN IF NOT EXISTS customer_address text,
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS is_manual boolean NOT NULL DEFAULT false;

-- ضبط قيم الحالة المسموحة لتطابق التطبيق
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE orders ADD CONSTRAINT orders_status_check
  CHECK (status IN ('pending','confirmed','shipped','delivered','cancelled'));

-- حذف الطلب يحذف أسطره تلقائيًا
ALTER TABLE order_items DROP CONSTRAINT IF EXISTS order_items_order_id_fkey;
ALTER TABLE order_items ADD CONSTRAINT order_items_order_id_fkey
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;

-- صلاحيات الأدمن على الطلبات
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_manage_orders" ON orders;
CREATE POLICY "admin_manage_orders" ON orders
  FOR ALL
  USING (current_user_role() = 'platform_admin')
  WITH CHECK (current_user_role() = 'platform_admin');

DROP POLICY IF EXISTS "admin_manage_order_items" ON order_items;
CREATE POLICY "admin_manage_order_items" ON order_items
  FOR ALL
  USING (current_user_role() = 'platform_admin')
  WITH CHECK (current_user_role() = 'platform_admin');

-- ------------------------------------------------------------
-- القسم ٢: باركود الدخول للمستخدمين
-- ------------------------------------------------------------

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS access_token text UNIQUE,
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS token_issued_at timestamptz;

-- فهرس للبحث السريع وقت تسجيل الدخول بالمسح
CREATE INDEX IF NOT EXISTS idx_profiles_access_token
  ON profiles(access_token) WHERE access_token IS NOT NULL;

-- توليد رمز عشوائي غير قابل للتخمين
CREATE OR REPLACE FUNCTION generate_access_token()
RETURNS text LANGUAGE sql AS $$
  SELECT 'TDX-' || encode(gen_random_bytes(16), 'hex');
$$;

GRANT EXECUTE ON FUNCTION generate_access_token() TO authenticated;

-- إعطاء كل مستخدم حالي رمزًا لو ما عنده
UPDATE profiles
SET access_token = generate_access_token(),
    token_issued_at = NOW()
WHERE access_token IS NULL;

-- ملاحظة: ما في سياسة RLS جديدة على profiles — السياسات الموجودة
-- (admin_view_all_profiles / admin_manage_profiles) بتغطي القراءة
-- والتعديل وهي محصورة بـ platform_admin، فالرمز محمي تلقائيًا.
