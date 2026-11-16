-- ============================================================================
-- Migration 008: Chat Media Storage Bucket & Realtime Publication for Chats
-- ============================================================================
-- Additive & idempotent migration safe to run after 001..007.

INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-media', 'chat-media', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "storage_public_read" ON storage.objects;
CREATE POLICY "storage_public_read" ON storage.objects
  FOR SELECT USING (
    bucket_id IN ('avatars', 'store-assets', 'product-images', 'chat-media')
  );

DROP POLICY IF EXISTS "storage_authenticated_upload" ON storage.objects;
CREATE POLICY "storage_authenticated_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated'
    AND bucket_id IN ('avatars', 'store-assets', 'product-images', 'chat-media')
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'chats'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;
  END IF;
END $$;

