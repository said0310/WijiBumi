import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store.dart';
import '../../../providers/store_provider.dart';
import '../../../widgets/glass_widgets.dart';
import 'store_settings_screen.dart';

class StoreVerificationScreen extends StatelessWidget {
  const StoreVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final Store? store = storeProvider.myStore;

    if (store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verifikasi Toko')),
        body: const Center(child: Text('Data toko tidak ditemukan.')),
      );
    }

    final statusColor = store.isApproved
        ? AppColors.success
        : (store.verificationStatus == 'rejected' ||
                store.verificationStatus == 'suspended'
            ? AppColors.error
            : AppColors.warning);

    final hasBasicInfo = store.storeName.trim().isNotEmpty &&
        (store.description?.trim().isNotEmpty ?? false);
    final hasContact = (store.email?.trim().isNotEmpty ?? false) &&
        (store.phone?.trim().isNotEmpty ?? false);
    final hasAddress = (store.address?.trim().isNotEmpty ?? false) &&
        (store.city?.trim().isNotEmpty ?? false) &&
        (store.province?.trim().isNotEmpty ?? false);
    final hasOperational =
        (store.operatingHours?.trim().isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Toko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Periksa Status Terbaru',
            onPressed: () => storeProvider.checkMyStore(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => storeProvider.checkMyStore(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassContainer(
              borderRadius: 18,
              padding: const EdgeInsets.all(18),
              tintColor: statusColor.withValues(alpha: 0.12),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      store.isApproved
                          ? Icons.verified_rounded
                          : (store.verificationStatus == 'rejected'
                              ? Icons.cancel_outlined
                              : Icons.hourglass_top_rounded),
                      color: statusColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Verifikasi Toko',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          store.verificationStatusLabel,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        if (store.verificationNote != null &&
                            store.verificationNote!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            store.verificationNote!,
                            style: const TextStyle(fontSize: 12.5, height: 1.35),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Kelengkapan Data Verifikasi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _CheckItem(
                    title: 'Profil & Deskripsi Toko',
                    subtitle: store.storeName,
                    completed: hasBasicInfo,
                  ),
                  const Divider(height: 1),
                  _CheckItem(
                    title: 'Email & Nomor Telepon Aktif',
                    subtitle: '${store.email ?? '-'} • ${store.phone ?? '-'}',
                    completed: hasContact,
                  ),
                  const Divider(height: 1),
                  _CheckItem(
                    title: 'Alamat Kebun / Gudang',
                    subtitle: [store.address, store.city, store.province]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(', '),
                    completed: hasAddress,
                  ),
                  const Divider(height: 1),
                  _CheckItem(
                    title: 'Jam Operasional Toko',
                    subtitle: store.operatingHours ?? 'Belum diatur',
                    completed: hasOperational,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Panduan Verifikasi Mitra WijiBumi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Pastikan nama toko, kontak aktif, dan alamat pengirim sesuai lokasi panen atau gudang.\n'
                    '• Tim admin memvalidasi data toko sebelum status berubah menjadi Aktif & Terverifikasi.\n'
                    '• Jika terdapat catatan revisi, perbarui data toko melalui menu Pengaturan Toko.',
                    style: TextStyle(fontSize: 12.5, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StoreSettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Lengkapi Data di Pengaturan Toko'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool completed;

  const _CheckItem({
    required this.title,
    required this.subtitle,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        completed ? Icons.check_circle : Icons.radio_button_unchecked,
        color: completed ? AppColors.success : Colors.grey,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle.isEmpty ? 'Belum dilengkapi' : subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

