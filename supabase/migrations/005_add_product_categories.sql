-- ============================================================================
-- Migration 005: Add Rempah-rempah, Bibit & Benih, and Umbi-umbian Categories
-- ============================================================================
-- Idempotent migration adding the 3 additional product categories so sellers
-- can publish products and buyers can filter all 6 categories in WijiBumi.

INSERT INTO public.categories (name, slug, description, icon) VALUES
  (
    'Rempah-rempah',
    'rempah-rempah',
    'Rempah-rempah segar dan kering pilihan langsung dari petani',
    'spa'
  ),
  (
    'Bibit & Benih',
    'bibit-benih',
    'Bibit unggul dan benih tanaman hortikultura siap tanam',
    'grass'
  ),
  (
    'Umbi-umbian',
    'umbi-umbian',
    'Umbi-umbian segar kualitas terbaik langsung dari kebun',
    'yard'
  )
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  icon = EXCLUDED.icon;

