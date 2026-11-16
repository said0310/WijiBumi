import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/smart_image.dart';

class StoreReviewsScreen extends StatelessWidget {
  const StoreReviewsScreen({super.key});

  Future<void> _showReplyDialog(
      BuildContext context, String reviewId, StoreProvider provider) async {
    final replyController = TextEditingController();
    bool sending = false;
    String? errorMsg;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
            title: const Text('Balas Ulasan Pelanggan'),
            content: SingleChildScrollView(
              child: TextField(
                controller: replyController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Tulis Balasan Toko',
                  hintText: 'Terima kasih atas pesanan dan ulasannya...',
                  errorText: errorMsg,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        final text = replyController.text.trim();
                        if (text.isEmpty) {
                          setDialogState(() => errorMsg = 'Balasan wajib diisi');
                          return;
                        }
                        setDialogState(() {
                          sending = true;
                          errorMsg = null;
                        });
                        final ok = await provider.replyReview(reviewId, text);
                        if (!context.mounted) return;
                        if (ok) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Balasan ulasan berhasil dikirim!')),
                          );
                        } else {
                          setDialogState(() {
                            sending = false;
                            errorMsg = 'Gagal mengirim balasan ulasan.';
                          });
                        }
                      },
                child: const Text('Kirim Balasan'),
              ),
            ],
          ),
        ),
      );
    } finally {
      replyController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storeProvider = context.watch<StoreProvider>();
    final reviews = storeProvider.myStoreReviews;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ulasan & Rating Toko'),
      ),
      body: SafeArea(
        top: false,
        child: reviews.isEmpty
            ? const EmptyState(
                icon: Icons.star_border,
                title: 'Belum Ada Ulasan',
                message: 'Ulasan dari pembeli yang telah menyelesaikan pesanan akan muncul di sini.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final rev = reviews[index];
                  final reviewerName = rev.reviewerName ?? 'Pelanggan WijiBumi';

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppColors.lightGreen,
                                        child: ClipOval(
                                          child: SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: SmartImage(
                                              source: rev.reviewerAvatar ??
                                                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=300&q=80',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reviewerName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              DateFormatter.formatShort(rev.createdAt),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (starIdx) {
                                    return Icon(
                                      starIdx < rev.rating ? Icons.star : Icons.star_border,
                                      size: 16,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                              ],
                            ),
                      const SizedBox(height: 10),
                      if (rev.productName != null) ...[
                        Text(
                          'Produk: ${rev.productName}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        rev.reviewText ?? '',
                        style: const TextStyle(fontSize: 13, height: 1.3),
                      ),
                      if (rev.replyText != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.primaryLight : AppColors.primary)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.reply, size: 14, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Text('Balasan Toko:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(rev.replyText!, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.reply, size: 14),
                            label: const Text('Balas Ulasan', style: TextStyle(fontSize: 12)),
                            onPressed: () => _showReplyDialog(context, rev.id, storeProvider),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
                },
              ),
      ),
    );
  }
}
