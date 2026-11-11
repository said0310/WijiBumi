import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/store_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/address_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/app_settings_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const WijiBumiApp(),
    ),
  );
}

class WijiBumiApp extends StatefulWidget {
  const WijiBumiApp({super.key});

  @override
  State<WijiBumiApp> createState() => _WijiBumiAppState();
}

class _WijiBumiAppState extends State<WijiBumiApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  bool _isRecoveryDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _listenAuthStateChanges();
  }

  void _listenAuthStateChanges() {
    final client = SupabaseConfig.client;
    if (client == null) return;
    _authSubscription = client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPasswordRecoveryDialog();
        });
      }
    });
  }

  Future<void> _showPasswordRecoveryDialog() async {
    final ctx = _navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted || _isRecoveryDialogOpen) return;
    _isRecoveryDialogOpen = true;

    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscurePassword = true;
    bool isSubmitting = false;
    String? errorText;

    try {
      await showDialog<void>(
        context: ctx,
        barrierDismissible: false,
        builder: (dialogCtx) {
          return StatefulBuilder(
            builder: (builderCtx, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: const Text('Atur Ulang Kata Sandi'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Tautan pemulihan terverifikasi. Masukkan kata sandi baru Anda.',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi Baru',
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setDialogState(
                                  () => obscurePassword = !obscurePassword,
                                );
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 8) {
                              return 'Minimal 8 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: confirmController,
                          obscureText: obscurePassword,
                          decoration: const InputDecoration(
                            labelText: 'Konfirmasi Kata Sandi Baru',
                          ),
                          validator: (v) {
                            if (v != passwordController.text) {
                              return 'Konfirmasi kata sandi tidak cocok';
                            }
                            return null;
                          },
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            errorText!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(dialogCtx).pop(),
                    child: const Text('Tutup'),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() {
                              isSubmitting = true;
                              errorText = null;
                            });
                            final res = await context
                                .read<AuthProvider>()
                                .updateRecoveredPassword(
                                  passwordController.text,
                                );
                            if (!dialogCtx.mounted) return;
                            if (res.success) {
                              Navigator.of(dialogCtx).pop();
                              final hostCtx = _navigatorKey.currentContext;
                              if (hostCtx != null && hostCtx.mounted) {
                                ScaffoldMessenger.of(hostCtx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res.message ??
                                          'Kata sandi baru berhasil disimpan.',
                                    ),
                                  ),
                                );
                              }
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                                errorText = res.message ??
                                    'Gagal memperbarui kata sandi.';
                              });
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      passwordController.dispose();
      confirmController.dispose();
      _isRecoveryDialogOpen = false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'WijiBumi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
