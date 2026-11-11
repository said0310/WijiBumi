import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../models/app_settings.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/glass_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<AppSettingsProvider>();
    final settings = settingsProvider.settings;

    final themeLabel = switch (themeProvider.themeMode) {
      ThemeMode.light => 'Light Mode',
      ThemeMode.dark => 'Dark Mode',
      ThemeMode.system => 'System Default',
    };

    final languageLabel =
        settings.languageCode == 'en' ? 'English (EN)' : 'Bahasa Indonesia (ID)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Aplikasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            borderRadius: 16,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                  title: const Text(
                    'Pengaturan Notifikasi',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    settings.orderNotifications ? 'Notifikasi pesanan aktif' : 'Notifikasi pesanan nonaktif',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
                  title: const Text(
                    'Pengaturan Tema',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(themeLabel, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_outlined, color: AppColors.primary),
                  title: const Text(
                    'Pengaturan Bahasa',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(languageLabel, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  title: const Text(
                    'Pengaturan Privasi',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Visibilitas status & preferensi data',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _saveSettingsWithFeedback(
  BuildContext context,
  AppSettingsProvider provider,
  AppSettings updated, {
  String? successMessage,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await provider.updateSettings(updated);
  if (!context.mounted) return;
  if (!ok) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          provider.lastError ?? 'Gagal menyimpan pengaturan ke server.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  } else if (successMessage != null) {
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
  }
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppSettingsProvider>();
    final s = provider.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Notifikasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            borderRadius: 16,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notifikasi Status Pesanan'),
                  subtitle: const Text('Pembaruan konfirmasi, pengemasan & tracking paket'),
                  value: s.orderNotifications,
                  onChanged: provider.isSaving
                      ? null
                      : (v) => _saveSettingsWithFeedback(
                            context,
                            provider,
                            s.copyWith(orderNotifications: v),
                          ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Notifikasi Pesan Chat'),
                  subtitle: const Text('Pesan masuk dari pembeli maupun petani penjual'),
                  value: s.chatNotifications,
                  onChanged: provider.isSaving
                      ? null
                      : (v) => _saveSettingsWithFeedback(
                            context,
                            provider,
                            s.copyWith(chatNotifications: v),
                          ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Info Panen Raya & Promo'),
                  subtitle: const Text('Voucher diskon dan penawaran segar dari toko mitra'),
                  value: s.promoNotifications,
                  onChanged: provider.isSaving
                      ? null
                      : (v) => _saveSettingsWithFeedback(
                            context,
                            provider,
                            s.copyWith(promoNotifications: v),
                          ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Pembaruan via Email'),
                  subtitle: const Text('Ringkasan transaksi dan verifikasi akun melalui email'),
                  value: s.emailUpdates,
                  onChanged: provider.isSaving
                      ? null
                      : (v) => _saveSettingsWithFeedback(
                            context,
                            provider,
                            s.copyWith(emailUpdates: v),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final current = themeProvider.themeMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Tema')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            borderRadius: 16,
            child: RadioGroup<ThemeMode>(
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  themeProvider.setThemeMode(val);
                }
              },
              child: Column(
                children: const [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    title: Text('Light Mode'),
                    subtitle: Text('Tampilan terang bersih khas agritech WijiBumi'),
                    secondary: Icon(Icons.light_mode, color: AppColors.secondary),
                  ),
                  Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    title: Text('Dark Mode'),
                    subtitle: Text('Tampilan gelap nyaman di mata saat malam hari'),
                    secondary: Icon(Icons.dark_mode, color: AppColors.secondaryEmerald),
                  ),
                  Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    title: Text('System Default'),
                    subtitle: Text('Menyesuaikan pengaturan tema perangkat Anda'),
                    secondary: Icon(Icons.phone_android, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppSettingsProvider>();
    final s = provider.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Bahasa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            borderRadius: 16,
            child: RadioGroup<String>(
              groupValue: s.languageCode,
              onChanged: (val) {
                if (val != null) {
                  _saveSettingsWithFeedback(
                    context,
                    provider,
                    s.copyWith(languageCode: val),
                    successMessage: val == 'en'
                        ? 'Language preference saved to account: English'
                        : 'Preferensi bahasa disimpan ke akun: Bahasa Indonesia',
                  );
                }
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    value: 'id',
                    title: Text('Bahasa Indonesia'),
                    subtitle: Text('Bahasa utama marketplace WijiBumi (Default)'),
                  ),
                  Divider(height: 1),
                  RadioListTile<String>(
                    value: 'en',
                    title: Text('English'),
                    subtitle: Text('Preferensi bahasa disimpan di profil; terjemahan penuh UI menyusul bertahap'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppSettingsProvider>();
    final s = provider.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Privasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            borderRadius: 16,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Tampilkan Status Online di Chat'),
                  subtitle: const Text('Izinkan pembeli/penjual melihat status aktif Anda'),
                  value: s.showOnlineStatus,
                  onChanged: provider.isSaving
                      ? null
                      : (v) => _saveSettingsWithFeedback(
                            context,
                            provider,
                            s.copyWith(showOnlineStatus: v),
                          ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Rekomendasi Produk Personalisasi'),
                  subtitle: const Text('Izinkan WijiBumi menyesuaikan produk berdasarkan preferensi'),
                  value: s.allowAnalytics,
                  onChanged: provider.isSaving
                      ? null
                      : (v) => _saveSettingsWithFeedback(
                            context,
                            provider,
                            s.copyWith(allowAnalytics: v),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
