-- Migration 011: Fix payments_status_check constraint to allow 'unpaid' and ensure safe status in checkout functions

-- 1. Alter table payments check constraint to allow 'unpaid'
ALTER TABLE public.payments DROP CONSTRAINT IF EXISTS payments_status_check;
ALTER TABLE public.payments ADD CONSTRAINT payments_status_check 
  CHECK (status IN ('unpaid', 'pending', 'paid', 'failed', 'expired', 'refunded'));

-- 2. Update create_checkout_orders to safely handle payments status
CREATE OR REPLACE FUNCTION public.create_checkout_orders(
  p_address_id uuid,
  p_payment_method text,
  p_courier_name text,
  p_buyer_note text DEFAULT NULL
)
RETURNS SETOF public.orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_address public.addresses%ROWTYPE;
  v_store_rec RECORD;
  v_item_rec RECORD;
  v_order_id uuid;
  v_order_code text;
  v_subtotal numeric(12,2);
  v_shipping_fee numeric(12,2);
  v_service_name text;
  v_total numeric(12,2);
  v_initial_status text;
  v_payment_status text;
  v_shipment_id uuid;
  v_seq integer := 0;
  v_created_order public.orders%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Autentikasi diperlukan untuk melakukan checkout';
  END IF;

  SELECT * INTO v_address FROM public.addresses
  WHERE id = p_address_id AND user_id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Alamat pengiriman tidak valid atau bukan milik Anda';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.cart_items WHERE user_id = v_user_id) THEN
    RAISE EXCEPTION 'Keranjang belanja kosong';
  END IF;

  v_shipping_fee := public.compute_courier_shipping_fee(p_courier_name);
  v_service_name := public.get_courier_service_name(p_courier_name);

  IF p_payment_method = 'COD (Bayar di Tempat)' THEN
    v_initial_status := 'awaiting_confirmation';
    v_payment_status := 'pending';
  ELSE
    v_initial_status := 'pending_payment';
    v_payment_status := 'pending';
  END IF;

  FOR v_store_rec IN
    SELECT DISTINCT p.store_id, s.store_name, s.owner_id, s.city,
                    s.verification_status::text AS verification_status, s.is_active
    FROM public.cart_items c
    JOIN public.products p ON p.id = c.product_id
    JOIN public.stores s ON s.id = p.store_id
    WHERE c.user_id = v_user_id
  LOOP
    IF v_store_rec.verification_status <> 'approved' OR v_store_rec.is_active = false THEN
      RAISE EXCEPTION 'Toko "%" belum terverifikasi atau sedang nonaktif untuk melakukan penjualan', v_store_rec.store_name;
    END IF;

    v_seq := v_seq + 1;
    v_subtotal := 0;
    v_order_id := gen_random_uuid();
    v_order_code := 'WIJI-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(replace(v_order_id::text, '-', ''), 1, 6));

    FOR v_item_rec IN
      SELECT c.quantity, p.id AS product_id, p.name, p.unit, p.price, p.stock, p.quality_grade, p.status,
             (SELECT pi.storage_path FROM public.product_images pi WHERE pi.product_id = p.id ORDER BY pi.is_primary DESC, pi.sort_order ASC LIMIT 1) AS primary_image
      FROM public.cart_items c
      JOIN public.products p ON p.id = c.product_id
      WHERE c.user_id = v_user_id AND p.store_id = v_store_rec.store_id
      FOR UPDATE OF p
    LOOP
      IF v_item_rec.status <> 'active' THEN
        RAISE EXCEPTION 'Produk "%" sedang tidak aktif', v_item_rec.name;
      END IF;
      IF v_item_rec.stock < v_item_rec.quantity THEN
        RAISE EXCEPTION 'Stok produk "%" tidak mencukupi (tersisa %)', v_item_rec.name, v_item_rec.stock;
      END IF;
      v_subtotal := v_subtotal + (v_item_rec.price * v_item_rec.quantity);
    END LOOP;

    v_total := v_subtotal + v_shipping_fee;

    INSERT INTO public.orders (
      id, order_code, buyer_id, store_id, address_id,
      shipping_address_snapshot, status, payment_status,
      subtotal, shipping_fee, discount_total, total_amount, buyer_note
    ) VALUES (
      v_order_id, v_order_code, v_user_id, v_store_rec.store_id, v_address.id,
      jsonb_build_object(
        'recipient_name', v_address.recipient_name,
        'phone', v_address.phone,
        'address', concat_ws(', ',
          v_address.address,
          NULLIF(v_address.kelurahan, ''),
          NULLIF(v_address.district, ''),
          NULLIF(v_address.city, ''),
          NULLIF(v_address.province, ''),
          NULLIF(v_address.postal_code, '')
        )
      ),
      v_initial_status, v_payment_status,
      v_subtotal, v_shipping_fee, 0, v_total, p_buyer_note
    )
    RETURNING * INTO v_created_order;

    FOR v_item_rec IN
      SELECT c.quantity, p.id AS product_id, p.name, p.unit, p.price, p.quality_grade,
             (SELECT pi.storage_path FROM public.product_images pi WHERE pi.product_id = p.id ORDER BY pi.is_primary DESC, pi.sort_order ASC LIMIT 1) AS primary_image
      FROM public.cart_items c
      JOIN public.products p ON p.id = c.product_id
      WHERE c.user_id = v_user_id AND p.store_id = v_store_rec.store_id
    LOOP
      INSERT INTO public.order_items (
        order_id, product_id, product_name_snapshot, unit_snapshot,
        unit_price, quantity, line_total, quality_grade_snapshot, image_snapshot
      ) VALUES (
        v_order_id, v_item_rec.product_id, v_item_rec.name, v_item_rec.unit,
        v_item_rec.price, v_item_rec.quantity, (v_item_rec.price * v_item_rec.quantity),
        v_item_rec.quality_grade, v_item_rec.primary_image
      );

      UPDATE public.products
      SET stock = stock - v_item_rec.quantity,
          total_sales = total_sales + v_item_rec.quantity
      WHERE id = v_item_rec.product_id;
    END LOOP;

    INSERT INTO public.payments (order_id, payment_method, amount, status)
    VALUES (v_order_id, p_payment_method, v_total, 'pending');

    v_shipment_id := gen_random_uuid();
    INSERT INTO public.shipments (id, order_id, courier_name, service_name, status, estimated_arrival)
    VALUES (
      v_shipment_id,
      v_order_id,
      p_courier_name,
      v_service_name,
      'pending',
      now() + interval '3 days'
    );

    INSERT INTO public.shipment_tracking (shipment_id, status, description, location)
    VALUES (
      v_shipment_id,
      'pending',
      'Pesanan dibuat. Menunggu konfirmasi toko dan persiapan paket.',
      coalesce(v_store_rec.city, 'Gudang Penjual')
    );

    INSERT INTO public.notifications (user_id, title, body, type, reference_id)
    VALUES (
      v_store_rec.owner_id,
      'Pesanan Baru Diterima',
      'Pesanan ' || v_order_code || ' telah dibuat oleh pembeli dan menunggu proses.',
      'order',
      v_order_id
    );

    RETURN NEXT v_created_order;
  END LOOP;

  DELETE FROM public.cart_items WHERE user_id = v_user_id;
  RETURN;
END;
$$;

-- 3. Update create_direct_order to safely handle payments status
CREATE OR REPLACE FUNCTION public.create_direct_order(
  p_product_id uuid,
  p_quantity integer,
  p_address_id uuid,
  p_payment_method text,
  p_courier_name text,
  p_buyer_note text DEFAULT NULL
)
RETURNS public.orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_address public.addresses%ROWTYPE;
  v_product RECORD;
  v_order_id uuid;
  v_order_code text;
  v_subtotal numeric(12,2);
  v_shipping_fee numeric(12,2);
  v_service_name text;
  v_total numeric(12,2);
  v_initial_status text;
  v_payment_status text;
  v_shipment_id uuid;
  v_created_order public.orders%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Autentikasi diperlukan untuk melakukan checkout';
  END IF;

  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Jumlah pembelian minimal 1';
  END IF;

  SELECT * INTO v_address FROM public.addresses
  WHERE id = p_address_id AND user_id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Alamat pengiriman tidak valid atau bukan milik Anda';
  END IF;

  SELECT p.*, s.store_name, s.owner_id, s.city,
         s.verification_status::text AS verification_status, s.is_active,
         (SELECT pi.storage_path FROM public.product_images pi WHERE pi.product_id = p.id ORDER BY pi.is_primary DESC, pi.sort_order ASC LIMIT 1) AS primary_image
  INTO v_product
  FROM public.products p
  JOIN public.stores s ON s.id = p.store_id
  WHERE p.id = p_product_id
  FOR UPDATE OF p;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Produk tidak ditemukan';
  END IF;

  IF v_product.verification_status <> 'approved' OR v_product.is_active = false THEN
    RAISE EXCEPTION 'Toko "%" belum terverifikasi atau sedang nonaktif untuk melakukan penjualan', v_product.store_name;
  END IF;

  IF v_product.status <> 'active' THEN
    RAISE EXCEPTION 'Produk "%" sedang tidak aktif', v_product.name;
  END IF;

  IF v_product.stock < p_quantity THEN
    RAISE EXCEPTION 'Stok produk "%" tidak mencukupi (tersisa %)', v_product.name, v_product.stock;
  END IF;

  v_shipping_fee := public.compute_courier_shipping_fee(p_courier_name);
  v_service_name := public.get_courier_service_name(p_courier_name);

  IF p_payment_method = 'COD (Bayar di Tempat)' THEN
    v_initial_status := 'awaiting_confirmation';
    v_payment_status := 'pending';
  ELSE
    v_initial_status := 'pending_payment';
    v_payment_status := 'pending';
  END IF;

  v_subtotal := v_product.price * p_quantity;
  v_total := v_subtotal + v_shipping_fee;
  v_order_id := gen_random_uuid();
  v_order_code := 'WIJI-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(replace(v_order_id::text, '-', ''), 1, 6));

  INSERT INTO public.orders (
    id, order_code, buyer_id, store_id, address_id,
    shipping_address_snapshot, status, payment_status,
    subtotal, shipping_fee, discount_total, total_amount, buyer_note
  ) VALUES (
    v_order_id, v_order_code, v_user_id, v_product.store_id, v_address.id,
    jsonb_build_object(
      'recipient_name', v_address.recipient_name,
      'phone', v_address.phone,
      'address', concat_ws(', ',
        v_address.address,
        NULLIF(v_address.kelurahan, ''),
        NULLIF(v_address.district, ''),
        NULLIF(v_address.city, ''),
        NULLIF(v_address.province, ''),
        NULLIF(v_address.postal_code, '')
      )
    ),
    v_initial_status, v_payment_status,
    v_subtotal, v_shipping_fee, 0, v_total, p_buyer_note
  )
  RETURNING * INTO v_created_order;

  INSERT INTO public.order_items (
    order_id, product_id, product_name_snapshot, unit_snapshot,
    unit_price, quantity, line_total, quality_grade_snapshot, image_snapshot
  ) VALUES (
    v_order_id, v_product.id, v_product.name, v_product.unit,
    v_product.price, p_quantity, v_subtotal,
    v_product.quality_grade, v_product.primary_image
  );

  UPDATE public.products
  SET stock = stock - p_quantity,
      total_sales = total_sales + p_quantity
  WHERE id = v_product.id;

  INSERT INTO public.payments (order_id, payment_method, amount, status)
  VALUES (v_order_id, p_payment_method, v_total, 'pending');

  v_shipment_id := gen_random_uuid();
  INSERT INTO public.shipments (id, order_id, courier_name, service_name, status, estimated_arrival)
  VALUES (
    v_shipment_id,
    v_order_id,
    p_courier_name,
    v_service_name,
    'pending',
    now() + interval '3 days'
  );

  INSERT INTO public.shipment_tracking (shipment_id, status, description, location)
  VALUES (
    v_shipment_id,
    'pending',
    'Pesanan dibuat. Menunggu konfirmasi toko dan persiapan paket.',
    coalesce(v_product.city, 'Gudang Penjual')
  );

  INSERT INTO public.notifications (user_id, title, body, type, reference_id)
  VALUES (
    v_product.owner_id,
    'Pesanan Langsung Baru',
    'Pesanan ' || v_order_code || ' telah dibuat oleh pembeli untuk produk ' || v_product.name || '.',
    'order',
    v_order_id
  );

  RETURN v_created_order;
END;
$$;
