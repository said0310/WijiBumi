import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Model konfigurasi setiap slide pada banner slideshow Beranda.
class HomeBannerSlide {
  final String title;
  final String subtitle;
  final String badgeText;
  final String ctaText;
  final String categorySlug;

  /// Path asset lokal di folder `assets/images/banners/` (disediakan oleh pemilik aplikasi).
  final String assetPath;

  /// Warna gradasi botani fallback ketika file gambar asset belum ditambahkan.
  final List<Color> fallbackGradient;

  const HomeBannerSlide({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.ctaText,
    required this.categorySlug,
    required this.assetPath,
    required this.fallbackGradient,
  });
}

/// Daftar banner promosi Beranda.
/// Letakkan file gambar sayuran/buah pada `assets/images/banners/` atau ubah `assetPath` di bawah ini.
const List<HomeBannerSlide> kHomePromoBanners = [
  HomeBannerSlide(
    title: 'Panen Raya Sayur Segar!',
    subtitle: 'Sayuran organik bebas pestisida langsung dari kebun mitra tani.',
    badgeText: 'Diskon hingga 20% • Panen Raya',
    ctaText: 'Belanja Sekarang',
    categorySlug: 'sayuran',
    assetPath: 'assets/images/banners/banner_sayuran.jpg',
    fallbackGradient: [Color(0xFF0E4A2D), Color(0xFF216E43)],
  ),
  HomeBannerSlide(
    title: 'Buah Manis Petik Pohon',
    subtitle: 'Apel Malang, Cavendish, dan Stroberi segar pilihan petani.',
    badgeText: 'Garansi Segar 100%',
    ctaText: 'Lihat Buah Segar',
    categorySlug: 'buah-buahan',
    assetPath: 'assets/images/banners/banner_buah.jpg',
    fallbackGradient: [Color(0xFF174F31), Color(0xFF2B7A4B)],
  ),
  HomeBannerSlide(
    title: 'Bunga Potong Berkualitas',
    subtitle: 'Mawar, krisan & anggrek segar langsung dari kebun.',
    badgeText: 'Mulai Rp 30.000',
    ctaText: 'Lihat Koleksi',
    categorySlug: 'bunga',
    assetPath: 'assets/images/banners/banner_bunga.jpg',
    fallbackGradient: [Color(0xFF144229), Color(0xFF256840)],
  ),
];

/// Banner slideshow produk pertanian berbasis image asset dengan dukungan swipe manual & auto-slide.
class HomeBannerSlideshow extends StatefulWidget {
  final List<HomeBannerSlide> slides;
  final double height;
  final ValueChanged<HomeBannerSlide>? onSlideTap;
  final bool enableAutoPlay;

  const HomeBannerSlideshow({
    super.key,
    this.slides = kHomePromoBanners,
    this.height = 176,
    this.onSlideTap,
    this.enableAutoPlay = true,
  });

  @override
  State<HomeBannerSlideshow> createState() => _HomeBannerSlideshowState();
}

class _HomeBannerSlideshowState extends State<HomeBannerSlideshow> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant HomeBannerSlideshow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableAutoPlay != widget.enableAutoPlay ||
        oldWidget.slides.length != widget.slides.length) {
      _autoPlayTimer?.cancel();
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (!widget.enableAutoPlay || widget.slides.length <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients || widget.slides.length <= 1) {
        return;
      }
      final nextPage = (_currentPage + 1) % widget.slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: widget.height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification &&
              notification.dragDetails != null) {
            _autoPlayTimer?.cancel();
          } else if (notification is ScrollEndNotification) {
            _startAutoPlay();
          }
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.slides.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) {
            final slide = widget.slides[index];
            return _BannerSlideCard(
              slide: slide,
              currentIndex: _currentPage,
              totalSlides: widget.slides.length,
              onTap: () => widget.onSlideTap?.call(slide),
            );
          },
        ),
      ),
    );
  }
}

class _BannerSlideCard extends StatelessWidget {
  final HomeBannerSlide slide;
  final int currentIndex;
  final int totalSlides;
  final VoidCallback onTap;

  const _BannerSlideCard({
    required this.slide,
    required this.currentIndex,
    required this.totalSlides,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Asset image with subtle botanical fallback when file hasn't been dropped in yet
                  Image.asset(
                    slide.assetPath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, _, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: slide.fallbackGradient,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -14,
                            top: -10,
                            child: Icon(
                              Icons.eco_outlined,
                              size: 132,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Subtle readability gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.62),
                          Colors.black.withValues(alpha: 0.34),
                          Colors.black.withValues(alpha: 0.14),
                        ],
                      ),
                    ),
                  ),

                  // Foreground Content: Badge, Title, Subtitle, CTA & Indicators
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC8EBD2)
                                    .withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.eco,
                                    size: 12,
                                    color: AppColors.forestGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      slide.badgeText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.forestGreen,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              slide.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slide.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 11.5,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),

                        // CTA Pill + Slide Indicator Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        slide.ctaText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.forestGreen,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: AppColors.forestGreen,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (totalSlides > 1) ...[
                              const SizedBox(width: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(totalSlides, (dotIdx) {
                                  final active = dotIdx == currentIndex;
                                  return AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 220),
                                    margin: const EdgeInsets.only(left: 5),
                                    width: active ? 18 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

