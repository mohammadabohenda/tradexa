-- ============================================================
-- TRADEXA — سياسات RLS لموقع الزبائن
-- تنفيذ إضافي فوق سياسات الأدمن القائمة — لا يحذف ولا يعدّل أي
-- سياسة موجودة لـ platform_admin. السياسات بـ Postgres تجميعية
-- (OR بين كل سياسات نفس الأمر)، فإضافة سياسة زبون هون ما بأثر
-- على وصول الأدمن إطلاقًا.
-- ============================================================

-- الزبون يقرأ المنتجات النشطة فقط
DROP POLICY IF EXISTS "buyers_read_active_products" ON products;
CREATE POLICY "buyers_read_active_products" ON products
  FOR SELECT TO authenticated
  USING (is_active = true);

-- الزبون يقرأ القطاعات النشطة
ALTER TABLE verticals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "buyers_read_active_verticals" ON verticals;
CREATE POLICY "buyers_read_active_verticals" ON verticals
  FOR SELECT TO authenticated
  USING (is_active = true);

-- الزبون ينشئ طلبات لنفسه فقط
DROP POLICY IF EXISTS "buyers_create_own_orders" ON orders;
CREATE POLICY "buyers_create_own_orders" ON orders
  FOR INSERT TO authenticated
  WITH CHECK (buyer_id = auth.uid());

-- الزبون يقرأ طلباته هو فقط
DROP POLICY IF EXISTS "buyers_read_own_orders" ON orders;
CREATE POLICY "buyers_read_own_orders" ON orders
  FOR SELECT TO authenticated
  USING (buyer_id = auth.uid());

-- الزبون ينشئ ويقرأ أسطر طلباته فقط
DROP POLICY IF EXISTS "buyers_manage_own_order_items" ON order_items;
CREATE POLICY "buyers_manage_own_order_items" ON order_items
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM orders o WHERE o.id = order_id AND o.buyer_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM orders o WHERE o.id = order_id AND o.buyer_id = auth.uid())
  );
