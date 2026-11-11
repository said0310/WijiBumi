import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../models/store.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import '../../services/supabase_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/lucide_icons.dart';
import '../../widgets/review_list_card.dart';
import '../../widgets/smart_image.dart';
import '../auth/login_screen.dart';
import '../cart/cart_screen.dart';
import '../cart/checkout_screen.dart';
import '../chat/chat_room_screen.dart';
import '../store/store_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  int _quantity = 1;
  late Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = SupabaseService.instance
        .getProductReviews(widget.product.id)
        .catchError((_) => <Review>[]);
  }

  Future<bool> _ensureAuthenticated() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      await authProvider.loadUser();
      if (!mounted) return false;
    }
    if (authProvider.isAuthenticated) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Silakan masuk ke akun WijiBumi terlebih dahulu.'),
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final product = widget.product;
    final cartCount = context.watch<CartProvider>().itemCount;
    final linkedStore = context
        .watch<StoreProvider>()
        .stores
        .where((s) => s.id == product.storeId)
        .firstOrNull;
    final isStoreVerified = linkedStore?.isApproved ?? false;

    Color gradeColor = AppColors.gradeA;
    if (product.qualityGrade == 'B') gradeColor = AppColors.gradeB;
    if (product.qualityGrade == 'C') gradeColor = AppColors.gradeC;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: LucideShoppingCartIcon(
                  size: 28,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                tooltip: 'Keranjang',
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  if (!await _ensureAuthenticated() || !mounted) return;
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
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Image Carousel / Hero Image
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: SmartImage(
                    source: product.images.isNotEmpty
                        ? product.images[_selectedImageIndex]
                        : product.primaryImage,
                    fit: BoxFit.cover,
                  ),
                ),
                if (product.qualityGrade != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: gradeColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Grade ${product.qualityGrade}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Thumbnail Images
            if (product.images.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: product.images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedImageIndex;
                    return InkWell(
                      onTap: () => setState(() => _selectedImageIndex = index),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SmartImage(
                            source: product.images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price & Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CurrencyFormatter.format(product.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                              ),
                            ),
                            Text(
                              'per ${product.unit}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (product.stock > 0
                                    ? AppColors.success
                                    : AppColors.error)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                product.stock > 0
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 14,
                                color: product.stock > 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  product.stock > 0
                                      ? 'Stok: ${product.stock} ${product.unit}'
                                      : 'Stok Habis',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: product.stock > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Product Title
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Terjual ${product.totalSales}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Farm & Agritech Specifications Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Agriteknologi & Panen',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        _buildSpecRow(
                          icon: Icons.calendar_today,
                          label: 'Tanggal Panen',
                          value: product.harvestDate != null
                              ? DateFormatter.formatShort(product.harvestDate!)
                              : 'Panen Segar Harian',
                        ),
                        const SizedBox(height: 8),
                        _buildSpecRow(
                          icon: Icons.timer,
                          label: 'Daya Tahan Produk',
                          value: product.shelfLifeDays != null
                              ? '${product.shelfLifeDays} Hari (Suhu Ruang/Dingin)'
                              : '5-7 Hari',
                        ),
                        const SizedBox(height: 8),
                        _buildSpecRow(
                          icon: Icons.place,
                          label: 'Lokasi Kebun',
                          value: product.farmLocation ?? 'Kebun Mitra WijiBumi',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Description
                  const Text(
                    'Deskripsi Produk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description ?? 'Tidak ada deskripsi produk.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Seller Profile Card (Clicking navigates to Store Detail Screen)
                  InkWell(
                    onTap: () => _openStore(context, product.storeId),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 380;
                          final storeInfoRow = Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: SmartImage(
                                    source: product.storeLogo ??
                                        'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&w=300&q=80',
                                    fit: BoxFit.cover,
                                    fallback: const Icon(Icons.storefront, size: 30),
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
                                        Flexible(
                                          child: Text(
                                            product.storeName ?? 'Kebun Mitra',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isStoreVerified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.verified,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product.storeCity ?? 'Indonesia',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textMutedDark
                                            : AppColors.textMutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isCompact) ...[
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _openStore(context, product.storeId),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text(
                                    'Kunjungi Toko',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          );
                          if (!isCompact) return storeInfoRow;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              storeInfoRow,
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () => _openStore(context, product.storeId),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 36),
                                ),
                                child: const Text(
                                  'Kunjungi Toko',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Buyer Reviews Section
                  _buildProductReviewsSection(isDark),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Jumlah Pembelian',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: product.stock > 0 && _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Text(
                              '${product.stock > 0 ? _quantity : 0}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: product.stock > 0 && _quantity < product.stock
                                  ? () => setState(() => _quantity++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Chat Button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: LucideMessageCircleIcon(
                    size: 22,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                  tooltip: 'Chat Penjual',
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    if (!await _ensureAuthenticated() || !mounted) return;
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          storeId: product.storeId,
                          productId: product.id,
                          title: product.storeName ?? 'Chat Penjual',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Add to Cart Button
              Expanded(
                flex: 1,
                child: CustomButton(
                  text: '+ Keranjang',
                  isOutlined: true,
                  onPressed: product.isAvailable
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final cartProv = context.read<CartProvider>();
                          if (!await _ensureAuthenticated() || !mounted) return;
                          final ok = await cartProv.addToCart(
                            product,
                            quantity: _quantity,
                          );
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? '$_quantity ${product.unit} ${product.name} dimasukkan ke keranjang!'
                                    : (cartProv.lastError ??
                                        'Gagal menambahkan ke keranjang.'),
                              ),
                              backgroundColor: ok ? null : AppColors.warning,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 8),

              // Buy Now Button (direct single-item checkout without touching cart)
              Expanded(
                flex: 1,
                child: CustomButton(
                  text: 'Beli Sekarang',
                  onPressed: product.isAvailable
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          if (!await _ensureAuthenticated() || !mounted) return;
                          if (_quantity <= 0 || _quantity > product.stock) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Jumlah melebihi stok tersedia (${product.stock} ${product.unit}).',
                                ),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }
                          navigator.push(
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(
                                directProduct: product,
                                directQuantity: _quantity,
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context, String storeId) async {
    final storeProvider = context.read<StoreProvider>();
    final messenger = ScaffoldMessenger.of(context);
    Store? store =
        storeProvider.stores.where((s) => s.id == storeId).firstOrNull;
    if (store == null) {
      try {
        store = await SupabaseService.instance.getStoreById(storeId);
      } catch (e) {
        debugPrint('Error opening store $storeId: $e');
      }
    }
    if (!context.mounted) return;
    if (store == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Informasi toko saat ini tidak tersedia.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoreDetailScreen(store: store!)),
    );
  }

  Widget _buildProductReviewsSection(bool isDark) {
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return FutureBuilder<List<Review>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ulasan Pembeli',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          );
        }

        final reviews = snapshot.data ?? const <Review>[];
        final avgRating = reviews.isNotEmpty
            ? reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length
            : widget.product.rating;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ulasan Pembeli',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                if (reviews.isNotEmpty) ...[
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${avgRating.toStringAsFixed(1)} (${reviews.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (reviews.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  'Belum ada ulasan pembeli untuk produk ini.',
                  style: TextStyle(fontSize: 12.5, color: mutedColor),
                ),
              )
            else ...[
              ...reviews.take(3).map(
                    (review) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BuyerReviewTileCard(
                        review: review,
                        showProductName: false,
                      ),
                    ),
                  ),
              if (reviews.length > 3)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showAllProductReviewsSheet(reviews),
                    child: Text('Lihat Semua Ulasan (${reviews.length})'),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  void _showAllProductReviewsSheet(List<Review> reviews) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Text(
              'Semua Ulasan (${reviews.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, idx) => BuyerReviewTileCard(
                  review: reviews[idx],
                  showProductName: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
