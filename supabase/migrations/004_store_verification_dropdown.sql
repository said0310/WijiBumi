-- ============================================================================
-- Migration 004: Dropdown ENUM for Store Verification in Supabase Table Editor
-- ============================================================================
-- Converts public.stores.verification_status from plain text to PostgreSQL ENUM
-- (public.store_verification_status) so Supabase Table Editor renders a
-- clickable dropdown ('pending', 'approved', 'rejected', 'suspended'), and
-- automatically activates the store & notifies the owner when approved.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'store_verification_status'
  ) THEN
    CREATE TYPE public.store_verification_status AS ENUM (
      'pending',
      'approved',
      'rejected',
      'suspended'
    );
  END IF;
END $$;

-- Policies referencing stores.verification_status must be recreated around ALTER COLUMN TYPE
DROP POLICY IF EXISTS "stores_select_public_or_owner" ON public.stores;
DROP POLICY IF EXISTS "products_select_public_or_owner" ON public.products;

DO $$
DECLARE
  v_udt text;
  v_con record;
BEGIN
  SELECT c.udt_name
  INTO v_udt
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND c.table_name = 'stores'
    AND c.column_name = 'verification_status';

  IF v_udt IS NOT NULL AND v_udt <> 'store_verification_status' THEN
    -- Drop existing CHECK constraints referencing verification_status
    FOR v_con IN
      SELECT conname
      FROM pg_constraint
      WHERE conrelid = 'public.stores'::regclass
        AND contype = 'c'
        AND pg_get_constraintdef(oid) ILIKE '%verification_status%'
    LOOP
      EXECUTE format('ALTER TABLE public.stores DROP CONSTRAINT IF EXISTS %I', v_con.conname);
    END LOOP;

    -- Normalize legacy values before converting to enum
    UPDATE public.stores
    SET verification_status = CASE
      WHEN lower(trim(COALESCE(verification_status, ''))) IN ('pending', 'approved', 'rejected', 'suspended')
        THEN lower(trim(verification_status))
      ELSE 'pending'
    END;

    ALTER TABLE public.stores
      ALTER COLUMN verification_status DROP DEFAULT;

    ALTER TABLE public.stores
      ALTER COLUMN verification_status TYPE public.store_verification_status
      USING verification_status::public.store_verification_status;

    ALTER TABLE public.stores
      ALTER COLUMN verification_status SET DEFAULT 'pending'::public.store_verification_status;
  END IF;
END $$;

CREATE POLICY "stores_select_public_or_owner" ON public.stores
  FOR SELECT USING (
    (verification_status = 'approved'::public.store_verification_status AND is_active = true)
    OR auth.uid() = owner_id
  );

CREATE POLICY "products_select_public_or_owner" ON public.products
  FOR SELECT USING (
    (status = 'active' AND EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.verification_status = 'approved'::public.store_verification_status
        AND s.is_active = true
    ))
    OR EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.owner_id = auth.uid()
    )
  );

-- Update trigger:
-- 1) Frontend users (anon/authenticated) still cannot self-approve stores.
-- 2) Admin selecting 'approved' from the Supabase dropdown auto-activates the store.
CREATE OR REPLACE FUNCTION public.protect_store_verification()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF current_user IN ('anon', 'authenticated') OR COALESCE(auth.role(), '') IN ('anon', 'authenticated') THEN
    IF TG_OP = 'INSERT' THEN
      NEW.verification_status := 'pending'::public.store_verification_status;
      NEW.is_active := false;
      NEW.verification_note := 'Menunggu verifikasi tim WijiBumi.';
    ELSIF TG_OP = 'UPDATE' THEN
      NEW.verification_status := OLD.verification_status;
      NEW.verification_note := OLD.verification_note;
      NEW.is_active := OLD.is_active;
    END IF;
    RETURN NEW;
  END IF;

  -- Admin / Dashboard / SQL Editor action: keep verification_status & is_active synced
  IF TG_OP = 'UPDATE' THEN
    IF NEW.verification_status IS DISTINCT FROM OLD.verification_status THEN
      IF NEW.verification_status = 'approved'::public.store_verification_status THEN
        NEW.is_active := true;
        IF COALESCE(NULLIF(trim(NEW.verification_note), ''), '') IN (
          '',
          'Menunggu verifikasi tim WijiBumi.',
          'Menunggu verifikasi tim TaniHub.'
        ) THEN
          NEW.verification_note := 'Toko telah diverifikasi dan aktif oleh tim WijiBumi.';
        END IF;
      ELSIF NEW.verification_status IN (
        'pending'::public.store_verification_status,
        'rejected'::public.store_verification_status,
        'suspended'::public.store_verification_status
      ) THEN
        NEW.is_active := false;
      END IF;
    ELSIF NEW.is_active IS TRUE
        AND OLD.is_active IS FALSE
        AND NEW.verification_status = 'pending'::public.store_verification_status THEN
      NEW.verification_status := 'approved'::public.store_verification_status;
      IF COALESCE(NULLIF(trim(NEW.verification_note), ''), '') IN (
        '',
        'Menunggu verifikasi tim WijiBumi.',
        'Menunggu verifikasi tim TaniHub.'
      ) THEN
        NEW.verification_note := 'Toko telah diverifikasi dan aktif oleh tim WijiBumi.';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_store_verification ON public.stores;
CREATE TRIGGER trg_protect_store_verification
  BEFORE INSERT OR UPDATE ON public.stores
  FOR EACH ROW EXECUTE FUNCTION public.protect_store_verification();

-- Clean up default pending note on rows already approved before this migration
UPDATE public.stores
SET verification_note = 'Toko telah diverifikasi dan aktif oleh tim WijiBumi.'
WHERE verification_status = 'approved'::public.store_verification_status
  AND COALESCE(NULLIF(trim(verification_note), ''), '') IN (
    '',
    'Menunggu verifikasi tim WijiBumi.',
    'Menunggu verifikasi tim TaniHub.'
  );

-- Notify store owner automatically when admin changes verification_status
CREATE OR REPLACE FUNCTION public.notify_store_verification_changed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.verification_status IS DISTINCT FROM OLD.verification_status THEN
    IF NEW.verification_status = 'approved'::public.store_verification_status THEN
      INSERT INTO public.notifications (user_id, type, title, body, reference_id)
      VALUES (
        NEW.owner_id,
        'system',
        'Toko Anda Disetujui!',
        'Selamat! Toko "' || NEW.store_name || '" telah terverifikasi dan kini aktif untuk berjualan di WijiBumi.',
        NEW.id::text
      );
    ELSIF NEW.verification_status = 'rejected'::public.store_verification_status THEN
      INSERT INTO public.notifications (user_id, type, title, body, reference_id)
      VALUES (
        NEW.owner_id,
        'system',
        'Verifikasi Toko Ditolak',
        COALESCE(NULLIF(trim(NEW.verification_note), ''), 'Pengajuan verifikasi toko "' || NEW.store_name || '" belum memenuhi syarat.'),
        NEW.id::text
      );
    ELSIF NEW.verification_status = 'suspended'::public.store_verification_status THEN
      INSERT INTO public.notifications (user_id, type, title, body, reference_id)
      VALUES (
        NEW.owner_id,
        'system',
        'Toko Dinonaktifkan Sementara',
        COALESCE(NULLIF(trim(NEW.verification_note), ''), 'Toko "' || NEW.store_name || '" sedang dinonaktifkan sementara oleh tim WijiBumi.'),
        NEW.id::text
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_store_verification ON public.stores;
CREATE TRIGGER trg_notify_store_verification
  AFTER UPDATE OF verification_status ON public.stores
  FOR EACH ROW EXECUTE FUNCTION public.notify_store_verification_changed();

