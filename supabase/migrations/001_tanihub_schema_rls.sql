-- ============================================================================
-- WijiBumi (ex-TaniHub) Supabase Schema, RLS, Storage, Triggers & RPC Functions
-- ============================================================================
-- Run this script in Supabase SQL Editor (or via Supabase CLI migration).
-- Idempotent where practical so it can be reviewed and applied cleanly.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- 1. CORE TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL DEFAULT '',
  email text,
  phone text,
  avatar_path text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.addresses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  label text NOT NULL DEFAULT 'Rumah',
  recipient_name text NOT NULL,
  phone text NOT NULL,
  address text NOT NULL,
  province text,
  city text,
  district text,
  kelurahan text,
  postal_code text,
  note text,
  latitude double precision,
  longitude double precision,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.stores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  store_name text NOT NULL,
  slug text NOT NULL UNIQUE,
  description text,
  logo_path text,
  cover_path text,
  email text,
  phone text NOT NULL,
  address text NOT NULL,
  province text NOT NULL,
  city text NOT NULL,
  district text,
  postal_code text,
  latitude double precision,
  longitude double precision,
  operating_hours text DEFAULT '06:00 - 17:00 WIB',
  verification_status text NOT NULL DEFAULT 'pending'
    CHECK (verification_status IN ('pending', 'approved', 'rejected', 'suspended')),
  verification_note text,
  is_active boolean NOT NULL DEFAULT false,
  rating numeric(3,2) NOT NULL DEFAULT 5.00,
  total_reviews integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  slug text NOT NULL UNIQUE,
  description text,
  icon text
);

-- Seed strictly the 3 allowed categories
INSERT INTO public.categories (name, slug, description, icon) VALUES
  ('Bunga', 'bunga', 'Aneka bunga potong, hias, dan tanaman bunga berkualitas tinggi', 'local_florist'),
  ('Sayuran', 'sayuran', 'Sayuran segar panen langsung dari kebun petani mitra', 'eco'),
  ('Buah-buahan', 'buah-buahan', 'Buah-buahan tropis manis dan segar petik matang pohon', 'apple')
ON CONFLICT (slug) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES public.categories(id),
  name text NOT NULL,
  description text,
  price numeric(12,2) NOT NULL CHECK (price > 0),
  unit text NOT NULL DEFAULT 'kg',
  stock integer NOT NULL DEFAULT 0 CHECK (stock >= 0),
  quality_grade text CHECK (quality_grade IN ('A', 'B', 'C')),
  harvest_date date,
  shelf_life_days integer CHECK (shelf_life_days IS NULL OR shelf_life_days > 0),
  farm_location text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('draft', 'active', 'inactive')),
  rating numeric(3,2) NOT NULL DEFAULT 5.00,
  total_sales integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.product_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  is_primary boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  quantity integer NOT NULL CHECK (quantity > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, product_id)
);

CREATE TABLE IF NOT EXISTS public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_code text NOT NULL UNIQUE,
  buyer_id uuid NOT NULL REFERENCES public.profiles(id),
  store_id uuid NOT NULL REFERENCES public.stores(id),
  address_id uuid REFERENCES public.addresses(id) ON DELETE SET NULL,
  shipping_address_snapshot jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pending_payment' CHECK (status IN (
    'pending_payment', 'awaiting_confirmation', 'processing',
    'ready_to_ship', 'shipped', 'completed', 'cancelled'
  )),
  payment_status text NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN (
    'unpaid', 'pending', 'paid', 'failed', 'refunded'
  )),
  subtotal numeric(12,2) NOT NULL CHECK (subtotal >= 0),
  shipping_fee numeric(12,2) NOT NULL DEFAULT 0 CHECK (shipping_fee >= 0),
  discount_total numeric(12,2) NOT NULL DEFAULT 0 CHECK (discount_total >= 0),
  total_amount numeric(12,2) NOT NULL CHECK (total_amount >= 0),
  buyer_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  product_name_snapshot text NOT NULL,
  unit_snapshot text NOT NULL,
  unit_price numeric(12,2) NOT NULL CHECK (unit_price >= 0),
  quantity integer NOT NULL CHECK (quantity > 0),
  line_total numeric(12,2) NOT NULL CHECK (line_total >= 0),
  quality_grade_snapshot text,
  image_snapshot text
);

CREATE TABLE IF NOT EXISTS public.payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  payment_method text NOT NULL,
  provider text,
  provider_reference text,
  amount numeric(12,2) NOT NULL CHECK (amount >= 0),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'paid', 'failed', 'expired', 'refunded'
  )),
  payment_url text,
  paid_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.shipments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL UNIQUE REFERENCES public.orders(id) ON DELETE CASCADE,
  courier_name text,
  service_name text,
  tracking_number text,
  status text NOT NULL DEFAULT 'waiting' CHECK (status IN (
    'waiting', 'picked_up', 'in_transit', 'delivered', 'returned', 'failed'
  )),
  estimated_arrival timestamptz,
  shipped_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.shipment_tracking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shipment_id uuid NOT NULL REFERENCES public.shipments(id) ON DELETE CASCADE,
  status text NOT NULL,
  description text,
  location text,
  event_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.chats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  store_id uuid NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  last_message_at timestamptz,
  last_message_body text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (buyer_id, store_id)
);

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id uuid NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message_type text NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image')),
  body text,
  media_path text,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  reviewer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  store_id uuid NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review_text text,
  reply_text text,
  replied_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.promotions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  title text NOT NULL,
  code text,
  promotion_type text NOT NULL DEFAULT 'percentage' CHECK (promotion_type IN ('percentage', 'fixed_amount', 'flash_sale')),
  value numeric(12,2) NOT NULL CHECK (value > 0),
  minimum_purchase numeric(12,2) NOT NULL DEFAULT 0,
  maximum_discount numeric(12,2),
  starts_at timestamptz NOT NULL DEFAULT now(),
  ends_at timestamptz NOT NULL,
  quota integer,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.payout_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  method text NOT NULL DEFAULT 'bank_transfer' CHECK (method IN ('bank_transfer', 'e_wallet')),
  provider_name text NOT NULL,
  account_holder text NOT NULL,
  account_number_last4 text NOT NULL,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.payout_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  payout_account_id uuid NOT NULL REFERENCES public.payout_accounts(id),
  amount numeric(12,2) NOT NULL CHECK (amount > 0),
  status text NOT NULL DEFAULT 'requested' CHECK (status IN ('requested', 'processing', 'paid', 'rejected')),
  reference_number text,
  note text,
  requested_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('transaction', 'order', 'shipment', 'chat', 'system')),
  title text NOT NULL,
  body text NOT NULL,
  reference_id text,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category text NOT NULL,
  subject text NOT NULL,
  message text NOT NULL,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  order_notifications boolean NOT NULL DEFAULT true,
  promo_notifications boolean NOT NULL DEFAULT true,
  chat_notifications boolean NOT NULL DEFAULT true,
  email_updates boolean NOT NULL DEFAULT true,
  language_code text NOT NULL DEFAULT 'id' CHECK (language_code IN ('id', 'en')),
  show_online_status boolean NOT NULL DEFAULT true,
  allow_analytics boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
-- 2. SECURITY TRIGGERS & HELPER FUNCTIONS
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_profiles_updated ON public.profiles;
CREATE TRIGGER trg_profiles_updated BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_addresses_updated ON public.addresses;
CREATE TRIGGER trg_addresses_updated BEFORE UPDATE ON public.addresses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_stores_updated ON public.stores;
CREATE TRIGGER trg_stores_updated BEFORE UPDATE ON public.stores
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_products_updated ON public.products;
CREATE TRIGGER trg_products_updated BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Auto-create profile when user signs up via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, phone)
  VALUES (
    NEW.id,
    COALESCE(
      NULLIF(trim(NEW.raw_user_meta_data->>'full_name'), ''),
      NULLIF(split_part(COALESCE(NEW.email, ''), '@', 1), ''),
      NEW.phone,
      'Pengguna WijiBumi'
    ),
    NEW.email,
    COALESCE(NULLIF(trim(NEW.raw_user_meta_data->>'phone'), ''), NEW.phone)
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Prevent frontend users (anon/authenticated) from self-approving stores
-- while still allowing Supabase Dashboard SQL Editor (postgres) & service_role
CREATE OR REPLACE FUNCTION public.protect_store_verification()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF current_user IN ('anon', 'authenticated') OR COALESCE(auth.role(), '') IN ('anon', 'authenticated') THEN
    IF TG_OP = 'INSERT' THEN
      NEW.verification_status := 'pending';
      NEW.is_active := false;
      NEW.verification_note := 'Menunggu verifikasi tim WijiBumi.';
    ELSIF TG_OP = 'UPDATE' THEN
      NEW.verification_status := OLD.verification_status;
      NEW.verification_note := OLD.verification_note;
      NEW.is_active := OLD.is_active;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- Prevent frontend users from forging payout request status
CREATE OR REPLACE FUNCTION public.protect_payout_request_status()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF current_user IN ('anon', 'authenticated') OR COALESCE(auth.role(), '') IN ('anon', 'authenticated') THEN
    IF TG_OP = 'INSERT' THEN
      NEW.status := 'requested';
      NEW.processed_at := NULL;
    ELSIF TG_OP = 'UPDATE' THEN
      NEW.status := OLD.status;
      NEW.amount := OLD.amount;
      NEW.processed_at := OLD.processed_at;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_payout_request ON public.payout_requests;
CREATE TRIGGER trg_protect_payout_request
  BEFORE INSERT OR UPDATE ON public.payout_requests
  FOR EACH ROW EXECUTE FUNCTION public.protect_payout_request_status();

DROP TRIGGER IF EXISTS trg_protect_store_verification ON public.stores;
CREATE TRIGGER trg_protect_store_verification
  BEFORE INSERT OR UPDATE ON public.stores
  FOR EACH ROW EXECUTE FUNCTION public.protect_store_verification();

-- Prevent unverified stores from activating products for sale
CREATE OR REPLACE FUNCTION public.enforce_verified_store_for_product()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_approved boolean;
BEGIN
  IF NEW.status = 'active' THEN
    SELECT (verification_status = 'approved' AND is_active = true)
    INTO v_approved
    FROM public.stores
    WHERE id = NEW.store_id;

    IF NOT COALESCE(v_approved, false) THEN
      RAISE EXCEPTION 'Toko belum terverifikasi. Tidak dapat mengaktifkan produk untuk penjualan.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_verified_store_product ON public.products;
CREATE TRIGGER trg_enforce_verified_store_product
  BEFORE INSERT OR UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.enforce_verified_store_for_product();

-- Keep chat last_message_at/body updated & notify recipient on new message
CREATE OR REPLACE FUNCTION public.on_chat_message_inserted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chat public.chats%ROWTYPE;
  v_owner_id uuid;
  v_recipient_id uuid;
  v_sender_name text;
BEGIN
  SELECT * INTO v_chat FROM public.chats WHERE id = NEW.chat_id;
  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  UPDATE public.chats
  SET last_message_at = NEW.created_at,
      last_message_body = COALESCE(NEW.body, '[Gambar]')
  WHERE id = NEW.chat_id;

  SELECT owner_id INTO v_owner_id FROM public.stores WHERE id = v_chat.store_id;
  SELECT full_name INTO v_sender_name FROM public.profiles WHERE id = NEW.sender_id;

  IF NEW.sender_id = v_chat.buyer_id THEN
    v_recipient_id := v_owner_id;
  ELSE
    v_recipient_id := v_chat.buyer_id;
  END IF;

  IF v_recipient_id IS NOT NULL AND v_recipient_id <> NEW.sender_id THEN
    INSERT INTO public.notifications (user_id, type, title, body, reference_id)
    VALUES (
      v_recipient_id,
      'chat',
      'Pesan baru dari ' || COALESCE(v_sender_name, 'Pengguna WijiBumi'),
      LEFT(COALESCE(NEW.body, 'Mengirim lampiran gambar'), 120),
      NEW.chat_id::text
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_chat_message_inserted ON public.chat_messages;
CREATE TRIGGER trg_chat_message_inserted
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION public.on_chat_message_inserted();

-- ============================================================================
-- 3. SECURE DATABASE FUNCTIONS (RPC) FOR SENSITIVE OPERATIONS
-- ============================================================================

-- Atomic server-side checkout (prevents price manipulation & race conditions)
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
  v_shipping_fee numeric(12,2) := 15000.00;
  v_total numeric(12,2);
  v_initial_status text;
  v_payment_status text;
  v_shipment_id uuid;
  v_store_owner uuid;
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

  IF p_payment_method = 'COD (Bayar di Tempat)' THEN
    v_initial_status := 'awaiting_confirmation';
    v_payment_status := 'pending';
  ELSE
    v_initial_status := 'pending_payment';
    v_payment_status := 'unpaid';
  END IF;

  FOR v_store_rec IN
    SELECT DISTINCT p.store_id, s.store_name, s.owner_id, s.city,
                    s.verification_status, s.is_active
    FROM public.cart_items c
    JOIN public.products p ON p.id = c.product_id
    JOIN public.stores s ON s.id = p.store_id
    WHERE c.user_id = v_user_id
  LOOP
    IF v_store_rec.verification_status <> 'approved' OR v_store_rec.is_active = false THEN
      RAISE EXCEPTION 'Toko "%" belum terverifikasi untuk melakukan penjualan', v_store_rec.store_name;
    END IF;

    v_seq := v_seq + 1;
    v_subtotal := 0;
    v_order_id := gen_random_uuid();
    v_order_code := 'WIJI-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(replace(v_order_id::text, '-', ''), 1, 6));

    -- Validate stock and calculate authoritative subtotal
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

    -- Insert order items & deduct stock
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
    VALUES (v_order_id, p_payment_method, v_total, v_payment_status);

    v_shipment_id := gen_random_uuid();
    INSERT INTO public.shipments (id, order_id, courier_name, service_name, status, estimated_arrival)
    VALUES (v_shipment_id, v_order_id, p_courier_name, 'Reguler Fresh Cargo', 'waiting', now() + interval '2 days');

    INSERT INTO public.shipment_tracking (shipment_id, status, description, location)
    VALUES (
      v_shipment_id,
      'waiting',
      'Pesanan berhasil dibuat, menunggu proses konfirmasi',
      COALESCE(v_store_rec.city, 'Kebun Petani')
    );

    -- Notify seller & buyer
    INSERT INTO public.notifications (user_id, type, title, body, reference_id)
    VALUES (
      v_store_rec.owner_id,
      'order',
      'Pesanan Baru Masuk: ' || v_order_code,
      'Ada pesanan baru senilai Rp ' || to_char(v_total, 'FM999G999G999') || '.',
      v_order_id::text
    );

    INSERT INTO public.notifications (user_id, type, title, body, reference_id)
    VALUES (
      v_user_id,
      'transaction',
      'Pesanan ' || v_order_code || ' Dibuat',
      'Pesanan Anda ke ' || v_store_rec.store_name || ' berhasil dibuat.',
      v_order_id::text
    );

    RETURN NEXT v_created_order;
  END LOOP;

  DELETE FROM public.cart_items WHERE user_id = v_user_id;
  RETURN;
END;
$$;

-- Secure order status transitions with role authorization
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

  -- Enforce valid transition matrix
  IF p_new_status = 'awaiting_confirmation' AND v_order.status = 'pending_payment' AND v_is_buyer THEN
    UPDATE public.orders
    SET status = 'awaiting_confirmation', payment_status = 'paid'
    WHERE id = p_order_id RETURNING * INTO v_order;

    UPDATE public.payments SET status = 'paid', paid_at = now() WHERE order_id = p_order_id;
    v_desc := 'Pembayaran diterima, menunggu konfirmasi penjual';
    v_ship_status := 'waiting';

    INSERT INTO public.notifications (user_id, type, title, body, reference_id)
    VALUES (v_store_owner, 'transaction', 'Pembayaran Diterima: ' || v_order.order_code,
      'Pembeli telah membayar pesanan. Silakan konfirmasi pesanan.', p_order_id::text);

  ELSIF p_new_status = 'processing' AND v_order.status IN ('pending_payment', 'awaiting_confirmation') AND v_is_seller THEN
    UPDATE public.orders
    SET status = 'processing',
        payment_status = CASE WHEN payment_status = 'unpaid' THEN 'paid' ELSE payment_status END
    WHERE id = p_order_id RETURNING * INTO v_order;
    v_desc := COALESCE(p_note, 'Penjual sedang menyiapkan dan mengemas produk hasil panen');
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

  ELSIF p_new_status = 'completed' AND v_order.status = 'shipped' AND (v_is_buyer OR v_is_seller) THEN
    UPDATE public.orders SET status = 'completed', payment_status = 'paid'
    WHERE id = p_order_id RETURNING * INTO v_order;
    UPDATE public.payments SET status = 'paid', paid_at = COALESCE(paid_at, now()) WHERE order_id = p_order_id;
    v_desc := 'Pesanan telah diterima pembeli. Transaksi selesai!';
    v_ship_status := 'delivered';

    INSERT INTO public.notifications (user_id, type, title, body, reference_id)
    VALUES (v_store_owner, 'transaction', 'Pesanan Selesai: ' || v_order.order_code,
      'Dana pesanan telah masuk ke ringkasan pendapatan toko.', p_order_id::text);

  ELSIF p_new_status = 'cancelled' AND v_order.status IN ('pending_payment', 'awaiting_confirmation', 'processing') THEN
    UPDATE public.orders SET status = 'cancelled' WHERE id = p_order_id RETURNING * INTO v_order;
    -- Restore product stock
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
    RAISE EXCEPTION 'Transisi status tidak valid dari "%" ke "%"', v_order.status, p_new_status;
  END IF;

  -- Update shipment & insert tracking event
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

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipment_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- Profiles
DROP POLICY IF EXISTS "profiles_select_authenticated" ON public.profiles;
CREATE POLICY "profiles_select_authenticated" ON public.profiles
  FOR SELECT USING (auth.uid() = id OR EXISTS (
    SELECT 1 FROM public.reviews r WHERE r.reviewer_id = profiles.id
  ) OR EXISTS (
    SELECT 1 FROM public.chats c WHERE c.buyer_id = profiles.id
      AND (c.buyer_id = auth.uid() OR EXISTS (SELECT 1 FROM public.stores s WHERE s.id = c.store_id AND s.owner_id = auth.uid()))
  ));

DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Addresses (Strictly owner-only)
DROP POLICY IF EXISTS "addresses_own_all" ON public.addresses;
CREATE POLICY "addresses_own_all" ON public.addresses
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Stores
DROP POLICY IF EXISTS "stores_select_public_or_owner" ON public.stores;
CREATE POLICY "stores_select_public_or_owner" ON public.stores
  FOR SELECT USING ((verification_status = 'approved' AND is_active = true) OR auth.uid() = owner_id);

DROP POLICY IF EXISTS "stores_insert_own" ON public.stores;
CREATE POLICY "stores_insert_own" ON public.stores
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "stores_update_own" ON public.stores;
CREATE POLICY "stores_update_own" ON public.stores
  FOR UPDATE USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);

-- Categories (Public read)
DROP POLICY IF EXISTS "categories_select_all" ON public.categories;
CREATE POLICY "categories_select_all" ON public.categories
  FOR SELECT USING (true);

-- Products
DROP POLICY IF EXISTS "products_select_public_or_owner" ON public.products;
CREATE POLICY "products_select_public_or_owner" ON public.products
  FOR SELECT USING (
    (status = 'active' AND EXISTS (
      SELECT 1 FROM public.stores s WHERE s.id = products.store_id AND s.verification_status = 'approved' AND s.is_active = true
    ))
    OR EXISTS (SELECT 1 FROM public.stores s WHERE s.id = products.store_id AND s.owner_id = auth.uid())
  );

DROP POLICY IF EXISTS "products_modify_owner" ON public.products;
CREATE POLICY "products_modify_owner" ON public.products
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.stores s WHERE s.id = products.store_id AND s.owner_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.stores s WHERE s.id = products.store_id AND s.owner_id = auth.uid())
  );

-- Product Images
DROP POLICY IF EXISTS "product_images_select" ON public.product_images;
CREATE POLICY "product_images_select" ON public.product_images
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "product_images_owner_all" ON public.product_images;
CREATE POLICY "product_images_owner_all" ON public.product_images
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN public.stores s ON s.id = p.store_id
      WHERE p.id = product_images.product_id AND s.owner_id = auth.uid()
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN public.stores s ON s.id = p.store_id
      WHERE p.id = product_images.product_id AND s.owner_id = auth.uid()
    )
  );

-- Cart Items
DROP POLICY IF EXISTS "cart_items_own_all" ON public.cart_items;
CREATE POLICY "cart_items_own_all" ON public.cart_items
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Orders, Order Items, Payments, Shipments, Tracking (Read-only for involved buyer/seller; mutations via RPC)
DROP POLICY IF EXISTS "orders_select_involved" ON public.orders;
CREATE POLICY "orders_select_involved" ON public.orders
  FOR SELECT USING (
    auth.uid() = buyer_id OR EXISTS (
      SELECT 1 FROM public.stores s WHERE s.id = orders.store_id AND s.owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "order_items_select_involved" ON public.order_items;
CREATE POLICY "order_items_select_involved" ON public.order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      LEFT JOIN public.stores s ON s.id = o.store_id
      WHERE o.id = order_items.order_id AND (o.buyer_id = auth.uid() OR s.owner_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "payments_select_involved" ON public.payments;
CREATE POLICY "payments_select_involved" ON public.payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      LEFT JOIN public.stores s ON s.id = o.store_id
      WHERE o.id = payments.order_id AND (o.buyer_id = auth.uid() OR s.owner_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "shipments_select_involved" ON public.shipments;
CREATE POLICY "shipments_select_involved" ON public.shipments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      LEFT JOIN public.stores s ON s.id = o.store_id
      WHERE o.id = shipments.order_id AND (o.buyer_id = auth.uid() OR s.owner_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "shipment_tracking_select_involved" ON public.shipment_tracking;
CREATE POLICY "shipment_tracking_select_involved" ON public.shipment_tracking
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.shipments sh
      JOIN public.orders o ON o.id = sh.order_id
      LEFT JOIN public.stores s ON s.id = o.store_id
      WHERE sh.id = shipment_tracking.shipment_id AND (o.buyer_id = auth.uid() OR s.owner_id = auth.uid())
    )
  );

-- Chats & Messages (Involved buyer or store owner only)
DROP POLICY IF EXISTS "chats_select_involved" ON public.chats;
CREATE POLICY "chats_select_involved" ON public.chats
  FOR SELECT USING (
    auth.uid() = buyer_id OR EXISTS (
      SELECT 1 FROM public.stores s WHERE s.id = chats.store_id AND s.owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "chats_insert_buyer" ON public.chats;
CREATE POLICY "chats_insert_buyer" ON public.chats
  FOR INSERT WITH CHECK (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "chat_messages_select_involved" ON public.chat_messages;
CREATE POLICY "chat_messages_select_involved" ON public.chat_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.chats c
      LEFT JOIN public.stores s ON s.id = c.store_id
      WHERE c.id = chat_messages.chat_id AND (c.buyer_id = auth.uid() OR s.owner_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "chat_messages_insert_involved" ON public.chat_messages;
CREATE POLICY "chat_messages_insert_involved" ON public.chat_messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND EXISTS (
      SELECT 1 FROM public.chats c
      LEFT JOIN public.stores s ON s.id = c.store_id
      WHERE c.id = chat_messages.chat_id AND (c.buyer_id = auth.uid() OR s.owner_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "chat_messages_update_read" ON public.chat_messages;
CREATE POLICY "chat_messages_update_read" ON public.chat_messages
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.chats c
      LEFT JOIN public.stores s ON s.id = c.store_id
      WHERE c.id = chat_messages.chat_id AND (c.buyer_id = auth.uid() OR s.owner_id = auth.uid())
    )
  );

-- Reviews
DROP POLICY IF EXISTS "reviews_select_all" ON public.reviews;
CREATE POLICY "reviews_select_all" ON public.reviews FOR SELECT USING (true);

DROP POLICY IF EXISTS "reviews_insert_buyer" ON public.reviews;
CREATE POLICY "reviews_insert_buyer" ON public.reviews
  FOR INSERT WITH CHECK (
    auth.uid() = reviewer_id AND EXISTS (
      SELECT 1 FROM public.orders o WHERE o.id = reviews.order_id AND o.buyer_id = auth.uid() AND o.status = 'completed'
    )
  );

DROP POLICY IF EXISTS "reviews_update_reply_owner" ON public.reviews;
CREATE POLICY "reviews_update_reply_owner" ON public.reviews
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.stores s WHERE s.id = reviews.store_id AND s.owner_id = auth.uid())
  );

-- Promotions
DROP POLICY IF EXISTS "promotions_select" ON public.promotions;
CREATE POLICY "promotions_select" ON public.promotions
  FOR SELECT USING (is_active = true OR EXISTS (
    SELECT 1 FROM public.stores s WHERE s.id = promotions.store_id AND s.owner_id = auth.uid()
  ));

DROP POLICY IF EXISTS "promotions_owner_all" ON public.promotions;
CREATE POLICY "promotions_owner_all" ON public.promotions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.stores s WHERE s.id = promotions.store_id AND s.owner_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.stores s WHERE s.id = promotions.store_id AND s.owner_id = auth.uid())
  );

-- Payout Accounts & Requests (Owner-only)
DROP POLICY IF EXISTS "payout_accounts_owner" ON public.payout_accounts;
CREATE POLICY "payout_accounts_owner" ON public.payout_accounts
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.stores s WHERE s.id = payout_accounts.store_id AND s.owner_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.stores s WHERE s.id = payout_accounts.store_id AND s.owner_id = auth.uid())
  );

DROP POLICY IF EXISTS "payout_requests_owner" ON public.payout_requests;
CREATE POLICY "payout_requests_owner" ON public.payout_requests
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.stores s WHERE s.id = payout_requests.store_id AND s.owner_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.stores s WHERE s.id = payout_requests.store_id AND s.owner_id = auth.uid())
  );

-- Notifications (Owner-only)
DROP POLICY IF EXISTS "notifications_own_all" ON public.notifications;
CREATE POLICY "notifications_own_all" ON public.notifications
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Support Tickets (Owner-only)
DROP POLICY IF EXISTS "support_tickets_own" ON public.support_tickets;
CREATE POLICY "support_tickets_own" ON public.support_tickets
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- User Settings (Owner-only)
DROP POLICY IF EXISTS "user_settings_own" ON public.user_settings;
CREATE POLICY "user_settings_own" ON public.user_settings
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 5. SUPABASE STORAGE BUCKETS & POLICIES
-- ============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES
  ('avatars', 'avatars', true),
  ('store-assets', 'store-assets', true),
  ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "storage_public_read" ON storage.objects;
CREATE POLICY "storage_public_read" ON storage.objects
  FOR SELECT USING (bucket_id IN ('avatars', 'store-assets', 'product-images'));

DROP POLICY IF EXISTS "storage_authenticated_upload" ON storage.objects;
CREATE POLICY "storage_authenticated_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated'
    AND bucket_id IN ('avatars', 'store-assets', 'product-images')
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "storage_owner_update_delete" ON storage.objects;
CREATE POLICY "storage_owner_update_delete" ON storage.objects
  FOR UPDATE USING (
    auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "storage_owner_delete" ON storage.objects;
CREATE POLICY "storage_owner_delete" ON storage.objects
  FOR DELETE USING (
    auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================================================
-- 6. REALTIME PUBLICATION
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'chat_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
  END IF;
END $$;
