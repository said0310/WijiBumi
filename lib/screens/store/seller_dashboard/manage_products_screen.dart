import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../models/product.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../widgets/smart_image.dart';
import 'add_edit_product_screen.dart';
import 'seller_ui_components.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  final List<String> _categories = [
    'Semua',
    ...AppConstants.productCategories,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = SellerThemeTokens(isDark);
    final storeProvider = context.watch<StoreProvider>();
    final isStoreApproved = storeProvider.myStore?.isApproved ?? false;

    final allProducts = storeProvider.myStoreProducts;
    final filteredProducts = allProducts.where((p) {
      if (_selectedCategory != 'Semua') {
        final cat = p.categoryName ?? '';
        if (cat.toLowerCase() != _selectedCategory.toLowerCase()) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            (p.farmLocation?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: tokens.pageBg,
      appBar: AppBar(
        backgroundColor: tokens.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Text(
          'Manajemen Produk',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: tokens.accentGreen,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: tokens.accentGreen,
            ),
            tooltip: 'Tambah Produk',
            onPressed: () => _openAddProduct(context, isStoreApproved),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: tokens.borderColor),
        ),
      ),
      body: Column(
        children: [
          if (!isStoreApproved)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.warning.withValues(alpha: 0.14)
                    : const Color(0xFFFFFAEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.45),
                ),
              ),
              child: const Text(
                'Toko sedang menunggu verifikasi. Penjualan & penambahan produk baru dikunci sampai toko diverifikasi.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(fontSize: 13.5, color: tokens.titleColor),
              decoration: InputDecoration(
                hintText: 'Cari nama produk atau lokasi kebun...',
                hintStyle: TextStyle(fontSize: 13, color: tokens.mutedTextColor),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: tokens.mutedTextColor,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: tokens.cardBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: tokens.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: tokens.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: tokens.accentGreen, width: 1.4),
                ),
              ),
            ),
          ),

          // Category Filter Chips
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_categories.length, (index) {
                  final cat = _categories[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == _categories.length - 1 ? 0 : 8,
                    ),
                    child: SellerPillChip(
                      label: cat,
                      selected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                  );
                }),
              ),
            ),
          ),

          Expanded(
            child: filteredProducts.isEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 780),
                        child: SellerCardSurface(
                          borderRadius: 22,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: allProducts.isEmpty
                                ? 'Belum Ada Produk'
                                : 'Produk Tidak Ditemukan',
                            message: allProducts.isEmpty
                                ? 'Tambahkan produk bunga, sayuran, atau buah-buahan dari kebun Anda.'
                                : 'Coba ubah kata kunci pencarian atau pilih kategori lain.',
                            buttonText: allProducts.isEmpty && isStoreApproved
                                ? '+ Tambah Produk Pertama'
                                : null,
                            onButtonPressed:
                                allProducts.isEmpty && isStoreApproved
                                    ? () =>
                                        _openAddProduct(context, isStoreApproved)
                                    : null,
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      6,
                      16,
                      88 + MediaQuery.paddingOf(context).bottom,
                    ),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 780),
                          child: SellerCardSurface(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 68,
                                    height: 68,
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: tokens.titleColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Switch(
                                            value: product.status == 'active',
                                            activeThumbColor: Colors.white,
                                            activeTrackColor:
                                                AppColors.primary,
                                            inactiveThumbColor: Colors.white,
                                            inactiveTrackColor:
                                                const Color(0xFFD5DED7),
                                            trackOutlineColor:
                                                WidgetStateProperty.all(
                                              Colors.transparent,
                                            ),
                                            onChanged: (val) async {
                                              if (val && !isStoreApproved) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Toko harus terverifikasi sebelum mengaktifkan produk.',
                                                    ),
                                                    backgroundColor:
                                                        AppColors.warning,
                                                  ),
                                                );
                                                return;
                                              }
                                              final updated = product.copyWith(
                                                status:
                                                    val ? 'active' : 'inactive',
                                              );
                                              final ok = await storeProvider
                                                  .updateProduct(updated);
                                              if (context.mounted) {
                                                if (ok) {
                                                  await context
                                                      .read<ProductProvider>()
                                                      .fetchProducts();
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Gagal mengubah status produk.',
                                                      ),
                                                      backgroundColor:
                                                          AppColors.error,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${CurrencyFormatter.format(product.price)} / ${product.unit}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: tokens.accentGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          if (product.categoryName != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: tokens.softMintBg,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                product.categoryName!,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: tokens.accentGreen,
                                                ),
                                              ),
                                            ),
                                          if (product.qualityGrade != null)
                                            Text(
                                              'Grade ${product.qualityGrade}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: tokens.mutedTextColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    'Stok: ${product.stock}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: product.stock <= 5
                                                          ? AppColors.error
                                                          : tokens.titleColor,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit_note,
                                                    size: 18,
                                                    color: tokens.accentGreen,
                                                  ),
                                                  tooltip: 'Perbarui Stok Cepat',
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 4,
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () {
                                                    _showQuickStockDialog(
                                                      context,
                                                      product,
                                                      storeProvider,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                  color: tokens.accentGreen,
                                                ),
                                                padding:
                                                    const EdgeInsets.all(6),
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          AddEditProductScreen(
                                                        productToEdit: product,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: AppColors.error,
                                                ),
                                                padding:
                                                    const EdgeInsets.all(6),
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () {
                                                  _confirmDelete(
                                                    context,
                                                    product,
                                                    storeProvider,
                                                  );
                                                },
                                              ),
                                            ],
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
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: tokens.accentGreen,
        foregroundColor: isDark ? Colors.black : Colors.white,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Produk',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => _openAddProduct(context, isStoreApproved),
      ),
    );
  }

  void _openAddProduct(BuildContext context, bool isStoreApproved) {
    if (!isStoreApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Toko Anda masih menunggu verifikasi. Penjualan belum diizinkan hingga toko diverifikasi.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
    );
  }

  Future<void> _showQuickStockDialog(
    BuildContext context,
    Product product,
    StoreProvider provider,
  ) async {
    final controller = TextEditingController(text: '${product.stock}');
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Perbarui Stok: ${product.name}'),
          content: SingleChildScrollView(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah Stok (${product.unit})',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null || parsed < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stok harus berupa angka >= 0'),
                    ),
                  );
                  return;
                }
                final ok =
                    await provider.updateProduct(product.copyWith(stock: parsed));
                if (context.mounted) {
                  if (ok) {
                    await context.read<ProductProvider>().fetchProducts();
                    if (ctx.mounted) Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal memperbarui stok.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Product product,
    StoreProvider provider,
  ) async {
    final confirmed = await showGlassConfirmDialog(
      context,
      title: 'Hapus Produk?',
      message: 'Apakah Anda yakin ingin menghapus "${product.name}"?',
      confirmText: 'Hapus',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await provider.deleteProduct(product.id);
    if (context.mounted) {
      if (ok) {
        await context.read<ProductProvider>().fetchProducts();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Produk berhasil dihapus.' : 'Gagal menghapus produk.',
            ),
            backgroundColor: ok ? null : AppColors.error,
          ),
        );
      }
    }
  }
}
