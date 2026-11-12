-- ============================================================================
-- Migration 002: Seller Authentication, Seller Profiles, Order Status History
-- ============================================================================
-- Additive migration: preserves all existing tables and data from 001.

-- 1. Add role column to profiles without altering existing rows' data
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'buyer'
  CHECK (role IN ('buyer', 'seller', 'both'));

-- Ensure existing store owners automatically have seller access
UPDATE public.profiles p
SET role = CASE WHEN p.role = 'buyer' THEN 'both' ELSE p.role END
WHERE EXISTS (SELECT 1 FROM public.stores s WHERE s.owner_id = p.id);

-- 2. Dedicated seller_profiles table
CREATE TABLE IF NOT EXISTS public.seller_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  email text,
  phone text,
  is_seller_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Seed seller_profiles for existing store owners if missing
INSERT INTO public.seller_profiles (user_id, full_name, email, phone)
SELECT p.id, p.full_name, p.email, p.phone
FROM public.profiles p
JOIN public.stores s ON s.owner_id = p.id
ON CONFLICT (user_id) DO NOTHING;

DROP TRIGGER IF EXISTS trg_seller_profiles_updated ON public.seller_profiles;
CREATE TRIGGER trg_seller_profiles_updated BEFORE UPDATE ON public.seller_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.seller_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "seller_profiles_select_own" ON public.seller_profiles;
CREATE POLICY "seller_profiles_select_own" ON public.seller_profiles
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "seller_profiles_insert_own" ON public.seller_profiles;
CREATE POLICY "seller_profiles_insert_own" ON public.seller_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "seller_profiles_update_own" ON public.seller_profiles;
CREATE POLICY "seller_profiles_update_own" ON public.seller_profiles
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. Update handle_new_user() to support seller registration metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role text;
  v_full_name text;
  v_phone text;
BEGIN
  v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'buyer');
  IF v_role NOT IN ('buyer', 'seller', 'both') THEN
    v_role := 'buyer';
  END IF;

  v_full_name := COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data->>'full_name'), ''),
    NULLIF(split_part(COALESCE(NEW.email, ''), '@', 1), ''),
    NEW.phone,
    'Pengguna WijiBumi'
  );
  v_phone := COALESCE(NULLIF(trim(NEW.raw_user_meta_data->>'phone'), ''), NEW.phone);

  INSERT INTO public.profiles (id, full_name, email, phone, role)
  VALUES (NEW.id, v_full_name, NEW.email, v_phone, v_role)
  ON CONFLICT (id) DO UPDATE
    SET full_name = COALESCE(NULLIF(EXCLUDED.full_name, ''), public.profiles.full_name),
        phone = COALESCE(EXCLUDED.phone, public.profiles.phone),
        role = CASE
          WHEN public.profiles.role = 'buyer' AND EXCLUDED.role = 'seller' THEN 'both'
          WHEN public.profiles.role = 'seller' AND EXCLUDED.role = 'buyer' THEN 'both'
          ELSE public.profiles.role
        END;

  IF v_role IN ('seller', 'both') THEN
    INSERT INTO public.seller_profiles (user_id, full_name, email, phone)
    VALUES (NEW.id, v_full_name, NEW.email, v_phone)
    ON CONFLICT (user_id) DO NOTHING;
  END IF;

  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- RPC to register/activate seller profile safely after signUp
CREATE OR REPLACE FUNCTION public.activate_seller_account(
  p_full_name text DEFAULT NULL,
  p_phone text DEFAULT NULL
)
RETURNS public.seller_profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_profile public.profiles%ROWTYPE;
  v_seller public.seller_profiles%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Autentikasi diperlukan';
  END IF;

  SELECT * INTO v_profile FROM public.profiles WHERE id = v_uid;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profil pengguna tidak ditemukan';
  END IF;

  UPDATE public.profiles
  SET role = CASE WHEN role = 'buyer' THEN 'both' ELSE role END,
      full_name = COALESCE(NULLIF(trim(p_full_name), ''), full_name),
      phone = COALESCE(NULLIF(trim(p_phone), ''), phone)
  WHERE id = v_uid
  RETURNING * INTO v_profile;

  INSERT INTO public.seller_profiles (user_id, full_name, email, phone, is_seller_active)
  VALUES (
    v_uid,
    v_profile.full_name,
    v_profile.email,
    v_profile.phone,
    true
  )
  ON CONFLICT (user_id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        phone = EXCLUDED.phone,
        is_seller_active = true
  RETURNING * INTO v_seller;

  RETURN v_seller;
END;
$$;

-- 4. Order Status History table for tracking all status changes
CREATE TABLE IF NOT EXISTS public.order_status_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  status text NOT NULL,
  actor_role text NOT NULL DEFAULT 'system' CHECK (actor_role IN ('buyer', 'seller', 'system')),
  changed_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "order_status_history_select_involved" ON public.order_status_history;
CREATE POLICY "order_status_history_select_involved" ON public.order_status_history
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      LEFT JOIN public.stores s ON s.id = o.store_id
      WHERE o.id = order_status_history.order_id
        AND (o.buyer_id = auth.uid() OR s.owner_id = auth.uid())
    )
  );

-- 5. Enforce customer-only confirmation for 'completed' status & log order_status_history
CREATE OR REPLACE FUNCTION public.update_order_status_secure(
  p_order_id uuid,
  p_new_status text,
  p_tracking_number text DEFAULT NULL,
  p_courier_name text DEFAULT NULL,
  p_note text DEFAULT NULL
)
RETURNS public.orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_order public.orders%ROWTYPE;
  v_store_owner uuid;
  v_shipment public.shipments%ROWTYPE;
  v_is_buyer boolean;
  v_is_seller boolean;
  v_actor_role text;
  v_ship_status text;
  v_desc text;
  v_item RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Autentikasi diperlukan';
  END IF;

  SELECT * INTO v_order FROM public.orders WHERE id = p_order_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pesanan tidak ditemukan';
  END IF;

  SELECT owner_id INTO v_store_owner FROM public.stores WHERE id = v_order.store_id;
  v_is_buyer := (v_order.buyer_id = v_user_id);
  v_is_seller := (v_store_owner = v_user_id);

  IF NOT (v_is_buyer OR v_is_seller) THEN
    RAISE EXCEPTION 'Anda tidak memiliki akses ke pesanan ini';
  END IF;

  v_actor_role := CASE WHEN v_is_seller THEN 'seller' ELSE 'buyer' END;

  -- Enforce strict valid transition matrix:
  -- - pending_payment -> awaiting_confirmation requires buyer/system payment validation (never seller directly)
  -- - shipped -> completed requires buyer confirmation (seller cannot force complete)
  IF p_new_status = 'awaiting_confirmation' AND v_order.status = 'pending_payment' AND v_is_buyer THEN
    UPDATE public.orders
    SET status = 'awaiting_confirmation', payment_status = 'paid'
    WHERE id = p_order_id RETURNING * INTO v_order;

    UPDATE public.payments SET status = 'paid', paid_at = now() WHERE order_id = p_order_id;
    v_desc := 'Pembayaran tervalidasi, menunggu konfirmasi penjual';
    v_ship_status := 'waiting';

    INSERT INTO public.notifications (user_id, type, title, body, reference_id)
    VALUES (v_store_owner, 'transaction', 'Pembayaran Diterima: ' || v_order.order_code,
      'Pembeli telah menyelesaikan pembayaran. Silakan konfirmasi pesanan.', p_order_id::text);

  ELSIF p_new_status = 'processing' AND v_order.status = 'awaiting_confirmation' AND v_is_seller THEN
    UPDATE public.orders
    SET status = 'processing'
    WHERE id = p_order_id RETURNING * INTO v_order;
    v_desc := COALESCE(p_note, 'Penjual mengonfirmasi dan sedang menyiapkan pesanan');
    v_ship_status := 'waiting';

    INSERT INTO public.notifications (user_id, type, title, body, reference_id)
    VALUES (v_order.buyer_id, 'order', 'Pesanan Diproses: ' || v_order.order_code, v_desc, p_order_id::text);

  ELSIF p_new_status = 'ready_to_ship' AND v_order.status = 'processing' AND v_is_seller THEN
    UPDATE public.orders SET status = 'ready_to_ship' WHERE id = p_order_id RETURNING * INTO v_order;
    v_desc := COALESCE(p_note, 'Paket telah dikemas dan siap dikirim oleh kurir');
    v_ship_status := 'picked_up';

    INSERT INTO public.notifications (user_id, type, title, body, reference_id)
    VALUES (v_order.buyer_id, 'shipment', 'Siap Dikirim: ' || v_order.order_code, v_desc, p_order_id::text);

  ELSIF p_new_status = 'shipped' AND v_order.status IN ('processing', 'ready_to_ship') AND v_is_seller THEN
    IF NULLIF(trim(COALESCE(p_tracking_number, '')), '') IS NULL THEN
      RAISE EXCEPTION 'Nomor resi pengiriman wajib diisi saat mengirim pesanan';
    END IF;
    UPDATE public.orders SET status = 'shipped' WHERE id = p_order_id RETURNING * INTO v_order;
    v_desc := COALESCE(p_note, 'Paket sedang dalam perjalanan (Resi: ' || trim(p_tracking_number) || ')');
    v_ship_status := 'in_transit';

    INSERT INTO public.notifications (user_id, type, title, body, reference_id)
    VALUES (v_order.buyer_id, 'shipment', 'Pesanan Dikirim: ' || v_order.order_code, v_desc, p_order_id::text);

  ELSIF p_new_status = 'completed' AND v_order.status = 'shipped' AND v_is_buyer THEN
    UPDATE public.orders SET status = 'completed', payment_status = 'paid'
    WHERE id = p_order_id RETURNING * INTO v_order;
    UPDATE public.payments SET status = 'paid', paid_at = COALESCE(paid_at, now()) WHERE order_id = p_order_id;
    v_desc := 'Pesanan dikonfirmasi diterima oleh customer. Transaksi selesai!';
    v_ship_status := 'delivered';

    INSERT INTO public.notifications (user_id, type, title, body, reference_id)
    VALUES (v_store_owner, 'transaction', 'Pesanan Selesai: ' || v_order.order_code,
      'Customer telah mengonfirmasi penerimaan pesanan.', p_order_id::text);

  ELSIF p_new_status = 'cancelled' AND v_order.status IN ('pending_payment', 'awaiting_confirmation', 'processing') THEN
    UPDATE public.orders SET status = 'cancelled' WHERE id = p_order_id RETURNING * INTO v_order;
    FOR v_item IN SELECT product_id, quantity FROM public.order_items WHERE order_id = p_order_id LOOP
      IF v_item.product_id IS NOT NULL THEN
        UPDATE public.products
        SET stock = stock + v_item.quantity,
            total_sales = GREATEST(0, total_sales - v_item.quantity)
        WHERE id = v_item.product_id;
      END IF;
    END LOOP;
    v_desc := COALESCE(p_note, 'Pesanan dibatalkan');
    v_ship_status := 'failed';

    INSERT INTO public.notifications (user_id, type, title, body, reference_id)
    VALUES (
      CASE WHEN v_is_seller THEN v_order.buyer_id ELSE v_store_owner END,
      'order',
      'Pesanan Dibatalkan: ' || v_order.order_code,
      v_desc,
      p_order_id::text
    );
  ELSE
    RAISE EXCEPTION 'Transisi status tidak valid atau tidak diizinkan dari "%" ke "%"', v_order.status, p_new_status;
  END IF;

  INSERT INTO public.order_status_history (order_id, status, actor_role, changed_by, note)
  VALUES (p_order_id, p_new_status, v_actor_role, v_user_id, v_desc);

  SELECT * INTO v_shipment FROM public.shipments WHERE order_id = p_order_id;
  IF FOUND THEN
    UPDATE public.shipments
    SET status = v_ship_status,
        tracking_number = COALESCE(NULLIF(trim(COALESCE(p_tracking_number, '')), ''), tracking_number),
        courier_name = COALESCE(NULLIF(trim(COALESCE(p_courier_name, '')), ''), courier_name),
        shipped_at = CASE WHEN p_new_status = 'shipped' THEN COALESCE(shipped_at, now()) ELSE shipped_at END,
        delivered_at = CASE WHEN p_new_status = 'completed' THEN now() ELSE delivered_at END,
        updated_at = now()
    WHERE id = v_shipment.id;

    INSERT INTO public.shipment_tracking (shipment_id, status, description, location)
    VALUES (v_shipment.id, v_ship_status, v_desc, CASE WHEN p_new_status = 'completed' THEN 'Alamat Pembeli' ELSE 'Proses Pengiriman' END);
  END IF;

  RETURN v_order;
END;
$$;

-- 6. Add chats table to Realtime publication so seller chat list auto-refreshes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'chats'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;
  END IF;
END $$;

