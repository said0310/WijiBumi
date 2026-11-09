import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../models/promotion.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/empty_state.dart';

class StorePromotionsScreen extends StatelessWidget {
  const StorePromotionsScreen({super.key});

  void _showAddPromotionDialog(BuildContext context, StoreProvider provider) {
    final titleController = TextEditingController();
    final codeController = TextEditingController();
    final valueController = TextEditingController();
    final minPurchaseController = TextEditingController();
    String promoType = 'percentage';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Buat Voucher Promo Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Judul Promo', hintText: 'Diskon Panen 10%'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Kode Voucher', hintText: 'PANEN10'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: promoType,
                    decoration: const InputDecoration(labelText: 'Tipe Promo'),
                    items: const [
                      DropdownMenuItem(value: 'percentage', child: Text('Persentase (%)')),
                      DropdownMenuItem(value: 'fixed_amount', child: Text('Nominal Tetap (Rp)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => promoType = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: promoType == 'percentage' ? 'Besar Diskon (%)' : 'Potongan Harga (Rp)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: minPurchaseController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minimal Pembelian (Rp)',
                      hintText: '50000',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isNotEmpty && valueController.text.trim().isNotEmpty) {
                    final store = provider.myStore!;
                    final promo = Promotion(
                      id: 'promo-${DateTime.now().millisecondsSinceEpoch}',
                      storeId: store.id,
                      title: titleController.text.trim(),
                      code: codeController.text.trim().toUpperCase(),
                      promotionType: promoType,
                      value: double.tryParse(valueController.text.trim()) ?? 0,
                      minimumPurchase: double.tryParse(minPurchaseController.text.trim()) ?? 0,
                      startsAt: DateTime.now(),
                      endsAt: DateTime.now().add(const Duration(days: 30)),
                      quota: 100,
                      isActive: true,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await provider.addPromotion(promo);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Voucher promo berhasil diterbitkan!')),
                      );
                    }
                  }
                },
                child: const Text('Terbitkan Voucher'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storeProvider = context.watch<StoreProvider>();
    final promotions = storeProvider.myStorePromotions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promosi & Voucher Toko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Promo',
            onPressed: () => _showAddPromotionDialog(context, storeProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: promotions.isEmpty
          ? EmptyState(
              icon: Icons.discount_outlined,
              title: 'Belum Ada Voucher',
              message: 'Tingkatkan omset toko dengan memberikan voucher diskon kepada pembeli.',
              buttonText: '+ Buat Voucher Baru',
              onButtonPressed: () => _showAddPromotionDialog(context, storeProvider),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: promotions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final promo = promotions[index];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.discount, color: AppColors.secondary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promo.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    promo.code ?? 'PROMO',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  promo.promotionType == 'percentage'
                                      ? 'Diskon ${promo.value.toInt()}%'
                                      : 'Diskon ${CurrencyFormatter.format(promo.value)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Min. belanja: ${CurrencyFormatter.format(promo.minimumPurchase)} • Berlaku s.d ${DateFormatter.formatShort(promo.endsAt)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Buat Voucher'),
        onPressed: () => _showAddPromotionDialog(context, storeProvider),
      ),
    );
  }
}
