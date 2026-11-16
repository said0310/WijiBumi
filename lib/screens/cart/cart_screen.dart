import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _confirmClear(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Keranjang?'),
        content: const Text('Apakah Anda yakin ingin menghapus semua produk dari keranjang?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Kosongkan', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, cart),
              child: const Text('Kosongkan', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Keranjang Masih Kosong',
              message: 'Ayo cari bunga, sayuran, dan buah segar untuk kebutuhan harian Anda!',
              buttonText: 'Mulai Belanja',
              onButtonPressed: () => Navigator.pop(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                for (final entry in cart.itemsByStore.entries)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Header
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.storefront, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(entry.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Store Items
                        for (final item in entry.value)
                          if (item.product != null)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 65,
                                      height: 65,
                                      child: Image.network(item.product!.primaryImage, fit: BoxFit.cover),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product!.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${CurrencyFormatter.format(item.product!.price)} / ${item.product!.unit}',
                                          style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Quantity Controls
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: borderColor),
                                              ),
                                              child: Row(
                                                children: [
                                                  InkWell(
                                                    onTap: () => cart.updateQuantity(item.id, item.quantity - 1),
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      child: Icon(Icons.remove, size: 14),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${item.quantity}',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                  InkWell(
                                                    onTap: item.quantity < item.product!.stock
                                                        ? () => cart.updateQuantity(item.id, item.quantity + 1)
                                                        : null,
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      child: Icon(Icons.add, size: 14),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                              onPressed: () => cart.removeItem(item.id),
                                            ),
                                          ],
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
              ],
            ),
      bottomSheet: cart.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
                        Text(
                          CurrencyFormatter.format(cart.totalAmount),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                  CustomButton(
                    text: 'Checkout (${cart.itemCount})',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
