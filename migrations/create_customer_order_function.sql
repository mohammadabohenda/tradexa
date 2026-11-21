-- ============================================================
-- TRADEXA — دالة إتمام طلب الزبون (معاملة ذرّية واحدة)
-- تُستدعى من صفحة /checkout بموقع الزبائن عبر supabase.rpc(...)
-- SECURITY DEFINER: تتخطى RLS عمدًا لقراءة الأسعار الحالية والتحقق
-- من is_active، لكنها تتحقق يدويًا من auth.uid() ومن حالة كل منتج
-- قبل أي إدراج، فما في ثغرة صلاحيات.
-- ============================================================

CREATE OR REPLACE FUNCTION create_customer_order(
  p_customer_name text,
  p_customer_phone text,
  p_customer_address text,
  p_notes text,
  p_items jsonb  -- [{ "product_id": "uuid", "quantity": 2 }, ...]
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_id uuid := auth.uid();
  v_order_id uuid;
  v_total numeric(12,2);
  v_unavailable_count integer;
BEGIN
  IF v_buyer_id IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'empty_cart';
  END IF;

  CREATE TEMPORARY TABLE tmp_cart_items ON COMMIT DROP AS
  SELECT
    (elem->>'product_id')::uuid AS product_id,
    (elem->>'quantity')::integer AS quantity
  FROM jsonb_array_elements(p_items) AS elem;

  IF EXISTS (SELECT 1 FROM tmp_cart_items WHERE quantity IS NULL OR quantity <= 0) THEN
    RAISE EXCEPTION 'invalid_quantity';
  END IF;

  -- كل منتج لازم يكون موجود وفعّال حاليًا
  SELECT count(*) INTO v_unavailable_count
  FROM tmp_cart_items t
  LEFT JOIN products p ON p.id = t.product_id AND p.is_active = true
  WHERE p.id IS NULL;

  IF v_unavailable_count > 0 THEN
    RAISE EXCEPTION 'product_unavailable';
  END IF;

  -- الإجمالي من الأسعار الحالية بقاعدة البيانات، مش من أي قيمة واصلة من المتصفح
  SELECT sum(p.selling_price * t.quantity) INTO v_total
  FROM tmp_cart_items t
  JOIN products p ON p.id = t.product_id;

  INSERT INTO orders (
    buyer_id, status, total_amount,
    customer_name, customer_phone, customer_address, notes, is_manual
  ) VALUES (
    v_buyer_id, 'pending', v_total,
    p_customer_name, p_customer_phone, p_customer_address, p_notes, false
  )
  RETURNING id INTO v_order_id;

  INSERT INTO order_items (order_id, product_id, quantity, unit_price)
  SELECT v_order_id, t.product_id, t.quantity, p.selling_price
  FROM tmp_cart_items t
  JOIN products p ON p.id = t.product_id;

  RETURN v_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION create_customer_order(text, text, text, text, jsonb) TO authenticated;
