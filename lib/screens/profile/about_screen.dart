import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/wijibumi_auth_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _showLegalModal(BuildContext context, {required String title, required String body}) {
    showGlassBottomSheet(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(body, style: const TextStyle(fontSize: 13, height: 1.55)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang WijiBumi'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassContainer(
                  borderRadius: 20,
                  enableGlow: true,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const WijiBumiLogoWithGlow(size: 88),
                      const SizedBox(height: 12),
                      const Text(
                        'Wiji Bumi',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tumbuh Bersama, Sejahtera Bersama',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.secondaryEmerald : AppColors.primary,
                        ),
                      ),
                const SizedBox(height: 12),
                Text(
                  'WijiBumi menghubungkan pembeli secara langsung dengan petani dan pemasok produk pertanian pilihan berupa bunga, sayuran segar, dan buah-buahan berkualitas tinggi dari seluruh Indonesia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassContainer(
            borderRadius: 16,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.primary),
                  title: Text('Versi Aplikasi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: Text('v0.1.0+1', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.code, color: AppColors.primary),
                  title: Text('Pengembang', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('Tim WijiBumi Agritech', style: TextStyle(fontSize: 12)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
                  title: const Text('Kebijakan Privasi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showLegalModal(
                    context,
                    title: 'Kebijakan Privasi WijiBumi',
                    body:
                        '1. Data Akun & Keamanan: WijiBumi menjaga keamanan data pribadi Anda (nama, email, nomor telepon, dan alamat pengiriman) menggunakan enkripsi serta Row Level Security pada Supabase.\n\n'
                        '2. Penggunaan Data: Informasi hanya digunakan untuk memproses pesanan, pengiriman hasil panen, komunikasi pembeli-penjual, dan notifikasi transaksi.\n\n'
                        '3. Hak Pengguna: Anda dapat memperbarui profil, alamat, maupun preferensi privasi kapan saja melalui halaman Profile & Pengaturan.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                  title: const Text('Syarat dan Ketentuan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showLegalModal(
                    context,
                    title: 'Syarat dan Ketentuan WijiBumi',
                    body:
                        '1. Satu Akun Multi-Peran: Setiap pengguna dapat berbelanja sebagai pembeli maupun mendaftarkan toko sebagai penjual setelah lolos verifikasi toko WijiBumi.\n\n'
                        '2. Produk Pertanian: Penjual wajib mencantumkan informasi produk bunga, sayuran, dan buah secara jujur (grade kualitas, tanggal panen, stok, dan harga).\n\n'
                        '3. Transaksi & Pengiriman: Status pesanan mengikuti alur transaksi yang sah mulai dari pembayaran, konfirmasi penjual, pengemasan, pengiriman dengan resi, hingga pesanan selesai.',
                  ),
                ),
              ],
            ),
          ),
        ],
            ),
          ),
        ),
      ),
    );
  }
}

