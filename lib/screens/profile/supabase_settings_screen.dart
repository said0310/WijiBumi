import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SupabaseSettingsScreen extends StatefulWidget {
  const SupabaseSettingsScreen({super.key});

  @override
  State<SupabaseSettingsScreen> createState() => _SupabaseSettingsScreenState();
}

class _SupabaseSettingsScreenState extends State<SupabaseSettingsScreen> {
  final _urlController = TextEditingController();
  final _anonKeyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = SupabaseConfig.currentUrl;
    _anonKeyController.text = SupabaseConfig.currentAnonKey;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = SupabaseConfig.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koneksi Supabase'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isConnected ? AppColors.success.withOpacity(0.12) : AppColors.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isConnected ? AppColors.success : AppColors.secondary,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected ? AppColors.success : AppColors.secondary,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? 'Terhubung ke Supabase Live' : 'Mode Offline / In-Memory Demo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isConnected ? AppColors.success : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isConnected
                            ? 'Aplikasi terhubung ke database cloud PostgreSQL Supabase.'
                            : 'Aplikasi berjalan dengan data mock lokal agrikultur lengkap.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Konfigurasi Kredensial Supabase',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Masukkan URL dan Anon Public Key dari project Supabase Anda (Settings -> API).',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 16),

          CustomTextField(
            label: 'Supabase Project URL',
            hint: 'https://xyzcompany.supabase.co',
            controller: _urlController,
          ),

          const SizedBox(height: 14),

          CustomTextField(
            label: 'Supabase Anon Public Key',
            hint: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
            controller: _anonKeyController,
            maxLines: 2,
          ),

          const SizedBox(height: 24),

          CustomButton(
            text: 'Simpan & Hubungkan Database',
            isLoading: _isLoading,
            onPressed: () async {
              setState(() => _isLoading = true);
              final success = await SupabaseConfig.updateCredentials(
                _urlController.text.trim(),
                _anonKeyController.text.trim(),
              );
              setState(() => _isLoading = false);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Koneksi ke Supabase berhasil diaktifkan!'
                          : 'Kredensial disimpan. Periksa validitas URL dan Anon Key.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
