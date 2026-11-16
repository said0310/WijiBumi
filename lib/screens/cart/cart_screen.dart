import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/lucide_icons.dart';
import '../../widgets/smart_image.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _mutatingItemIds = {};
  bool _isBulkMutating = false;

  Future<void> _runItemMutation(
    String itemId,
    Future<bool> Function(CartProvider provider) action,
  ) async {
    if (_isBulkMutating || _mutatingItemIds.contains(itemId)) return;
    setState(() => _mutatingItemIds.add(itemId));
    final cartProvider = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await action(cartProvider);
      if (!mounted) return;
      if (!ok && cartProvider.lastError != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(cartProvider.lastError!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _mutatingItemIds.remove(itemId));
      }
    }
  }

  Future<void> _runBulkMutation(
    Future<bool> Function(CartProvider provider) action, {
    String? successMessage,
  }) async {
    if (_isBulkMutating) return;
    setState(() => _isBulkMutating = true);
    final cartProvider = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await action(cartProvider);
      if (!mounted) return;
      if (ok) {
        if (successMessage != null) {
          messenger.showSnackBar(SnackBar(content: Text(successMessage)));
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              cartProvider.lastError ?? 'Gagal memperbarui keranjang.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBulkMutating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartProvider = context.watch<CartProvider>();
    final unavailableItems = cartProvider.unavailableItems;
    final hasBlockers =
        cartProvider.hasUnavailableItems || cartProvider.hasOverStockItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
        actions: [
          if (cartProvider.items.isNotEmpty)
            TextButton(
              onPressed: _isBulkMutating
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Kosongkan Keranjang?'),
                          content: const Text(
                            'Apakah Anda yakin ingin menghapus semua produk dari keranjang?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _runBulkMutation((p) => p.clear());
                              },
                              child: const Text(
                                'Kosongkan',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
              child: const Text(
                'Kosongkan',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: cartProvider.isLoading && cartProvider.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cartProvider.items.isEmpty
              ? EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  iconBuilder: (color, size) =>
                      LucideShoppingCartIcon(size: size, color: color),
                  title: 'Keranjang Masih Kosong',
                  message:
                      'Ayo cari bunga, sayuran, dan buah segar untuk kebutuhan harian Anda!',
                  buttonText: 'Mulai Belanja',
                  onButtonPressed: () => Navigator.pop(context),
                )
              : RefreshIndicator(
                  onRefresh: () => cartProvider.loadCart(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      if (unavailableItems.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Produk Tidak Tersedia',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isBulkMutating
                                        ? null
                                        : () => _runBulkMutation(
                                              (p) => p.removeUnavailableItems(),
                                              successMessage:
                                                  'Produk tidak tersedia telah dihapus.',
                                            ),
                                    child: const Text(
                                      'Hapus Semua',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'Produk atau toko berikut sedang nonaktif/habis. Hapus sebelum melanjutkan checkout.',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              ...unavailableItems.map((ci) {
                                final busy =
                                    _isBulkMutating ||
                                    _mutatingItemIds.contains(ci.id);
                                final name = ci.product?.name ??
                                    'Produk sudah tidak tersedia';
                                final reason = ci.product == null
                                    ? 'Produk dinonaktifkan atau toko tidak aktif'
                                    : (ci.product!.stock <= 0
                                        ? 'Stok habis'
                                        : 'Produk sedang dinonaktifkan penjual');
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$name (${ci.quantity} item)',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              reason,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? AppColors.textMutedDark
                                                    : AppColors.textMutedLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: busy
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                                color: AppColors.error,
                                              ),
                                        tooltip: 'Hapus item',
                                        onPressed: busy
                                            ? null
                                            : () => _runItemMutation(
                                                  ci.id,
                                                  (p) => p.removeItem(ci.id),
                                                ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ...cartProvider.itemsByStoreId.entries.map((entry) {
                        final items = entry.value;
                        final storeName =
                            items.first.product?.storeName ?? 'Toko Mitra';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.storefront,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        storeName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              ...items.map((cartItem) {
                                final product = cartItem.product!;
                                final busy = _isBulkMutating ||
                                    _mutatingItemIds.contains(cartItem.id);
                                final isOverStock =
                                    cartItem.quantity > product.stock;

                                return Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                          width: 65,
                                          height: 65,
                                          child: SmartImage(
                                            source: product.primaryImage,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${CurrencyFormatter.format(product.price)} / ${product.unit}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? AppColors.primaryLight
                                                    : AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (isOverStock) ...[
                                              const SizedBox(height: 4),
                                              Wrap(
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                spacing: 8,
                                                children: [
                                                  Text(
                                                    'Melebihi stok (tersisa ${product.stock})',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.error,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: busy
                                                        ? null
                                                        : () => _runItemMutation(
                                                              cartItem.id,
                                                              (p) => p
                                                                  .updateQuantity(
                                                                cartItem.id,
                                                                product.stock,
                                                              ),
                                                            ),
                                                    child: const Text(
                                                      'Sesuaikan',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                        color: isDark
                                                            ? AppColors
                                                                .borderDark
                                                            : AppColors
                                                                .borderLight,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        InkWell(
                                                          onTap: busy
                                                              ? null
                                                              : () =>
                                                                  _runItemMutation(
                                                                    cartItem.id,
                                                                    (p) => p
                                                                        .updateQuantity(
                                                                      cartItem
                                                                          .id,
                                                                      cartItem
                                                                              .quantity -
                                                                          1,
                                                                    ),
                                                                  ),
                                                          child: const Padding(
                                                            padding:
                                                                EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            child: Icon(
                                                              Icons.remove,
                                                              size: 14,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '${cartItem.quantity}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        InkWell(
                                                          onTap: busy
                                                              ? null
                                                              : () {
                                                                  if (cartItem
                                                                          .quantity <
                                                                      product
                                                                          .stock) {
                                                                    _runItemMutation(
                                                                      cartItem
                                                                          .id,
                                                                      (p) => p
                                                                          .updateQuantity(
                                                                        cartItem
                                                                            .id,
                                                                        cartItem.quantity +
                                                                            1,
                                                                      ),
                                                                    );
                                                                  } else {
                                                                    ScaffoldMessenger
                                                                            .of(
                                                                                context)
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text(
                                                                          'Maksimal stok ${product.name} (${product.stock} ${product.unit})',
                                                                        ),
                                                                        duration:
                                                                            const Duration(
                                                                          seconds:
                                                                              1,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                },
                                                          child: const Padding(
                                                            padding:
                                                                EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            child: Icon(
                                                              Icons.add,
                                                              size: 14,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: busy
                                                      ? const SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.delete_outline,
                                                          size: 20,
                                                          color:
                                                              AppColors.error,
                                                        ),
                                                  onPressed: busy
                                                      ? null
                                                      : () => _runItemMutation(
                                                            cartItem.id,
                                                            (p) => p.removeItem(
                                                                cartItem.id),
                                                          ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
      bottomNavigationBar: cartProvider.items.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasBlockers) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          cartProvider.hasUnavailableItems
                              ? 'Hapus produk yang tidak tersedia sebelum checkout.'
                              : 'Sesuaikan jumlah produk yang melebihi stok terlebih dahulu.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Pembayaran',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMutedLight,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(
                                  cartProvider.totalAmount,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        CustomButton(
                          text: 'Checkout (${cartProvider.itemCount})',
                          onPressed: !cartProvider.canCheckout ||
                                  _isBulkMutating ||
                                  _mutatingItemIds.isNotEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CheckoutScreen(),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
