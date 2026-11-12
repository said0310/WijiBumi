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
