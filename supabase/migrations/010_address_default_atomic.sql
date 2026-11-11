-- ============================================================================
-- Migration 010: Atomic Default Address Handling Trigger & RPC
-- ============================================================================
-- Additive & idempotent migration safe to run after 001..009.

-- 1. Trigger to automatically unset previous default addresses whenever a
--    new/updated row for the same user is marked is_default = true.
CREATE OR REPLACE FUNCTION public.clear_other_default_addresses()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.is_default IS TRUE THEN
    UPDATE public.addresses
    SET is_default = false,
        updated_at = now()
    WHERE user_id = NEW.user_id
      AND id IS DISTINCT FROM NEW.id
      AND is_default IS TRUE;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_clear_other_default_addresses ON public.addresses;
CREATE TRIGGER trg_clear_other_default_addresses
  BEFORE INSERT OR UPDATE OF is_default ON public.addresses
  FOR EACH ROW
  WHEN (NEW.is_default IS TRUE)
  EXECUTE FUNCTION public.clear_other_default_addresses();

-- 2. Single atomic RPC to switch the caller's default address cleanly.
CREATE OR REPLACE FUNCTION public.set_default_address(p_address_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Autentikasi diperlukan untuk mengubah alamat utama';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.addresses
    WHERE id = p_address_id AND user_id = v_uid
  ) THEN
    RAISE EXCEPTION 'Alamat tidak ditemukan atau bukan milik Anda';
  END IF;

  UPDATE public.addresses
  SET is_default = (id = p_address_id),
      updated_at = now()
  WHERE user_id = v_uid;
END;
$$;

REVOKE ALL ON FUNCTION public.set_default_address(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_default_address(uuid) TO authenticated;

