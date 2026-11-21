-- ============================================================
-- TRADEXA — أصناف المنتجات (Categories)
--
-- كل قطاع إله أصنافه الخاصة، والمنتج ممكن ينتمي لأكتر من صنف.
-- ============================================================

-- ------------------------------------------------------------
-- 1) جدول الأصناف
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vertical_id uuid NOT NULL REFERENCES verticals(id) ON DELETE CASCADE,
  name        text NOT NULL,
  sort_order  integer NOT NULL DEFAULT 0,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT NOW(),

  -- ما ينفع صنفين بنفس الاسم داخل نفس القطاع، بس ينفع نفس
  -- الاسم بقطاعات مختلفة (مثلاً "إكسسوارات" بكل قطاع)
  CONSTRAINT categories_unique_per_vertical UNIQUE (vertical_id, name)
);

CREATE INDEX IF NOT EXISTS idx_categories_vertical
  ON categories(vertical_id) WHERE is_active;


-- ------------------------------------------------------------
-- 2) جدول الربط: منتج ← أصناف (متعدّد لمتعدّد)
--
-- المفتاح المركّب بيمنع تكرار نفس الصنف لنفس المنتج تلقائيًا،
-- فما بنحتاج فحص إضافي بالتطبيق.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product_categories (
  product_id  uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, category_id)
);

CREATE INDEX IF NOT EXISTS idx_product_categories_category
  ON product_categories(category_id);


-- ------------------------------------------------------------
-- 3) صلاحيات: الأدمن يدير، الزبون يقرأ أصناف قطاعه فقط
-- ------------------------------------------------------------
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_manage_categories" ON categories;
CREATE POLICY "admin_manage_categories" ON categories
  FOR ALL
  USING (current_user_role() = 'platform_admin')
  WITH CHECK (current_user_role() = 'platform_admin');

DROP POLICY IF EXISTS "buyers_read_own_vertical_categories" ON categories;
CREATE POLICY "buyers_read_own_vertical_categories" ON categories
  FOR SELECT TO authenticated
  USING (is_active = true AND vertical_id = current_user_vertical());

DROP POLICY IF EXISTS "admin_manage_product_categories" ON product_categories;
CREATE POLICY "admin_manage_product_categories" ON product_categories
  FOR ALL
  USING (current_user_role() = 'platform_admin')
  WITH CHECK (current_user_role() = 'platform_admin');

-- الزبون يقرأ روابط المنتجات اللي بيقدر يشوفها أصلاً
DROP POLICY IF EXISTS "buyers_read_product_categories" ON product_categories;
CREATE POLICY "buyers_read_product_categories" ON product_categories
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM products p
      WHERE p.id = product_id
        AND p.is_active = true
        AND p.vertical_id = current_user_vertical()
    )
  );


-- ------------------------------------------------------------
-- 4) دالة حفظ أصناف منتج (استبدال كامل)
--
-- بتحذف الروابط القديمة وبتضيف الجديدة بمعاملة وحدة، فما بيصير
-- المنتج بحالة نص محفوظة لو فشل شي بالنص.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_product_categories(
  p_product_id   uuid,
  p_category_ids uuid[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF current_user_role() <> 'platform_admin' THEN
    RAISE EXCEPTION 'هذا الإجراء متاح لمدير المنصة فقط';
  END IF;

  DELETE FROM product_categories WHERE product_id = p_product_id;

  IF p_category_ids IS NOT NULL AND array_length(p_category_ids, 1) > 0 THEN
    INSERT INTO product_categories (product_id, category_id)
    SELECT p_product_id, unnest(p_category_ids);
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION set_product_categories(uuid, uuid[]) TO authenticated;
