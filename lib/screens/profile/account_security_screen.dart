import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/address_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glass_widgets.dart';
import '../auth/login_screen.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;
  bool _isResendingVerification = false;
  bool _isDeletingAccount = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  (double, String, Color) _evaluatePasswordStrength(String pwd) {
    if (pwd.isEmpty) return (0.0, 'Belum diisi', Colors.grey);
    int score = 0;
    if (pwd.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) score++;
    if (RegExp(r'[a-z]').hasMatch(pwd)) score++;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pwd)) score++;

    if (score <= 2) return (0.33, 'Lemah', AppColors.error);
    if (score <= 4) return (0.66, 'Sedang', AppColors.warning);
    return (1.0, 'Kuat', AppColors.success);
  }

  Future<void> _handleResendVerification() async {
    if (_isResendingVerification) return;
    setState(() => _isResendingVerification = true);
    final authProv = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final res = await authProv.resendVerificationEmail();
    await authProv.refreshVerificationStatus();
    if (!mounted) return;
    setState(() => _isResendingVerification = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          res.message ??
              (res.success
                  ? 'Tautan verifikasi email telah dikirim.'
                  : 'Gagal mengirim ulang email verifikasi.'),
        ),
        backgroundColor: res.success ? AppColors.success : AppColors.warning,
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    if (_isDeletingAccount) return;
    final confirmed = await showGlassConfirmDialog(
      context,
      title: 'Hapus Akun Permanen',
      message:
          'Akun, alamat pengiriman, dan data profil Anda akan dihapus secara permanen. Pesanan aktif harus diselesaikan atau dibatalkan lebih dulu. Lanjutkan?',
      cancelText: 'Batal',
      confirmText: 'Hapus Akun',
      confirmColor: AppColors.error,
      icon: Icons.delete_forever_outlined,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeletingAccount = true);
    final authProv = context.read<AuthProvider>();
    final storeProv = context.read<StoreProvider>();
    final orderProv = context.read<OrderProvider>();
    final cartProv = context.read<CartProvider>();
    final chatProv = context.read<ChatProvider>();
    final addressProv = context.read<AddressProvider>();
    final notifProv = context.read<NotificationProvider>();
    final productProv = context.read<ProductProvider>();
    final appSettingsProv = context.read<AppSettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final res = await authProv.deleteAccount();
    if (!mounted) return;
    setState(() => _isDeletingAccount = false);

    if (res.success) {
      storeProv.clearSession();
      orderProv.clearSession();
      cartProv.clearSession();
      chatProv.clearSession();
      addressProv.clearSession();
      notifProv.clearSession();
      productProv.resetFilters();
      await appSettingsProv.clearSession();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Akun berhasil dihapus.'),
          backgroundColor: AppColors.success,
        ),
      );
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Gagal menghapus akun.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final res = await context.read<AuthProvider>().changePassword(
          oldPassword: _oldPasswordController.text,
          newPassword: _newPasswordController.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Password berhasil diperbarui!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Gagal memperbarui password.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final info = authProvider.getSecurityInfo();
    final emailVerified = info['emailVerified'] == true;
    final (strengthVal, strengthLabel, strengthColor) =
        _evaluatePasswordStrength(_newPasswordController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keamanan Akun'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
          // Security Status Info Card
          GlassContainer(
            borderRadius: 16,
            enableGlow: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryEmerald.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.secondaryEmerald,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Keamanan Akun',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            info['isSupabaseLive'] == true
                                ? 'Dilindungi oleh Supabase Auth'
                                : 'Mode Demo Lokal (Password tidak disimpan di DB)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22),
                _buildInfoRow('Email Terdaftar', '${info['email']}'),
                const SizedBox(height: 6),
                _buildInfoRow(
                  'Status Verifikasi Email',
                  emailVerified ? 'Terverifikasi' : 'Belum Terverifikasi',
                  valueColor: emailVerified ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(height: 6),
                _buildInfoRow('Metode Autentikasi', '${info['provider']}'),
                if (!emailVerified && '${info['email']}'.trim() != '-') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isResendingVerification
                          ? null
                          : _handleResendVerification,
                      icon: _isResendingVerification
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.mark_email_read_outlined, size: 18),
                      label: Text(
                        _isResendingVerification
                            ? 'Mengirim Tautan...'
                            : 'Kirim Ulang Email Verifikasi',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Change Password Form
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ubah Kata Sandi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gunakan kombinasi huruf besar, huruf kecil, angka, dan simbol minimal 8 karakter.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Password Lama',
                    hint: 'Masukkan password saat ini',
                    controller: _oldPasswordController,
                    obscureText: !_showOld,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_showOld ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showOld = !_showOld),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Password lama wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Password Baru',
                    hint: 'Minimal 8 karakter kuat',
                    controller: _newPasswordController,
                    obscureText: !_showNew,
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showNew = !_showNew),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password baru wajib diisi';
                      if (v.length < 8) return 'Password baru minimal 8 karakter';
                      if (!RegExp(r'[A-Z]').hasMatch(v) ||
                          !RegExp(r'[a-z]').hasMatch(v) ||
                          !RegExp(r'[0-9]').hasMatch(v)) {
                        return 'Sertakan huruf besar, huruf kecil, dan angka';
                      }
                      if (v == _oldPasswordController.text) {
                        return 'Password baru harus berbeda dengan password lama';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: strengthVal,
                            minHeight: 6,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            color: strengthColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        strengthLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: strengthColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Konfirmasi Password Baru',
                    hint: 'Ulangi password baru',
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirm,
                    prefixIcon: const Icon(Icons.verified_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showConfirm = !_showConfirm),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                      if (v != _newPasswordController.text) {
                        return 'Konfirmasi password tidak cocok';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  CustomButton(
                    text: 'Perbarui Password',
                    isLoading: _isLoading,
                    width: double.infinity,
                    onPressed: _handleChangePassword,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Delete Account Danger Zone
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hapus Akun',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Menghapus akun akan menghapus profil dan akses Anda secara permanen. Pesanan yang masih aktif harus diselesaikan atau dibatalkan terlebih dahulu.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isDeletingAccount ? null : _handleDeleteAccount,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: _isDeletingAccount
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.error,
                            ),
                          )
                        : const Icon(Icons.delete_forever_outlined),
                    label: Text(
                      _isDeletingAccount
                          ? 'Menghapus Akun...'
                          : 'Hapus Akun Saya',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
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

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

