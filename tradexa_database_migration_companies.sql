-- ============================================================
-- TREDEXA — Migration: Companies (ترقية stores إلى Tenant كامل)
-- نفّذ هذا بعد سكربت قاعدة البيانات الأساسي
-- ============================================================

-- 1) أعمدة جديدة على stores (الشركة)
ALTER TABLE stores
  ADD COLUMN IF NOT EXISTS logo_url text,
  ADD COLUMN IF NOT EXISTS country text,
  ADD COLUMN IF NOT EXISTS subscription_plan text NOT NULL DEFAULT 'starter'
    CHECK (subscription_plan IN ('starter', 'business', 'enterprise')),
  ADD COLUMN IF NOT EXISTS billing_cycle text NOT NULL DEFAULT 'monthly'
    CHECK (billing_cycle IN ('monthly', 'yearly')),
  ADD COLUMN IF NOT EXISTS subscription_expires_at timestamptz;

-- 2) View لحساب إحصائيات كل شركة (عدد منتجات، طلبات، عملاء مميزين،
-- آخر نشاط) على مستوى قاعدة البيانات — أسرع وأدق بكثير من حسابها
-- بالتطبيق، وبيتحدث تلقائيًا مع أي بيانات جديدة بدون أي كود إضافي.
--
-- security_invoker = true يعني: الـ View بتحترم RLS الجداول الأصلية
-- (products, orders) — يعني لو تاجر استعلم عنها (مستقبلًا)، ما رح
-- يشوف إلا إحصائيات متجره هو فقط، تلقائيًا وبدون أي كود إضافي.
CREATE OR REPLACE VIEW store_stats
WITH (security_invoker = true) AS
SELECT
  s.id AS store_id,
  COUNT(DISTINCT p.id) AS products_count,
  COUNT(DISTINCT o.id) AS orders_count,
  COUNT(DISTINCT o.buyer_id) AS customers_count,
  MAX(o.created_at) AS last_order_at
FROM stores s
LEFT JOIN products p ON p.store_id = s.id
LEFT JOIN orders o ON o.store_id = s.id
GROUP BY s.id;

-- ملاحظة: الـ View نفسه ما بيحتاج RLS منفصل لأنه security_invoker
-- بيخليه يعتمد على صلاحيات المستخدم الفعلي وقت الاستعلام.
