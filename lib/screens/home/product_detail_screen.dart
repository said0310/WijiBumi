import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/cart_icon_button.dart';
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

  void _openStore() {
    final stores = context.read<StoreProvider>().stores;
    final store = stores.firstWhere(
      (s) => s.id == widget.product.storeId,
      orElse: () => stores.first,
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailScreen(store: store)));
  }

  void _addToCart({bool checkout = false}) {
    context.read<CartProvider>().addToCart(widget.product, quantity: _quantity);
    if (checkout) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_quantity ${widget.product.unit} ${widget.product.name} dimasukkan ke keranjang!'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final product = widget.product;
    final inStock = product.stock > 0;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        actions: const [CartIconButton(), SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image & Grade Badge
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Image.network(
                    product.images.isNotEmpty ? product.images[_selectedImageIndex] : product.primaryImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.eco, size: 80, color: Colors.grey),
                    ),
                  ),
                ),
                if (product.qualityGrade != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.forGrade(product.qualityGrade),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Grade ${product.qualityGrade}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final isSelected = index == _selectedImageIndex;
                    return InkWell(
                      onTap: () => setState(() => _selectedImageIndex = index),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? primaryColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(product.images[index], fit: BoxFit.cover),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CurrencyFormatter.format(product.price),
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: primaryColor),
                          ),
                          Text(
                            'per ${product.unit}',
                            style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (inStock ? AppColors.success : AppColors.error).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(inStock ? Icons.check_circle : Icons.cancel, size: 14, color: inStock ? AppColors.success : AppColors.error),
                            const SizedBox(width: 6),
                            Text(
                              inStock ? 'Stok: ${product.stock} ${product.unit}' : 'Stok Habis',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: inStock ? AppColors.success : AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Product Title
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Specifications Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.primary.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Informasi Agriteknologi & Panen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        _specRow(Icons.calendar_today, 'Tanggal Panen', product.harvestDate != null ? DateFormatter.formatShort(product.harvestDate!) : 'Panen Segar Harian'),
                        const SizedBox(height: 8),
                        _specRow(Icons.timer, 'Daya Tahan Produk', product.shelfLifeDays != null ? '${product.shelfLifeDays} Hari (Suhu Ruang/Dingin)' : '5-7 Hari'),
                        const SizedBox(height: 8),
                        _specRow(Icons.place, 'Lokasi Kebun', product.farmLocation ?? 'Kebun Mitra TaniHub'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Description
                  const Text('Deskripsi Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    product.description ?? 'Tidak ada deskripsi produk.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Seller Profile Card
                  InkWell(
                    onTap: _openStore,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: Image.network(
                                product.storeLogo ?? 'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&w=300&q=80',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.storefront, size: 30),
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
                                        product.storeName ?? 'Kebun Mitra',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.verified, size: 16, color: AppColors.primary),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.storeCity ?? 'Indonesia',
                                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _openStore,
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero),
                            child: const Text('Kunjungi Toko', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jumlah Pembelian', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            ),
                            Text('$_quantity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: _quantity < product.stock ? () => setState(() => _quantity++) : null,
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
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            // Chat Button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_outlined),
                color: primaryColor,
                tooltip: 'Chat Penjual',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(
                      storeId: product.storeId,
                      productId: product.id,
                      title: product.storeName ?? 'Chat Penjual',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Add to Cart Button
            Expanded(
              child: CustomButton(
                text: '+ Keranjang',
                isOutlined: true,
                onPressed: inStock ? () => _addToCart() : null,
              ),
            ),
            const SizedBox(width: 8),

            // Buy Now Button
            Expanded(
              child: CustomButton(
                text: 'Beli Sekarang',
                onPressed: inStock ? () => _addToCart(checkout: true) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
