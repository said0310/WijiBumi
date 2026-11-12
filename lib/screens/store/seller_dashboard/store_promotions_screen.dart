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

  Future<void> _showAddPromotionDialog(BuildContext context, StoreProvider provider) async {
    final store = provider.myStore;
    if (store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data toko tidak ditemukan.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final codeController = TextEditingController();
    final valueController = TextEditingController();
    final minPurchaseController = TextEditingController();
    String promoType = 'percentage';
    bool isSaving = false;
    String? errorMsg;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Buat Voucher Promo Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMsg != null) ...[
                      Text(
                        errorMsg!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                    ],
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
                      initialValue: promoType,
                      isExpanded: true,
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
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final parsedVal = double.tryParse(valueController.text.trim()) ?? 0;
                          final minPurchase =
                              double.tryParse(minPurchaseController.text.trim()) ?? 0;
                          if (title.isEmpty) {
                            setDialogState(() => errorMsg = 'Judul promo wajib diisi');
                            return;
                          }
                          if (parsedVal <= 0) {
                            setDialogState(() => errorMsg = 'Nilai diskon harus lebih dari 0');
                            return;
                          }
                          if (promoType == 'percentage' && parsedVal > 100) {
                            setDialogState(() => errorMsg = 'Diskon persentase maksimal 100%');
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            errorMsg = null;
                          });

                          final trimmedCode = codeController.text.trim().toUpperCase();
                          final promo = Promotion(
                            id: 'promo-${DateTime.now().millisecondsSinceEpoch}',
                            storeId: store.id,
                            title: title,
                            code: trimmedCode.isNotEmpty ? trimmedCode : null,
                            promotionType: promoType,
                            value: parsedVal,
                            minimumPurchase: minPurchase < 0 ? 0 : minPurchase,
                            startsAt: DateTime.now(),
                            endsAt: DateTime.now().add(const Duration(days: 30)),
                            quota: 100,
                            isActive: true,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          try {
                            await provider.addPromotion(promo);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Voucher promo berhasil diterbitkan!')),
                              );
                            }
                          } catch (_) {
                            setDialogState(() {
                              isSaving = false;
                              errorMsg = 'Gagal menerbitkan voucher. Periksa data atau kode promo.';
                            });
                          }
                        },
                  child: const Text('Terbitkan Voucher'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      titleController.dispose();
      codeController.dispose();
      valueController.dispose();
      minPurchaseController.dispose();
    }
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
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                96 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: promotions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final promo = promotions[index];

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: Container(
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
                              color: AppColors.secondary.withValues(alpha: 0.12),
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
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
                    ),
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
