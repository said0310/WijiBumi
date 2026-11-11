import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/address.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/store_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_guard.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/home_banner_slideshow.dart';
import '../../widgets/lucide_icons.dart';
import '../../widgets/product_card.dart';
import '../../widgets/smart_image.dart';
import '../../widgets/wijibumi_auth_widgets.dart';
import '../auth/login_screen.dart';
import '../cart/cart_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/address_list_screen.dart';
import '../store/store_detail_screen.dart';
import '../store/store_list_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSeeAllStoresTap;

  const HomeScreen({super.key, this.onSeeAllStoresTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val, ProductProvider productProvider) {
    _searchDebounce?.cancel();
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      productProvider.clearSearch();
      setState(() {});
      return;
    }
    setState(() {});
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      productProvider.setSearchQuery(trimmed);
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

  void _openAddresses(bool isAuthenticated) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            isAuthenticated ? const AddressListScreen() : const LoginScreen(),
      ),
    );
  }

  void _openStoresList() {
    if (widget.onSeeAllStoresTap != null) {
      widget.onSeeAllStoresTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StoreListScreen()),
    );
  }

  Future<void> _showCategoryFilterSheet(ProductProvider productProvider) async {
    String? tempCategoryId = productProvider.selectedCategoryId;

    await showGlassBottomSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final accentGreen =
            isDark ? AppColors.primaryLight : AppColors.forestGreen;
        final titleColor =
            isDark ? AppColors.textPrimaryDark : AppColors.neutralDark;

        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Filter Kategori Produk',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setSheetState(() => tempCategoryId = null);
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: accentGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterSheetChoiceChip(
                          label: 'Semua',
                          selected: tempCategoryId == null,
                          isDark: isDark,
                          onTap: () => setSheetState(() => tempCategoryId = null),
                        ),
                        ...productProvider.categories.map(
                          (cat) => _FilterSheetChoiceChip(
                            label: cat.name,
                            selected: tempCategoryId == cat.id,
                            isDark: isDark,
                            onTap: () =>
                                setSheetState(() => tempCategoryId = cat.id),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        productProvider.setCategory(tempCategoryId);
                        Navigator.pop(sheetCtx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatShortAddress(Address? addr, bool isAuthenticated) {
    if (!isAuthenticated) return 'Masuk untuk atur alamat pengiriman';
    if (addr == null) return 'Belum ada alamat utama — Tambah alamat';
    final areaParts = [
      if (addr.district != null && addr.district!.trim().isNotEmpty)
        addr.district!.trim(),
      if (addr.city != null && addr.city!.trim().isNotEmpty)
        addr.city!.trim(),
    ];
    final area = areaParts.isNotEmpty ? areaParts.join(', ') : addr.address;
    return '${addr.label} ($area)';
  }

  IconData _categoryIcon(String slug) {
    return switch (slug.toLowerCase()) {
      'bunga' => Icons.local_florist,
      'sayuran' => Icons.eco,
      'buah-buahan' => Icons.apple,
      'rempah-rempah' => Icons.spa,
      'bibit-benih' => Icons.grass,
      'umbi-umbian' => Icons.yard,
      _ => Icons.eco,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final productProvider = context.watch<ProductProvider>();
    final storeProvider = context.watch<StoreProvider>();
    final cartCount = context.watch<CartProvider>().itemCount;
    final myStoreId = storeProvider.myStore?.id;
    final unreadChatCount = context.watch<ChatProvider>().buyerUnreadCount(
          myStoreId,
          myUserId: authProvider.user?.id,
        );

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardExtent = (256.0 * textScale.clamp(1.0, 1.35)).ceilToDouble();
    final bannerHeight = (184.0 * textScale.clamp(1.0, 1.3)).ceilToDouble();
    final farmerCardHeight = (112.0 * textScale.clamp(1.0, 1.3)).ceilToDouble();
    final headerLogoSize = screenWidth < 340
        ? 40.0
        : (screenWidth >= 600 ? 44.0 : 43.0);
    final gridCrossAxisCount =
        screenWidth >= 900 ? 4 : (screenWidth >= 600 ? 3 : 2);

    final pageBg = isDark ? AppColors.backgroundDark : const Color(0xFFECF4EE);
    final cardBg = isDark ? AppColors.cardDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderDark : const Color(0xFFE0EBE3);
    final accentGreen =
        isDark ? AppColors.primaryLight : AppColors.forestGreen;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.neutralDark;
    final mutedTextColor =
        isDark ? AppColors.textMutedDark : const Color(0xFF6B7280);
    final softMintBg = isDark
        ? AppColors.primary.withValues(alpha: 0.16)
        : const Color(0xFFDCEEE2);
    final headerIconColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final isAuthenticated = authProvider.isAuthenticated;
    final defaultAddress = addressProvider.defaultAddress;
    final showFarmersAndBanner = productProvider.searchQuery.isEmpty;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            WijiBumiCompactLogo(size: headerLogoSize),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WijiBumi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                  Text(
                    'Pasar Tani Digital',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: mutedTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Chat Icon with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: LucideMessageCircleIcon(
                  size: 28,
                  color: headerIconColor,
                ),
                tooltip: 'Pesan',
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  if (!await ensureBuyerAuthenticated(context)) return;
                  if (!mounted) return;
                  navigator.push(
                    MaterialPageRoute(builder: (_) => const ChatListScreen()),
                  );
                },
              ),
              if (unreadChatCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: pageBg, width: 1.2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadChatCount > 99 ? '99+' : '$unreadChatCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Cart Icon with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: LucideShoppingCartIcon(
                  size: 28,
                  color: headerIconColor,
                ),
                tooltip: 'Keranjang',
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  if (!await ensureBuyerAuthenticated(context)) return;
                  if (!mounted) return;
                  navigator.push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: pageBg, width: 1.2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        cartCount > 99 ? '99+' : '$cartCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            productProvider.initData(),
            storeProvider.loadStores(),
            if (isAuthenticated) addressProvider.loadAddresses(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Shipping Address Section (using existing AddressProvider & AddressListScreen)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: mutedTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Dikirim ke',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _openAddresses(isAuthenticated),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              'Ubah Alamat',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: accentGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Material(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: () => _openAddresses(isAuthenticated),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: softMintBg,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: accentGreen,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _formatShortAddress(
                                    defaultAddress,
                                    isAuthenticated,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: titleColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: mutedTextColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Compact Search Bar + Category Filter Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            _onSearchChanged(val, productProvider),
                        style: TextStyle(fontSize: 13.5, color: titleColor),
                        decoration: InputDecoration(
                          hintText: 'Cari bunga, sayuran, buah, atau toko...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: mutedTextColor,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: mutedTextColor,
                          ),
                          suffixIcon: (_searchController.text.isNotEmpty ||
                                  productProvider.searchQuery.isNotEmpty)
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchDebounce?.cancel();
                                    _searchController.clear();
                                    productProvider.clearSearch();
                                    setState(() {});
                                  },
                                )
                              : null,
                          fillColor: cardBg,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: accentGreen,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Tooltip(
                          message: 'Filter Kategori',
                          child: Material(
                            color: productProvider.selectedCategoryId != null
                                ? accentGreen
                                : softMintBg,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () =>
                                  _showCategoryFilterSheet(productProvider),
                              child: SizedBox(
                                width: 46,
                                height: 46,
                                child: Icon(
                                  Icons.tune,
                                  size: 21,
                                  color: productProvider.selectedCategoryId !=
                                          null
                                      ? (isDark ? Colors.black : Colors.white)
                                      : accentGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (productProvider.selectedCategoryId != null)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryEmerald,
                                shape: BoxShape.circle,
                                border: Border.all(color: pageBg, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Asset-Based Banner Slideshow
              if (showFarmersAndBanner) ...[
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth >= 900 ? 920 : double.infinity,
                    ),
                    child: HomeBannerSlideshow(
                      height: bannerHeight,
                      onSlideTap: (slide) {
                        final matches = productProvider.categories
                            .where((c) => c.slug == slide.categorySlug);
                        if (matches.isNotEmpty) {
                          productProvider.setCategory(matches.first.id);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 4. Category Selector (all 7 categories preserved)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategori Produk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip(
                            label: 'Semua',
                            icon: Icons.grid_view,
                            isSelected:
                                productProvider.selectedCategoryId == null,
                            onTap: () => productProvider.selectCategory(null),
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                          ...productProvider.categories.map((cat) {
                            return _buildCategoryChip(
                              label: cat.name,
                              icon: _categoryIcon(cat.slug),
                              isSelected:
                                  productProvider.selectedCategoryId == cat.id,
                              onTap: () =>
                                  productProvider.selectCategory(cat.id),
                              isDark: isDark,
                              borderColor: borderColor,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 5. Rekomendasi Petani (Horizontal Store Cards from actual StoreProvider data)
              if (showFarmersAndBanner &&
                  productProvider.selectedCategoryId == null &&
                  storeProvider.stores.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 18,
                              color: accentGreen,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Rekomendasi Petani',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _openStoresList,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: accentGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: accentGreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: farmerCardHeight,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: storeProvider.stores.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final store = storeProvider.stores[index];
                      final productCount = productProvider.products
                          .where((p) => p.storeId == store.id)
                          .length;
                      return _FarmerRecommendationCard(
                        store: store,
                        productCount: productCount,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        softMintBg: softMintBg,
                        accentGreen: accentGreen,
                        titleColor: titleColor,
                        mutedTextColor: mutedTextColor,
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoreDetailScreen(store: store),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // 6. Daftar Produk Segar (2 Columns on Mobile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productProvider.searchQuery.isNotEmpty
                          ? 'Hasil Pencarian (${productProvider.products.length})'
                          : 'Daftar Produk Segar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    if (productProvider.searchQuery.isEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Langsung dipanen setelah dipesan',
                        style: TextStyle(
                          fontSize: 12,
                          color: mutedTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (productProvider.isLoading && productProvider.products.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (productProvider.products.isEmpty)
                const EmptyState(
                  icon: Icons.search_off,
                  title: 'Produk Tidak Ditemukan',
                  message:
                      'Coba ubah kata kunci pencarian atau pilih kategori yang berbeda.',
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCrossAxisCount,
                      mainAxisExtent: cardExtent,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: productProvider.products.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.products[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        onAddToCart: () => _handleAddToCart(product),
                      );
                    },
                  ),
                ),

              // 7. Bottom Local Farmer Commitment Note
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark
                        : Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: softMintBg,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.volunteer_activism_outlined,
                          size: 20,
                          color: accentGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '100% Langsung dari Petani Lokal',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Setiap transaksi Anda mendukung kemandirian pangan mitra kebun Indonesia.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
  }) {
    final activeBg = isDark ? AppColors.primaryLight : AppColors.forestGreen;
    final inactiveBg = isDark ? AppColors.cardDark : AppColors.surfaceLight;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? activeBg : inactiveBg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: isSelected ? null : Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? AppColors.primaryLight : AppColors.forestGreen),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.neutralDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FarmerRecommendationCard extends StatelessWidget {
  final Store store;
  final int productCount;
  final Color cardBg;
  final Color borderColor;
  final Color softMintBg;
  final Color accentGreen;
  final Color titleColor;
  final Color mutedTextColor;
  final bool isDark;
  final VoidCallback onTap;

  const _FarmerRecommendationCard({
    required this.store,
    required this.productCount,
    required this.cardBg,
    required this.borderColor,
    required this.softMintBg,
    required this.accentGreen,
    required this.titleColor,
    required this.mutedTextColor,
    required this.isDark,
    required this.onTap,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'W';
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = store.logoPath != null && store.logoPath!.trim().isNotEmpty;
    final location = store.city?.trim().isNotEmpty == true
        ? store.city!.trim()
        : (store.district?.trim().isNotEmpty == true
            ? store.district!.trim()
            : 'Indonesia');
    final metricRight =
        productCount > 0 ? '$productCount Produk' : '${store.totalReviews} Ulasan';

    return SizedBox(
      width: 224,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: softMintBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: ClipOval(
                          child: hasLogo
                              ? SmartImage(
                                  source: store.logoPath,
                                  fit: BoxFit.cover,
                                  fallback: Center(
                                    child: Text(
                                      _initials(store.storeName),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: accentGreen,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _initials(store.storeName),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: accentGreen,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    store.storeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                                  ),
                                ),
                                if (store.isApproved) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: accentGreen,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 1, thickness: 1, color: borderColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 13,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            store.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                      Flexible(
                        child: Text(
                          metricRight,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: accentGreen,
                          ),
                        ),
                      ),
                    ],
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

class _FilterSheetChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterSheetChoiceChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor:
          isDark ? AppColors.primaryLight : AppColors.forestGreen,
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFE9F4EC),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected
            ? (isDark ? Colors.black : Colors.white)
            : (isDark ? AppColors.textPrimaryDark : AppColors.neutralDark),
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      showCheckmark: false,
    );
  }
}
