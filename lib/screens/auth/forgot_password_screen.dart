import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/wijibumi_auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.contains('@')) {
      _emailController.text = widget.initialEmail!.trim();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitReset() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final res = await context
        .read<AuthProvider>()
        .sendPasswordReset(_emailController.text.trim());

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isSuccess = res.success;
      _statusMessage = res.message ??
          (res.success
              ? 'Tautan pengaturan ulang kata sandi telah dikirim ke email Anda.'
              : 'Gagal mengirim tautan reset password.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.forestGreen;
    final subTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.forestGreen.withValues(alpha: 0.78);

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
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 40).clamp(0, double.infinity),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: metrics.contentMaxWidth),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: primaryTextColor,
                                size: 20,
                              ),
                              tooltip: 'Kembali',
                            ),
                          ),
                          WijiBumiLogoWithGlow(size: metrics.authLogoSize),
                          const SizedBox(height: 6),
                          Text(
                            'Wiji Bumi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: metrics.authBrandFontSize,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Lupa Kata Sandi?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: metrics.authHeadingSize,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masukkan email terdaftar Anda untuk menerima tautan reset password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: metrics.subtitleFontSize,
                              fontWeight: FontWeight.w400,
                              color: subTextColor,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          WijiBumiGlassAuthCard(
                            padding: EdgeInsets.symmetric(
                              horizontal: metrics.isCompactMobile ? 18 : 24,
                              vertical: 24,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_statusMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: (_isSuccess
                                                ? AppColors.emeraldGreen
                                                : AppColors.error)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: (_isSuccess
                                                  ? AppColors.emeraldGreen
                                                  : AppColors.error)
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            _isSuccess
                                                ? Icons.check_circle_outline
                                                : Icons.error_outline,
                                            color: _isSuccess
                                                ? AppColors.emeraldGreen
                                                : AppColors.error,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _statusMessage!,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  WijiBumiAuthTextField(
                                    controller: _emailController,
                                    hintText: 'Email terdaftar',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [AutofillHints.email],
                                    onFieldSubmitted: (_) => _submitReset(),
                                    validator: (v) {
                                      final val = (v ?? '').trim();
                                      if (val.isEmpty) {
                                        return 'Email wajib diisi';
                                      }
                                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                          .hasMatch(val)) {
                                        return 'Masukkan alamat email yang valid';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  WijiBumiPrimaryPillButton(
                                    text: 'Kirim Tautan Reset',
                                    isLoading: _isLoading,
                                    onPressed: _submitReset,
                                  ),
                                  const SizedBox(height: 18),
                                  Center(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Kembali ke Halaman Masuk',
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

