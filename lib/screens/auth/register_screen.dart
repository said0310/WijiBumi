import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_guard.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/wijibumi_auth_widgets.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
    return AppColors.forestGreen;
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() {
        _errorMessage =
            'Anda wajib menyetujui Syarat & Ketentuan Wiji Bumi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final res = await context.read<AuthProvider>().register(
          fullName: _nameController.text.trim(),
          email: email,
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
        );
    if (!mounted) return;

    if (!res.success) {
      setState(() {
        _isLoading = false;
        _errorMessage = res.message ?? 'Gagal mendaftarkan akun.';
      });
      return;
    }

    if (res.requiresEmailConfirmation) {
      setState(() => _isLoading = false);
      final msg = res.message ??
          'Pendaftaran berhasil! Silakan cek kotak masuk email Anda untuk verifikasi sebelum masuk.';
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verifikasi Email Diperlukan'),
          content: SingleChildScrollView(child: Text(msg)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _returnToLogin(email: email, message: msg);
              },
              child: const Text('Ke Halaman Masuk'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = false);
    final successMsg = res.message ??
        'Akun berhasil didaftarkan! Silakan masuk menggunakan akun yang baru didaftarkan.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMsg),
        backgroundColor: AppColors.emeraldGreen,
      ),
    );
    _returnToLogin(email: email, message: successMsg);
  }

  void _returnToLogin({required String email, required String message}) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, {'email': email, 'message': message});
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            initialIdentifier: email,
            infoBanner: message,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor =
        isDark ? AppColors.textPrimaryDark : AppColors.forestGreen;
    final subtitleColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.forestGreen.withValues(alpha: 0.82);
    final strength = _passwordStrength(_passwordController.text);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: WijiBumiAmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = WijiBumiResponsiveMetrics(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              );

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.horizontalPadding,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 32)
                        .clamp(0.0, double.infinity),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: metrics.isDesktop ? 480 : metrics.contentMaxWidth,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: headingColor,
                                size: 20,
                              ),
                              tooltip: 'Kembali ke Masuk',
                            ),
                          ),
                          WijiBumiLogoWithGlow(size: metrics.authLogoSize * 0.88),
                          const SizedBox(height: 4),
                          Text(
                            'Buat Akun Wiji Bumi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: metrics.authBrandFontSize * 0.86,
                              fontWeight: FontWeight.w700,
                              color: headingColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Daftar untuk membeli hasil panen segar langsung dari petani.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: metrics.subtitleFontSize * 0.94,
                              fontWeight: FontWeight.w400,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          WijiBumiGlassAuthCard(
                            padding: EdgeInsets.symmetric(
                              horizontal: metrics.isCompactMobile ? 18 : 24,
                              vertical: 22,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_errorMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.error
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppColors.error
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: AppColors.error,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  WijiBumiAuthTextField(
                                    controller: _nameController,
                                    hintText: 'Nama Lengkap',
                                    prefixIcon: Icons.person_outline,
                                    keyboardType: TextInputType.name,
                                    autofillHints: const [AutofillHints.name],
                                    validator: (v) {
                                      final val = (v ?? '').trim();
                                      if (val.isEmpty) {
                                        return 'Nama lengkap wajib diisi';
                                      }
                                      if (val.length < 3) {
                                        return 'Nama lengkap minimal 3 karakter';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  WijiBumiAuthTextField(
                                    controller: _phoneController,
                                    hintText: 'Nomor HP',
                                    prefixIcon: Icons.smartphone_outlined,
                                    keyboardType: TextInputType.phone,
                                    autofillHints: const [
                                      AutofillHints.telephoneNumber,
                                    ],
                                    validator: (v) =>
                                        validateIndonesianPhoneNumber(
                                      v,
                                      invalidMessage:
                                          'Format nomor HP tidak valid (9-15 digit)',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  WijiBumiAuthTextField(
                                    controller: _emailController,
                                    hintText: 'Email',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    validator: (v) {
                                      final val = (v ?? '').trim();
                                      if (val.isEmpty) {
                                        return 'Email wajib diisi';
                                      }
                                      if (!RegExp(
                                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                      ).hasMatch(val)) {
                                        return 'Format email tidak valid';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  WijiBumiAuthTextField(
                                    controller: _passwordController,
                                    hintText: 'Password',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    onChanged: (_) => setState(() {}),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: headingColor,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword =
                                            !_obscurePassword);
                                      },
                                    ),
                                    validator: (v) {
                                      final val = v ?? '';
                                      if (val.isEmpty) {
                                        return 'Password wajib diisi';
                                      }
                                      if (val.length < 6) {
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
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: strength,
                                              minHeight: 5,
                                              backgroundColor: Colors.grey
                                                  .withValues(alpha: 0.2),
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                _strengthColor(strength),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
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
                                  const SizedBox(height: 12),
                                  WijiBumiAuthTextField(
                                    controller: _confirmPasswordController,
                                    hintText: 'Konfirmasi Password',
                                    prefixIcon: Icons.lock_reset_outlined,
                                    obscureText: _obscureConfirm,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleRegister(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: headingColor,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() =>
                                            _obscureConfirm = !_obscureConfirm);
                                      },
                                    ),
                                    validator: (v) {
                                      if (v != _passwordController.text) {
                                        return 'Konfirmasi password tidak sama';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  InkWell(
                                    onTap: () => setState(() =>
                                        _acceptedTerms = !_acceptedTerms),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          value: _acceptedTerms,
                                          activeColor: AppColors.forestGreen,
                                          onChanged: (val) => setState(
                                            () => _acceptedTerms = val ?? false,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 10),
                                            child: Text(
                                              'Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi Wiji Bumi.',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                height: 1.4,
                                                color: isDark
                                                    ? AppColors
                                                        .textSecondaryDark
                                                    : AppColors.neutralDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  WijiBumiPrimaryPillButton(
                                    text: 'Daftar',
                                    isLoading: _isLoading,
                                    onPressed: _handleRegister,
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'Sudah punya akun? ',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.neutralDark,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (Navigator.canPop(context)) {
                                            Navigator.pop(context);
                                          } else {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const LoginScreen(),
                                              ),
                                            );
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          child: Text(
                                            'Masuk',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.primaryLight
                                                  : AppColors.oliveGreen,
                                            ),
                                          ),
                                        ),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
