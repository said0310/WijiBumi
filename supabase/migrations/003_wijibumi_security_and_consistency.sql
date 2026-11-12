-- ============================================================================
-- Migration 003: WijiBumi Security Hardening, Branding & Consistency Fixes
-- ============================================================================
-- Additive & idempotent migration safe to run after 001 and 002.

-- 1. Handle phone-only signups safely in handle_new_user()
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

-- 2. Rebrand legacy TaniHub trigger messages to WijiBumi
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
      'Pesan baru dari ' || COALESCE(NULLIF(trim(v_sender_name), ''), 'Pengguna WijiBumi'),
      LEFT(COALESCE(NEW.body, 'Mengirim lampiran gambar'), 120),
      NEW.chat_id::text
    );
  END IF;

  RETURN NEW;
END;
$$;

-- 3. Protect reviews & chat_messages immutable columns during client UPDATEs
CREATE OR REPLACE FUNCTION public.protect_review_reply_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF current_user IN ('anon', 'authenticated') OR COALESCE(auth.role(), '') IN ('anon', 'authenticated') THEN
    NEW.order_id := OLD.order_id;
    NEW.store_id := OLD.store_id;
    NEW.product_id := OLD.product_id;
    NEW.reviewer_id := OLD.reviewer_id;
    NEW.rating := OLD.rating;
    NEW.review_text := OLD.review_text;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_review_reply_update ON public.reviews;
CREATE TRIGGER trg_protect_review_reply_update
  BEFORE UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.protect_review_reply_update();

CREATE OR REPLACE FUNCTION public.protect_chat_message_read_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF current_user IN ('anon', 'authenticated') OR COALESCE(auth.role(), '') IN ('anon', 'authenticated') THEN
    NEW.chat_id := OLD.chat_id;
    NEW.sender_id := OLD.sender_id;
    NEW.body := OLD.body;
    NEW.media_path := OLD.media_path;
    NEW.created_at := OLD.created_at;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_chat_message_read_update ON public.chat_messages;
CREATE TRIGGER trg_protect_chat_message_read_update
  BEFORE UPDATE ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION public.protect_chat_message_read_update();

-- 4. Automatically sync stores.rating, stores.total_reviews & products.rating
CREATE OR REPLACE FUNCTION public.sync_ratings_on_review()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_store_id uuid := COALESCE(NEW.store_id, OLD.store_id);
  v_product_id uuid := COALESCE(NEW.product_id, OLD.product_id);
BEGIN
  IF v_store_id IS NOT NULL THEN
    UPDATE public.stores
    SET rating = COALESCE((SELECT ROUND(AVG(rating)::numeric, 2)::double precision FROM public.reviews WHERE store_id = v_store_id), 0),
        total_reviews = (SELECT COUNT(*) FROM public.reviews WHERE store_id = v_store_id)
    WHERE id = v_store_id;
  END IF;

  IF v_product_id IS NOT NULL THEN
    UPDATE public.products
    SET rating = COALESCE((SELECT ROUND(AVG(rating)::numeric, 2)::double precision FROM public.reviews WHERE product_id = v_product_id), 0)
    WHERE id = v_product_id;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_ratings_on_review ON public.reviews;
CREATE TRIGGER trg_sync_ratings_on_review
  AFTER INSERT OR UPDATE OR DELETE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.sync_ratings_on_review();

-- 5. Allow sellers to read buyer profiles for orders belonging to their store
DROP POLICY IF EXISTS "profiles_select_authenticated" ON public.profiles;
CREATE POLICY "profiles_select_authenticated" ON public.profiles
  FOR SELECT USING (
    auth.uid() = id
    OR EXISTS (SELECT 1 FROM public.reviews r WHERE r.reviewer_id = profiles.id)
    OR EXISTS (
      SELECT 1 FROM public.chats c
      WHERE c.buyer_id = profiles.id
        AND (c.buyer_id = auth.uid() OR EXISTS (
          SELECT 1 FROM public.stores s WHERE s.id = c.store_id AND s.owner_id = auth.uid()
        ))
    )
    OR EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.stores s ON s.id = o.store_id
      WHERE o.buyer_id = profiles.id AND s.owner_id = auth.uid()
    )
  );

