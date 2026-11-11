import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/store_provider.dart';

/// Shared review submission dialog for completed buyer orders.
/// Allows choosing among unreviewed products in the order, prevents duplicate
/// reviews, and refreshes store/product ratings upon success.
Future<bool> showOrderReviewDialog(
  BuildContext context, {
  required Order order,
}) async {
  final orderProv = context.read<OrderProvider>();
  final productProv = context.read<ProductProvider>();
  final storeProv = context.read<StoreProvider>();
  final messenger = ScaffoldMessenger.of(context);

  final reviewedKeys = orderProv.reviewedProductKeysForOrder(order.id);
  final uniqueItems = <OrderItem>[];
  final seenKeys = <String>{};
  for (final item in order.items) {
    final key = item.productId ?? '__order__';
    if (seenKeys.add(key)) {
      uniqueItems.add(item);
    }
  }

  final unreviewedItems = uniqueItems
      .where((item) => !reviewedKeys.contains(item.productId ?? '__order__'))
      .toList();

  if (uniqueItems.isEmpty && reviewedKeys.contains('__order__')) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Pesanan ini sudah Anda ulas.')),
    );
    return false;
  }

  if (uniqueItems.isNotEmpty && unreviewedItems.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Semua produk pada pesanan ini sudah Anda ulas.'),
      ),
    );
    return false;
  }

  int rating = 5;
  bool isSubmitting = false;
  String? errorMsg;
  OrderItem? selectedItem =
      unreviewedItems.isNotEmpty ? unreviewedItems.first : null;
  final reviewController = TextEditingController();
  bool submitted = false;

  try {
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Beri Ulasan Pesanan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Berikan penilaian untuk kualitas hasil panen & layanan toko:',
                  ),
                  if (unreviewedItems.length > 1) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedItem?.productId ?? '__order__',
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Produk yang Diulas',
                      ),
                      items: unreviewedItems.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.productId ?? '__order__',
                          child: Text(
                            item.productNameSnapshot,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: isSubmitting
                          ? null
                          : (val) {
                              final picked = unreviewedItems
                                  .where(
                                    (i) => (i.productId ?? '__order__') == val,
                                  )
                                  .firstOrNull;
                              if (picked != null) {
                                setDialogState(() => selectedItem = picked);
                              }
                            },
                    ),
                  ] else if (selectedItem != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        selectedItem!.productNameSnapshot,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 2,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: Icon(
                          starValue <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 30,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () => setDialogState(() => rating = starValue),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Tulis Ulasan Anda',
                      hintText:
                          'Contoh: Sayur sangat segar, pengiriman cepat...',
                      errorText: errorMsg,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final text = reviewController.text.trim();
                        if (text.isEmpty) {
                          setDialogState(
                            () => errorMsg = 'Ulasan wajib diisi',
                          );
                          return;
                        }
                        setDialogState(() {
                          isSubmitting = true;
                          errorMsg = null;
                        });
                        try {
                          await orderProv.addReview(
                            orderId: order.id,
                            storeId: order.storeId,
                            productId: selectedItem?.productId,
                            rating: rating,
                            reviewText: text,
                          );
                          await Future.wait([
                            productProv.fetchProducts(),
                            storeProv.loadStores(),
                          ]);
                          submitted = true;
                          if (ctx.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ulasan berhasil dikirim! Terima kasih.',
                              ),
                            ),
                          );
                        } catch (e) {
                          final raw = e
                              .toString()
                              .replaceFirst('Exception: ', '')
                              .trim();
                          setDialogState(() {
                            isSubmitting = false;
                            errorMsg = raw.isNotEmpty
                                ? raw
                                : 'Gagal mengirim ulasan. Coba lagi nanti.';
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kirim Ulasan'),
              ),
            ],
          );
        },
      ),
    );
  } finally {
    reviewController.dispose();
  }

  return submitted;
}

