import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/store.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../services/supabase_service.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/lucide_icons.dart';
import '../../widgets/review_list_card.dart';
import '../../widgets/smart_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_guard.dart';
import '../chat/chat_room_screen.dart';
import '../home/product_detail_screen.dart';

class StoreDetailScreen extends StatefulWidget {
  final Store store;

  const StoreDetailScreen({super.key, required this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Product> _storeProducts = [];
  List<Review> _storeReviews = [];
  bool _isLoading = true;
  bool _isLoadingReviews = true;
  String _searchInStore = '';

  final List<String> _categories = [
    'Semua',
    ...AppConstants.productCategories,
    'Ulasan',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() {
      _isLoading = true;
      _isLoadingReviews = true;
    });
    final productsFuture = SupabaseService.instance
        .getStoreProducts(widget.store.id)
        .then<List<Product>?>((val) => val)
        .catchError((Object e) {
      debugPrint('Error loading store products: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat produk toko. Coba beberapa saat lagi.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    });
    final reviewsFuture = SupabaseService.instance
        .getStoreReviews(widget.store.id)
        .catchError((Object e) {
      debugPrint('Error loading store reviews: $e');
      return <Review>[];
    });

    final prods = await productsFuture;
    final revs = await reviewsFuture;
    if (!mounted) return;
    setState(() {
      if (prods != null) {
        _storeProducts = prods.where((p) => p.status == 'active').toList();
      }
      _storeReviews = revs;
      _isLoading = false;
      _isLoadingReviews = false;
    });
  }

  Future<void> _handleAddToCart(Product product) async {
    if (!await ensureBuyerAuthenticated(context)) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final cartProv = context.read<CartProvider>();
    if (!product.isAvailable) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Maaf, stok produk sedang habis.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final ok = await cartProv.addToCart(product);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${product.name} dimasukkan ke keranjang'
              : (cartProv.lastError ??
                  'Jumlah melebihi stok tersedia (${product.stock} ${product.unit}).'),
        ),
        backgroundColor: ok ? null : AppColors.warning,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts(int tabIndex) {
    var list = _storeProducts;
    if (tabIndex > 0) {
      final catName = _categories[tabIndex];
      list = list.where((p) => p.categoryName == catName).toList();
    }
    if (_searchInStore.isNotEmpty) {
      final q = _searchInStore.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final store = widget.store;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              foregroundColor: innerBoxIsScrolled
                  ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                  : Colors.white,
              title: innerBoxIsScrolled ? Text(store.storeName) : null,
              actions: [
                IconButton(
                  icon: const LucideMessageCircleIcon(size: 28),
                  tooltip: 'Chat Toko',
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    if (!await ensureBuyerAuthenticated(context)) return;
                    if (!mounted) return;
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          storeId: store.id,
                          title: store.storeName,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    SmartImage(
                      source: store.coverPath ??
                          'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=800&q=80',
                      fit: BoxFit.cover,
                      fallback: Container(color: AppColors.primaryDark),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.black.withValues(alpha: 0.72),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: SmartImage(
                                source: store.logoPath ??
                                    'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&w=300&q=80',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        store.storeName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (store.isApproved)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(Icons.verified, color: AppColors.primaryLight, size: 18),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    if (store.city != null && store.city!.trim().isNotEmpty)
                                      store.city!.trim(),
                                    if (store.province != null && store.province!.trim().isNotEmpty)
                                      store.province!.trim(),
                                  ].join(', ').isNotEmpty
                                      ? [
                                          if (store.city != null && store.city!.trim().isNotEmpty)
                                            store.city!.trim(),
                                          if (store.province != null && store.province!.trim().isNotEmpty)
                                            store.province!.trim(),
                                        ].join(', ')
                                      : 'Indonesia',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Details Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (store.description != null && store.description!.isNotEmpty) ...[
                            Text(
                              store.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  store.address ?? 'Alamat kebun belum diatur',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      store.phone ?? '-',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.email_outlined, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      store.email ?? '-',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () => _tabController.animateTo(_categories.length - 1),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _storeReviews.isNotEmpty
                                          ? '${(_storeReviews.fold<int>(0, (sum, r) => sum + r.rating) / _storeReviews.length).toStringAsFixed(1)} (${_storeReviews.length} Ulasan Pembeli)'
                                          : (store.totalReviews > 0
                                              ? '${store.rating.toStringAsFixed(1)} (${store.totalReviews} Ulasan)'
                                              : 'Lihat Ulasan Pembeli'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.primaryLight
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Search in store
                    TextField(
                      onChanged: (val) => setState(() => _searchInStore = val),
                      decoration: InputDecoration(
                        hintText: 'Cari produk di toko ini...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: isDark ? AppColors.primaryLight : AppColors.primary,
                  labelColor: isDark ? AppColors.primaryLight : AppColors.primary,
                  unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  tabs: _categories.map((c) {
                    if (c == 'Ulasan' && _storeReviews.isNotEmpty) {
                      return Tab(text: 'Ulasan (${_storeReviews.length})');
                    }
                    return Tab(text: c);
                  }).toList(),
                ),
                color: theme.scaffoldBackgroundColor,
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: List.generate(_categories.length, (tabIndex) {
                  if (_categories[tabIndex] == 'Ulasan') {
                    return _buildReviewsTab(isDark);
                  }
                  final prods = _getFilteredProducts(tabIndex);
                  if (prods.isEmpty) {
                    return const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Tidak Ada Produk',
                      message: 'Toko ini belum memiliki produk pada kategori ini.',
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 215,
                      mainAxisExtent: (256.0 *
                              MediaQuery.textScalerOf(context)
                                  .scale(1.0)
                                  .clamp(1.0, 1.35))
                          .ceilToDouble(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: prods.length,
                    itemBuilder: (context, index) {
                      final product = prods[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        onAddToCart: () => _handleAddToCart(product),
                      );
                    },
                  );
                }),
              ),
      ),
    );
  }

  Widget _buildReviewsTab(bool isDark) {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_storeReviews.isEmpty) {
      return const EmptyState(
        icon: Icons.rate_review_outlined,
        title: 'Belum Ada Ulasan',
        message: 'Jadilah pembeli pertama yang memberikan ulasan untuk kebun mitra ini.',
      );
    }
    final avgRating = _storeReviews.fold<int>(0, (sum, r) => sum + r.rating) /
        _storeReviews.length;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _storeReviews.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : const Color(0xFFEBF5EE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.secondary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${avgRating.toStringAsFixed(1)} / 5.0',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Berdasarkan ${_storeReviews.length} ulasan pembeli terverifikasi',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return BuyerReviewTileCard(review: _storeReviews[index - 1]);
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;

  _SliverAppBarDelegate(this.tabBar, {required this.color});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return color != oldDelegate.color || tabBar != oldDelegate.tabBar;
  }
}
