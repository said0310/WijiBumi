import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/glass_widgets.dart';
import 'seller_login_screen.dart';

class SellerRegisterScreen extends StatefulWidget {
  final String? initialEmail;

  const SellerRegisterScreen({super.key, this.initialEmail});

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final currentUser = context.read<AuthProvider>().user;
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    } else if (currentUser?.email != null) {
      _emailController.text = currentUser!.email!;
    }
    if (currentUser?.fullName != null) {
      _nameController.text = currentUser!.fullName;
    }
    if (currentUser?.phone != null) {
      _phoneController.text = currentUser!.phone!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  double _passwordStrength(String pwd) {
    if (pwd.isEmpty) return 0;
    double score = 0;
    if (pwd.length >= 6) score += 0.25;
    if (pwd.length >= 8) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(pwd) && RegExp(r'[a-z]').hasMatch(pwd)) {
      score += 0.25;
    }
    if (RegExp(r'[0-9]').hasMatch(pwd)) score += 0.25;
    return score.clamp(0.0, 1.0);
  }

  String _strengthLabel(double s) {
    if (s <= 0.25) return 'Lemah';
    if (s <= 0.5) return 'Sedang';
    if (s <= 0.75) return 'Kuat';
    return 'Sangat Kuat';
  }

  Color _strengthColor(double s) {
    if (s <= 0.25) return AppColors.error;
    if (s <= 0.5) return AppColors.warning;
    if (s <= 0.75) return AppColors.emeraldGreen;
    return AppColors.success;
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Anda wajib menyetujui Syarat & Ketentuan Penjual WijiBumi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final registeredEmail = _emailController.text.trim();

    final result = await authProvider.registerSeller(
      fullName: _nameController.text.trim(),
      email: registeredEmail,
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.status == SellerAuthStatus.emailNotVerified) {
      final msg = result.message ??
          'Akun penjual berhasil dibuat. Silakan cek inbox email Anda untuk verifikasi lalu login melalui halaman Login Penjual.';
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verifikasi Email Diperlukan'),
          content: SingleChildScrollView(child: Text(msg)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _returnToSellerLogin(email: registeredEmail, message: msg);
              },
              child: const Text('Ke Login Penjual'),
            ),
          ],
        ),
      );
      return;
    }

    if (result.isSuccess) {
      final msg = result.message ??
          'Akun penjual berhasil didaftarkan! Silakan login terlebih dahulu menggunakan email dan password Anda.';
      _returnToSellerLogin(email: registeredEmail, message: msg);
      return;
    }

    setState(() {
      _errorMessage = result.message ?? 'Pendaftaran akun penjual gagal.';
    });
  }

  void _returnToSellerLogin({required String email, required String message}) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, {'email': email, 'message': message});
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SellerLoginScreen(
            initialEmail: email,
            infoBanner: message,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strength = _passwordStrength(_passwordController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Penjual'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.surfaceDark]
                : [AppColors.lightGreen, AppColors.backgroundLight],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bergabung Sebagai Mitra Petani & Pemasok',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Jual bunga, sayuran, dan buah-buahan segar langsung dari kebun Anda ke pelanggan WijiBumi.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (_errorMessage != null) ...[
                      GlassContainer(
                        borderRadius: 14,
                        padding: const EdgeInsets.all(14),
                        tintColor: AppColors.error.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.45),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              label: 'Nama Lengkap',
                              hint: 'Nama pemilik toko / petani',
                              controller: _nameController,
                              prefixIcon: const Icon(Icons.person_outline),
                              validator: (v) {
                                if (v == null || v.trim().length < 3) {
                                  return 'Nama lengkap minimal 3 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              label: 'Email',
                              hint: 'penjual@kebun.id',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(Icons.email_outlined),
                              validator: (v) {
                                final val = (v ?? '').trim();
                                if (val.isEmpty) {
                                  return 'Email wajib diisi';
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(val)) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              label: 'Nomor HP',
                              hint: '0812xxxxxxxx',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              prefixIcon: const Icon(Icons.phone_outlined),
                              validator: (v) {
                                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                                if (digits.length < 9 || digits.length > 15) {
                                  return 'Format nomor HP tidak valid (9-15 digit)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              label: 'Password',
                              hint: 'Minimal 6 karakter',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                if (v == null || v.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: strength,
                                        minHeight: 6,
                                        backgroundColor:
                                            Colors.grey.withValues(alpha: 0.2),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _strengthColor(strength),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _strengthLabel(strength),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: _strengthColor(strength),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),
                            CustomTextField(
                              label: 'Konfirmasi Password',
                              hint: 'Ulangi password',
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              prefixIcon: const Icon(Icons.lock_reset_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Konfirmasi password tidak cocok';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _acceptedTerms,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) => setState(
                                      () => _acceptedTerms = val ?? false),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _acceptedTerms = !_acceptedTerms),
                                    child: const Padding(
                                      padding: EdgeInsets.only(top: 10),
                                      child: Text(
                                        'Saya menyetujui Syarat & Ketentuan Mitra Penjual WijiBumi serta berkomitmen menjaga kualitas hasil panen.',
                                        style: TextStyle(fontSize: 12.5, height: 1.4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Daftar',
                              icon: Icons.how_to_reg,
                              isLoading: _isLoading,
                              width: double.infinity,
                              onPressed: _submitRegister,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text('Sudah memiliki akun penjual?',
                                    style: TextStyle(fontSize: 13)),
                                TextButton(
                                  onPressed: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    } else {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SellerLoginScreen(),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Login',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
