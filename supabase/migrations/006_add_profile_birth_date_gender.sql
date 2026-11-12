-- ============================================================================
-- Migration 006: Add Optional Birth Date & Gender Columns to public.profiles
-- ============================================================================
-- Safe additive migration preserving all existing profile rows & RLS rules.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS birth_date date,
  ADD COLUMN IF NOT EXISTS gender text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'profiles_gender_check'
      AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_gender_check
      CHECK (
        gender IS NULL
        OR gender IN ('Laki-laki', 'Perempuan', 'Tidak ingin menyebutkan')
      );
  END IF;
END $$;

