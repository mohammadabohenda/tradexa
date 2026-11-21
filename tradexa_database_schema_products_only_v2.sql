-- ============================================================
-- TRADEXA — Pivot: Products-Only Catalog (v2 — آمن على البيانات)
-- ============================================================

-- 1) حذف جدول stores
DROP TABLE IF EXISTS stores CASCADE;

-- 2) تنظيف جدول products:
--    - إذا ما كان vertical_id موجود، نضيفه ونملأه من store_id
--    - ثم نحذف store_id
DO $$
BEGIN
  -- إضافة vertical_id إذا ما موجود
  IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'products' AND column_name = 'vertical_id') THEN
    ALTER TABLE products ADD COLUMN vertical_id uuid;
    
    -- نملأ vertical_id من store_id (عن طريق join مع stores)
    -- لكن إذا stores محذوف بالفعل، ما بنقدر نعمل join
    -- الحل: إذا فيه store_id، نجرب نملأه من stores
    -- إذا stores ما موجود، بنحط NULL (تاجر ما بنشأ متجر حالياً)
    IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'stores') THEN
      UPDATE products p SET vertical_id = s.vertical_id 
      FROM stores s WHERE p.store_id = s.id;
    END IF;
  END IF;
  
  -- حذف store_id
  IF EXISTS(SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'products' AND column_name = 'store_id') THEN
    ALTER TABLE products DROP COLUMN store_id;
  END IF;
END$$;

-- 3) إضافة/تأكد من الأعمدة الأخرى
ALTER TABLE products
  ADD COLUMN IF NOT EXISTS original_price numeric(12, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS selling_price numeric(12, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS image_url text,
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT NOW();

-- 4) بعد النقل، اجعل vertical_id NOT NULL (عمود مطلوب)
ALTER TABLE products
  ALTER COLUMN vertical_id SET NOT NULL;

-- 5) حذف View القديم (إذا موجود) وإنشاء الجديد
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

-- 6) تفعيل RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- 7) حذف السياسات القديمة
DROP POLICY IF EXISTS "platform_admin_all_products" ON products;

-- 8) Policy جديد
CREATE POLICY "platform_admin_all_products" ON products
  FOR ALL
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'platform_admin'
  );
