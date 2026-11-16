-- ============================================================================
-- Migration 009: Auth Email Sync Trigger, Phone Login Email Lookup,
-- & Account Self-Deletion RPC
-- ============================================================================
-- Additive & idempotent migration safe to run after 001..008.

-- 1. Sync confirmed auth.users.email changes into profiles & seller_profiles
CREATE OR REPLACE FUNCTION public.handle_auth_user_email_updated()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.email IS NOT NULL AND NEW.email IS DISTINCT FROM OLD.email THEN
    UPDATE public.profiles
    SET email = NEW.email,
        updated_at = now()
    WHERE id = NEW.id;

    UPDATE public.seller_profiles
    SET email = NEW.email,
        updated_at = now()
    WHERE user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_email_updated ON auth.users;
CREATE TRIGGER on_auth_user_email_updated
  AFTER UPDATE OF email ON auth.users
  FOR EACH ROW
  WHEN (OLD.email IS DISTINCT FROM NEW.email)
  EXECUTE FUNCTION public.handle_auth_user_email_updated();

-- 2. Normalize Indonesian phone digits & resolve login email for phone login
CREATE OR REPLACE FUNCTION public.resolve_login_email_by_phone(p_phone text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_digits text;
  v_email text;
BEGIN
  v_digits := regexp_replace(COALESCE(p_phone, ''), '\D', '', 'g');
  IF length(v_digits) < 9 THEN
    RETURN NULL;
  END IF;
  IF left(v_digits, 1) = '0' THEN
    v_digits := '62' || substr(v_digits, 2);
  ELSIF left(v_digits, 2) <> '62' THEN
    v_digits := '62' || v_digits;
  END IF;

  SELECT COALESCE(u.email, p.email)
  INTO v_email
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE (
    CASE
      WHEN left(regexp_replace(COALESCE(p.phone, ''), '\D', '', 'g'), 1) = '0'
        THEN '62' || substr(regexp_replace(COALESCE(p.phone, ''), '\D', '', 'g'), 2)
      WHEN left(regexp_replace(COALESCE(p.phone, ''), '\D', '', 'g'), 2) = '62'
        THEN regexp_replace(COALESCE(p.phone, ''), '\D', '', 'g')
      WHEN length(regexp_replace(COALESCE(p.phone, ''), '\D', '', 'g')) > 0
        THEN '62' || regexp_replace(COALESCE(p.phone, ''), '\D', '', 'g')
      ELSE ''
    END
  ) = v_digits
  AND NULLIF(trim(COALESCE(u.email, p.email, '')), '') IS NOT NULL
  LIMIT 1;

  RETURN v_email;
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_login_email_by_phone(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_login_email_by_phone(text) TO anon, authenticated;

-- 3. Make orders.buyer_id nullable with ON DELETE SET NULL for safe account deletion
DO $$
DECLARE
  v_con record;
BEGIN
  FOR v_con IN
    SELECT con.conname
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    JOIN pg_attribute att ON att.attrelid = rel.oid AND att.attnum = ANY(con.conkey)
    WHERE nsp.nspname = 'public'
      AND rel.relname = 'orders'
      AND con.contype = 'f'
      AND att.attname = 'buyer_id'
  LOOP
    EXECUTE format('ALTER TABLE public.orders DROP CONSTRAINT %I', v_con.conname);
  END LOOP;
END $$;

ALTER TABLE public.orders
  ALTER COLUMN buyer_id DROP NOT NULL;

ALTER TABLE public.orders
  DROP CONSTRAINT IF EXISTS orders_buyer_id_fkey;
ALTER TABLE public.orders
  ADD CONSTRAINT orders_buyer_id_fkey
  FOREIGN KEY (buyer_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 4. Safe self-service account deletion RPC
CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Autentikasi diperlukan untuk menghapus akun';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.orders
    WHERE buyer_id = v_uid
      AND status IN ('pending_payment', 'awaiting_confirmation', 'processing', 'ready_to_ship', 'shipped')
  ) THEN
    RAISE EXCEPTION 'Selesaikan atau batalkan seluruh pesanan aktif Anda sebelum menghapus akun.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.orders o
    JOIN public.stores s ON s.id = o.store_id
    WHERE s.owner_id = v_uid
  ) THEN
    RAISE EXCEPTION 'Akun pemilik toko yang memiliki riwayat pesanan tidak dapat dihapus otomatis. Hubungi Customer Service WijiBumi.';
  END IF;

  DELETE FROM auth.users WHERE id = v_uid;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_my_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;

