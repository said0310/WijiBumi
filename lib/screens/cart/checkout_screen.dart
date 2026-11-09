import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/address.dart';
import '../../services/supabase_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../orders/orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Address? _selectedAddress;
  List<Address> _addresses = [];
  bool _isLoading = true;
  bool _isPlacingOrder = false;

  String _selectedPayment = 'BCA Virtual Account';
  final List<String> _paymentMethods = [
    'BCA Virtual Account',
    'Mandiri Virtual Account',
    'BRI Virtual Account',
    'GoPay',
    'OVO',
    'DANA',
    'COD (Bayar di Tempat)',
  ];

  String _selectedCourier = 'J&T Express Cargo Tani';
  final List<String> _couriers = [
    'J&T Express Cargo Tani',
    'SiCepat Cargo Fresh',
    'AnterAja Sameday',
  ];

  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final addrs = await SupabaseService.instance.getAddresses();
    setState(() {
      _addresses = addrs;
      if (addrs.isNotEmpty) {
        _selectedAddress = addrs.firstWhere((a) => a.isDefault, orElse: () => addrs.first);
      }
      _isLoading = false;
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

    final storeGroups = cartProvider.itemsByStore;
    final int storeCount = storeGroups.length;
    const double shippingFeePerStore = 15000.0;
    final double totalShippingFee = shippingFeePerStore * storeCount;
    final double grandTotal = cartProvider.totalAmount + totalShippingFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Pembelian'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shipping Address Section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.location_on, color: AppColors.secondary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Alamat Pengiriman',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            if (_addresses.length > 1)
                              TextButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (ctx) => ListView(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.all(16),
                                      children: [
                                        const Text(
                                          'Pilih Alamat Pengiriman',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 12),
                                        ..._addresses.map((a) => ListTile(
                                              title: Text('${a.label}: ${a.recipientName}'),
                                              subtitle: Text(a.fullAddressText),
                                              trailing: _selectedAddress?.id == a.id
                                                  ? const Icon(Icons.check, color: AppColors.primary)
                                                  : null,
                                              onTap: () {
                                                setState(() => _selectedAddress = a);
                                                Navigator.pop(ctx);
                                              },
                                            )),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('Ganti', style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_selectedAddress != null) ...[
                          Text(
                            '${_selectedAddress!.recipientName} (${_selectedAddress!.phone})',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedAddress!.fullAddressText,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'Belum ada alamat pengiriman terpilih.',
                            style: TextStyle(fontSize: 12, color: AppColors.error),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Orders Breakdown by Store
                  const Text(
                    'Daftar Pesanan per Toko',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pesanan akan diproses secara terpisah oleh masing-masing toko mitra.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...storeGroups.entries.map((entry) {
                    final storeName = entry.key;
                    final items = entry.value;
                    final subtotalThisStore = items.fold(0.0, (sum, i) => sum + i.totalPrice);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                storeName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          ...items.map((ci) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${ci.quantity}x ${ci.product?.name ?? ''}',
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(ci.totalPrice),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ongkir Khusus Segar:', style: TextStyle(fontSize: 12)),
                              Text(
                                CurrencyFormatter.format(shippingFeePerStore),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal Toko:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(
                                CurrencyFormatter.format(subtotalThisStore + shippingFeePerStore),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 12),

                  // Courier Selection
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih Layanan Kurir Pengiriman',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        ..._couriers.map((c) {
                          return RadioListTile<String>(
                            value: c,
                            groupValue: _selectedCourier,
                            contentPadding: EdgeInsets.zero,
                            title: Text(c, style: const TextStyle(fontSize: 13)),
                            subtitle: const Text('Spesialis produk segar berpendingin', style: TextStyle(fontSize: 11)),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCourier = val);
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Method
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Metode Pembayaran',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        ..._paymentMethods.map((pm) {
                          return RadioListTile<String>(
                            value: pm,
                            groupValue: _selectedPayment,
                            contentPadding: EdgeInsets.zero,
                            title: Text(pm, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPayment = val);
                            },
                          );
                        }).toList(),
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
                      hintText: 'Contoh: Titip di pos satpam jika tidak ada orang',
                      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey[50],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Harga Produk:', style: TextStyle(fontSize: 13)),
                            Text(CurrencyFormatter.format(cartProvider.totalAmount), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ongkos Kirim ($storeCount Toko):', style: const TextStyle(fontSize: 13)),
                            Text(CurrencyFormatter.format(totalShippingFee), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Tagihan:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            Text(
                              CurrencyFormatter.format(grandTotal),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.primaryLight : AppColors.primary,
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
      bottomSheet: Container(
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
          onPressed: _selectedAddress == null || _isPlacingOrder
              ? null
              : () async {
                  setState(() => _isPlacingOrder = true);
                  final orders = await context.read<OrderProvider>().checkout(
                        address: _selectedAddress!,
                        paymentMethod: _selectedPayment,
                        courierName: _selectedCourier,
                        buyerNote: _noteController.text.trim().isNotEmpty
                            ? _noteController.text.trim()
                            : null,
                      );
                  setState(() => _isPlacingOrder = false);

                  if (context.mounted && orders.isNotEmpty) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success),
                            SizedBox(width: 8),
                            Text('Pesanan Dibuat!'),
                          ],
                        ),
                        content: Text(
                          'Berhasil membuat ${orders.length} pesanan toko. Silakan selesaikan pembayaran dan pantau status pengiriman.',
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx); // Close dialog
                              Navigator.pop(context); // Close checkout
                              // Navigate to Orders
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const OrdersScreen()),
                              );
                            },
                            child: const Text('Lihat Pesanan Saya'),
                          ),
                        ],
                      ),
                    );
                  }
                },
        ),
      ),
    );
  }
}
