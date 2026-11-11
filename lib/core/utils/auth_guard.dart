import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';

/// Shared authentication check for buyer-facing actions (Cart, Chat, Checkout, Account).
/// If the session hasn't initialized yet, finishes loading once before checking.
Future<bool> ensureBuyerAuthenticated(BuildContext context) async {
  final authProvider = context.read<AuthProvider>();
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  if (!authProvider.isAuthenticated && !authProvider.initialized) {
    await authProvider.loadUser();
  }
  if (authProvider.isAuthenticated) return true;

  messenger.showSnackBar(
    const SnackBar(
      content: Text('Silakan masuk ke akun WijiBumi terlebih dahulu.'),
    ),
  );
  navigator.push(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return false;
}

/// Validates Indonesian phone numbers strictly without permitting alphabetic characters.
String? validateIndonesianPhoneNumber(
  String? value, {
  String emptyMessage = 'Nomor HP wajib diisi',
  String invalidMessage =
      'Masukkan nomor HP Indonesia yang valid (contoh: 081234567890)',
}) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return emptyMessage;
  if (RegExp(r'[^0-9+\s\-\(\)]').hasMatch(raw)) {
    return invalidMessage;
  }
  final clean = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (!RegExp(r'^(?:\+62|62|0)8[1-9][0-9]{6,11}$').hasMatch(clean)) {
    return invalidMessage;
  }
  return null;
}

/// Validates either a formatted email address or an Indonesian mobile number.
String? validateLoginIdentifier(String? value) {
  final val = (value ?? '').trim();
  if (val.isEmpty) {
    return 'Nomor HP atau Email wajib diisi';
  }
  if (val.contains('@')) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(val)) {
      return 'Format email tidak valid';
    }
    return null;
  }
  return validateIndonesianPhoneNumber(
    val,
    emptyMessage: 'Nomor HP atau Email wajib diisi',
    invalidMessage: 'Masukkan nomor HP atau email yang valid',
  );
}

