import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/store_provider.dart';
import '../../models/address.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_widgets.dart';
import '../orders/orders_screen.dart';
import '../profile/add_edit_address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Product? directProduct;
  final int directQuantity;

  const CheckoutScreen({
    super.key,
    this.directProduct,
    this.directQuantity = 1,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Address? _selectedAddress;
  bool _isPlacingOrder = false;

  String _selectedPayment = 'BCA Virtual Account';
  final List<String> _paymentMethods = const [
    'BCA Virtual Account',
    'Mandiri Virtual Account',
    'BRI Virtual Account',
    'GoPay',
    'OVO',
    'DANA',
    'COD (Bayar di Tempat)',
  ];

  String _selectedCourier = AppConstants.availableCouriers.first;
  final List<String> _couriers = AppConstants.availableCouriers;

  final TextEditingController _noteController = TextEditingController();

  bool get _isDirectBuy => widget.directProduct != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().loadAddresses();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartProvider = context.watch<CartProvider>();
    final addressProvider = context.watch<AddressProvider>();

    final addresses = addressProvider.addresses;
    final effectiveAddress = _selectedAddress ?? addressProvider.defaultAddress;

    final Map<String, List<CartItem>> storeGroups;
    final double productsSubtotal;
    if (_isDirectBuy) {
      final p = widget.directProduct!;
      final now = DateTime.now();
      storeGroups = {
        p.storeId: [
          CartItem(
            id: 'direct-${p.id}',
            userId: '',
            productId: p.id,
            quantity: widget.directQuantity,
            createdAt: now,
            updatedAt: now,
            product: p,
          ),
        ],
      };
      productsSubtotal = p.price * widget.directQuantity;
    } else {
      storeGroups = cartProvider.itemsByStoreId;
      productsSubtotal = cartProvider.totalAmount;
    }

    final int storeCount = storeGroups.length;
    final double shippingFeePerStore =
        AppConstants.getCourierShippingFee(_selectedCourier);
    final double totalShippingFee = shippingFeePerStore * storeCount;
    final double grandTotal = productsSubtotal + totalShippingFee;

    final bool hasBlockedCartItems = !_isDirectBuy &&
        (cartProvider.hasUnavailableItems || cartProvider.hasOverStockItems);
    final bool hasNoCheckoutItems = storeGroups.isEmpty ||
        (_isDirectBuy &&
            (!widget.directProduct!.isAvailable ||
                widget.directQuantity <= 0 ||
                widget.directQuantity > widget.directProduct!.stock));
    final bool canSubmitOrder = effectiveAddress != null &&
        !_isPlacingOrder &&
        !hasNoCheckoutItems &&
        !hasBlockedCartItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Pembelian'),
      ),
      body: addressProvider.isLoading && addresses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasBlockedCartItems) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  cartProvider.hasUnavailableItems
                                      ? 'Ada produk tidak tersedia di keranjang. Kembali ke keranjang dan hapus produk tersebut sebelum checkout.'
                                      : 'Ada produk di keranjang yang jumlahnya melebihi stok. Kembali ke keranjang untuk menyesuaikan.',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Shipping Address Section
                      GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: AppColors.secondary,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Alamat Pengiriman',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Wrap(
                                  spacing: 2,
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        final created =
                                            await Navigator.push<Address?>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const AddEditAddressScreen(),
                                          ),
                                        );
                                        if (created != null && mounted) {
                                          setState(
                                            () => _selectedAddress = created,
                                          );
                                        }
                                      },
                                      child: const Text(
                                        '+ Alamat',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    if (addresses.length > 1)
                                      TextButton(
                                        onPressed: () {
                                          showGlassBottomSheet(
                                            context,
                                            builder: (ctx) => ListView(
                                              shrinkWrap: true,
                                              padding: const EdgeInsets.all(16),
                                              children: [
                                                const Text(
                                                  'Pilih Alamat Pengiriman',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                ...addresses.map(
                                                  (a) => ListTile(
                                                    title: Text(
                                                      '${a.label}: ${a.recipientName}',
                                                    ),
                                                    subtitle: Text(
                                                      a.fullAddressText,
                                                    ),
                                                    trailing:
                                                        effectiveAddress?.id ==
                                                                a.id
                                                            ? const Icon(
                                                                Icons.check,
                                                                color: AppColors
                                                                    .primary,
                                                              )
                                                            : null,
                                                    onTap: () {
                                                      setState(
                                                        () => _selectedAddress =
                                                            a,
                                                      );
                                                      Navigator.pop(ctx);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Ganti',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (effectiveAddress != null) ...[
                              Text(
                                '${effectiveAddress.recipientName} (${effectiveAddress.phone})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                effectiveAddress.fullAddressText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ] else ...[
                              const Text(
                                'Belum ada alamat pengiriman. Tambahkan alamat terlebih dahulu.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Daftar Pesanan per Toko',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pesanan akan diproses secara terpisah oleh masing-masing toko mitra.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...storeGroups.entries.map((entry) {
                        final items = entry.value;
                        final storeName =
                            items.first.product?.storeName ?? 'Toko Mitra';
                        final subtotalThisStore = items.fold(
                          0.0,
                          (sum, i) => sum + i.totalPrice,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.storefront,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      storeName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              ...items.map(
                                (ci) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${ci.quantity}x ${ci.product?.name ?? 'Produk tidak tersedia'}',
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        CurrencyFormatter.format(ci.totalPrice),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Ongkir Khusus Segar:',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    CurrencyFormatter.format(
                                      shippingFeePerStore,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Subtotal Toko:',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    CurrencyFormatter.format(
                                      subtotalThisStore + shippingFeePerStore,
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.primaryLight
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),

                      // Courier Selection
                      GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pilih Layanan Kurir Pengiriman',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            RadioGroup<String>(
                              groupValue: _selectedCourier,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCourier = val);
                                }
                              },
                              child: Column(
                                children: _couriers.map((c) {
                                  final fee =
                                      AppConstants.getCourierShippingFee(c);
                                  final service =
                                      AppConstants.getCourierServiceName(c);
                                  return RadioListTile<String>(
                                    value: c,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      c,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      '$service • ${CurrencyFormatter.format(fee)} / toko',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Payment Method
                      GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Metode Pembayaran',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            RadioGroup<String>(
                              groupValue: _selectedPayment,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedPayment = val);
                                }
                              },
                              child: Column(
                                children: _paymentMethods
                                    .map(
                                      (pm) => RadioListTile<String>(
                                        value: pm,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          pm,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Buyer Note
                      TextField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Catatan untuk Penjual (Opsional)',
                          hintText:
                              'Contoh: Titip di pos satpam jika tidak ada orang',
                          fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Payment Summary
                      GlassContainer(
                        borderRadius: 14,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Total Harga Produk:',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.format(productsSubtotal),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Ongkos Kirim ($storeCount Toko):',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.format(totalShippingFee),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Total Tagihan:',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.format(grandTotal),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: CustomButton(
            text: 'Buat Pesanan (${CurrencyFormatter.format(grandTotal)})',
            isLoading: _isPlacingOrder,
            width: double.infinity,
            onPressed: !canSubmitOrder
                ? null
                : () async {
                    final orderProv = context.read<OrderProvider>();
                    final cartProv = context.read<CartProvider>();
                    final productProv = context.read<ProductProvider>();
                    final storeProv = context.read<StoreProvider>();
                    final notifProv = context.read<NotificationProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    setState(() => _isPlacingOrder = true);
                    List orders = [];
                    try {
                      final noteText = _noteController.text.trim();
                      final note = noteText.isNotEmpty ? noteText : null;
                      if (_isDirectBuy) {
                        orders = await orderProv.directCheckout(
                          address: effectiveAddress,
                          product: widget.directProduct!,
                          quantity: widget.directQuantity,
                          paymentMethod: _selectedPayment,
                          courierName: _selectedCourier,
                          buyerNote: note,
                        );
                      } else {
                        orders = await orderProv.checkout(
                          address: effectiveAddress,
                          paymentMethod: _selectedPayment,
                          courierName: _selectedCourier,
                          buyerNote: note,
                        );
                      }
                      if (orders.isNotEmpty) {
                        try {
                          await Future.wait([
                            if (!_isDirectBuy) cartProv.loadCart(),
                            productProv.fetchProducts(),
                            if (storeProv.hasStore) storeProv.loadMyStoreData(),
                            notifProv.loadNotifications(),
                          ]);
                        } catch (_) {
                          // Secondary provider refresh errors should not mask created orders
                        }
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isPlacingOrder = false);
                      }
                    }
                    if (!mounted) return;

                    if (orders.isNotEmpty) {
                      showDialog(
                        context: this.context,
                        barrierDismissible: false,
                        builder: (ctx) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 8),
                              Flexible(child: Text('Pesanan Dibuat!')),
                            ],
                          ),
                          content: SingleChildScrollView(
                            child: Text(
                              'Berhasil membuat ${orders.length} pesanan toko. Silakan selesaikan pembayaran dan pantau status pengiriman.',
                            ),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                navigator.popUntil((route) => route.isFirst);
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => const OrdersScreen(),
                                  ),
                                );
                              },
                              child: const Text('Lihat Pesanan Saya'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            orderProv.lastError ??
                                'Gagal membuat pesanan. Periksa stok produk dan koneksi.',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
          ),
        ),
      ),
    );
  }
}
