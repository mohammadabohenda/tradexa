-- ============================================================
-- TRADEXA — إحصائيات الأرباح والمبيعات
-- نفّذ هذا الملف كاملاً بـ Supabase SQL Editor
-- ============================================================

-- ------------------------------------------------------------
-- View: إحصائيات المبيعات والأرباح لكل منتج
--
-- نستثني الطلبات الملغية لأنها ما بتمثّل بيعًا فعليًا.
--
-- ملاحظة مهمة: الربح محسوب بسعر التكلفة الحالي
-- (products.original_price) مش تكلفة وقت البيع، لأن order_items
-- ما بتخزّن التكلفة. يعني تغيير سعر تكلفة منتج بيغيّر أرباح
-- الطلبات القديمة بأثر رجعي.
--
-- تحذير أمني: هذا الـ View بيعرض original_price (سرّ تجاري).
-- security_invoker بتخليه محكومًا بسياسة products، يعني الأدمن
-- فقط. لا تستعمله بموقع الزبائن إطلاقًا.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW product_sales_stats
WITH (security_invoker = true) AS
SELECT
  p.id                AS product_id,
  p.name              AS product_name,
  p.image_url,
  p.selling_price,
  p.original_price,
  COALESCE(SUM(oi.quantity), 0)                                      AS units_sold,
  COALESCE(SUM(oi.quantity * oi.unit_price), 0)                      AS revenue,
  COALESCE(SUM(oi.quantity * (oi.unit_price - p.original_price)), 0) AS profit,
  COUNT(DISTINCT o.id)                                               AS orders_count
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.id
LEFT JOIN orders o
       ON o.id = oi.order_id
      AND o.status <> 'cancelled'
GROUP BY p.id, p.name, p.image_url, p.selling_price, p.original_price;


-- ------------------------------------------------------------
-- Function: ملخّص الأرباح العام
--
-- نفرّق بين "محقّق" (تم التسليم فعليًا) و"متوقّع" (كل ما عدا
-- الملغي)، لأن طلب قيد الانتظار مش ربح بالجيب بعد.
--
-- SECURITY DEFINER مقصود: الدالة بتقرأ original_price لكنها
-- بترجع أرقامًا مجمّعة فقط، فما بتكشف تكلفة أي منتج مفرد.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_profit_summary()
RETURNS TABLE (
  realized_revenue numeric,
  realized_profit  numeric,
  expected_revenue numeric,
  expected_profit  numeric,
  orders_delivered bigint,
  orders_pending   bigint,
  units_sold       bigint
)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    COALESCE(SUM(oi.quantity * oi.unit_price)
             FILTER (WHERE o.status = 'delivered'), 0),
    COALESCE(SUM(oi.quantity * (oi.unit_price - p.original_price))
             FILTER (WHERE o.status = 'delivered'), 0),
    COALESCE(SUM(oi.quantity * oi.unit_price), 0),
    COALESCE(SUM(oi.quantity * (oi.unit_price - p.original_price)), 0),
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'delivered'),
    COUNT(DISTINCT o.id) FILTER (WHERE o.status <> 'delivered'),
    COALESCE(SUM(oi.quantity), 0)
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.id
  JOIN products p     ON p.id = oi.product_id
  WHERE o.status <> 'cancelled';
$$;

GRANT EXECUTE ON FUNCTION get_profit_summary() TO authenticated;


-- ------------------------------------------------------------
-- اختياري: تثبيت التكلفة وقت البيع (يحل مشكلة الأثر الرجعي)
--
-- بعد تنفيذ هدول، عدّل createManualOrder بالتطبيق ليبعت
-- cost_price كمان، وغيّر الحسابات فوق لتستعمل oi.cost_price
-- بدل p.original_price. الطلبات القديمة رح تضل بتكلفة NULL
-- فبتحسب بالسعر الحالي كما هو.
-- ------------------------------------------------------------
-- ALTER TABLE order_items ADD COLUMN IF NOT EXISTS cost_price numeric(12,2);
