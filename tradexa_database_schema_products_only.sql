-- ============================================================
-- TRADEXA — Pivot: Products-Only Catalog (إلغاء Stores)
-- حذف فكرة المتاجر بالكامل والتركيز على Catalog مركزي
-- ============================================================

-- 1) حذف جدول stores بكل جداول الأطفال (foreign keys تُحذف تلقائيًا بـ CASCADE)
DROP TABLE IF EXISTS stores CASCADE;

-- 2) تنظيف جدول products إذا كان موجود من قبل:
--    - حذف store_id إذا كان موجود
--    - إضافة الأعمدة الجديدة إذا ما كانت موجودة
ALTER TABLE IF EXISTS products
  DROP COLUMN IF EXISTS store_id,
  ADD COLUMN IF NOT EXISTS original_price numeric(12, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS selling_price numeric(12, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS image_url text,
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT NOW();

-- 3) View إحصائيات كل قطاع:
--    تعرض عدد منتجات، عدد المبيعات (طلبات)، آخر تحديث منتج
DROP VIEW IF EXISTS vertical_stats CASCADE;
CREATE VIEW vertical_stats
WITH (security_invoker = true) AS
SELECT
  v.id AS vertical_id,
  COUNT(DISTINCT p.id) AS products_count,
  COUNT(DISTINCT o.id) AS orders_count,
  MAX(p.updated_at) AS last_product_updated_at
FROM verticals v
LEFT JOIN products p ON p.vertical_id = v.id
LEFT JOIN orders o ON o.vertical_id = v.id
GROUP BY v.id;

-- 4) تأكد من تفعيل RLS على products
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- 5) حذف السياسات القديمة لو كانت موجودة
DROP POLICY IF EXISTS "platform_admin_all_products" ON products;

-- 6) Policy جديد: Platform Admin يقدر يفعل أي حاجة
CREATE POLICY "platform_admin_all_products" ON products
  FOR ALL
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'platform_admin'
  );
