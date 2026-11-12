import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_formatter.dart';
import '../models/user_profile.dart';
import '../models/store.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/shipment.dart';
import '../models/chat.dart';
import '../models/review.dart';
import '../models/promotion.dart';
import '../models/payout.dart';
import '../models/app_notification.dart';
import '../models/support_ticket.dart';
import '../models/app_settings.dart';
import 'mock_data.dart';

class AuthResult {
  final bool success;
  final UserProfile? profile;
  final String? message;
  final bool requiresEmailConfirmation;

  const AuthResult({
    required this.success,
    this.profile,
    this.message,
    this.requiresEmailConfirmation = false,
  });
}

class ProfileUpdateResult {
  final bool success;
  final bool emailVerificationSent;
  final String? errorMessage;

  const ProfileUpdateResult({
    required this.success,
    this.emailVerificationSent = false,
    this.errorMessage,
  });
}

enum SellerAuthStatus {
  success,
  needsStoreRegistration,
  notSeller,
  emailNotVerified,
  notConfigured,
  error,
}

class SellerAuthResult {
  final SellerAuthStatus status;
  final UserProfile? profile;
  final Store? store;
  final String? message;

  const SellerAuthResult({
    required this.status,
    this.profile,
    this.store,
    this.message,
  });

  bool get isSuccess =>
      status == SellerAuthStatus.success || status == SellerAuthStatus.needsStoreRegistration;
}

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  // In-memory data store for fallback / offline demo mode
  UserProfile? _activeDemoUser = MockData.defaultUser;
  final Map<String, String> _demoPasswords = {
    MockData.defaultUser.id: 'password123',
  };
  final List<UserProfile> _demoUsers = [MockData.defaultUser];

  List<Category> categories = List.from(MockData.categories);
  List<Store> stores = List.from(MockData.stores);
  List<Product> products = List.from(MockData.products);
  List<Address> addresses = List.from(MockData.addresses);
  List<CartItem> cartItems = List.from(MockData.initialCart);
  List<Order> orders = List.from(MockData.initialOrders);
  List<Chat> chats = List.from(MockData.initialChats);
  List<ChatMessage> chatMessages = List.from(MockData.initialChatMessages);
  List<Review> reviews = List.from(MockData.initialReviews);
  List<Promotion> promotions = List.from(MockData.initialPromotions);
  List<PayoutAccount> payoutAccounts = List.from(MockData.initialPayoutAccounts);
  List<PayoutRequest> payoutRequests = List.from(MockData.initialPayoutRequests);
  List<AppNotification> notifications = List.from(MockData.initialNotifications);
  List<SupportTicket> supportTickets = [];
  final Map<String, List<OrderStatusHistoryEntry>> _localOrderHistory = {};

  @visibleForTesting
  Future<SellerAuthResult> Function(String email, String password)? sellerLoginTestHook;

  @visibleForTesting
  Future<SellerAuthResult> Function({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  })? sellerRegisterTestHook;

  @visibleForTesting
  Future<AuthResult> Function(String identifier, String password)? buyerLoginTestHook;

  @visibleForTesting
  Future<AuthResult> Function({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  })? buyerRegisterTestHook;

  @visibleForTesting
  Future<AuthResult> Function(String email)? forgotPasswordTestHook;

  @visibleForTesting
  Map<String, dynamic> Function(String? draftEmail, String? draftPhone)?
      profileVerificationTestHook;

  @visibleForTesting
  Future<AuthResult> Function()? deleteAccountTestHook;

  bool get hasActiveRemoteSession {
    if (!isConnected) return false;
    final client = SupabaseConfig.client;
    return client?.auth.currentSession != null && client?.auth.currentUser != null;
  }

  UserProfile get currentUser => _activeDemoUser ?? MockData.defaultUser;
  set currentUser(UserProfile user) {
    _activeDemoUser = user;
  }

  bool get isConnected => SupabaseConfig.isInitialized && SupabaseConfig.client != null;

  String? get activeUserId {
    if (isConnected) {
      return SupabaseConfig.client!.auth.currentUser?.id;
    }
    return _activeDemoUser?.id;
  }

  // ------------------ STORAGE ------------------

  Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String bucket,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final uid = client.auth.currentUser?.id ?? 'anonymous';
        final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        await client.storage.from(bucket).uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(upsert: true, contentType: contentType),
            );
        return client.storage.from(bucket).getPublicUrl(path);
      } catch (e) {
        debugPrint('Supabase Storage upload error ($bucket): $e');
        return null;
      }
    }

    // Fallback for offline/demo mode so selected photos still preview & persist in memory
    final mime = contentType.isNotEmpty ? contentType : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  // ------------------ AUTH & PROFILE ------------------

  Future<UserProfile?> getCurrentProfile() async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final user = client.auth.currentUser;
        if (user == null) {
          return null;
        }
        final res = await client.from('profiles').select().eq('id', user.id).maybeSingle();
        if (res != null) {
          var prof = UserProfile.fromJson(res);
          final confirmedEmail = user.email?.trim();
          if (user.emailConfirmedAt != null &&
              confirmedEmail != null &&
              confirmedEmail.isNotEmpty &&
              confirmedEmail.toLowerCase() != (prof.email ?? '').trim().toLowerCase()) {
            try {
              await client.from('profiles').update({
                'email': confirmedEmail,
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', user.id);
            } catch (_) {}
            if (prof.hasSellerAccess) {
              try {
                await client.from('seller_profiles').update({
                  'email': confirmedEmail,
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('user_id', user.id);
              } catch (_) {}
            }
            prof = prof.copyWith(email: confirmedEmail);
          }
          _activeDemoUser = prof;
          return prof;
        }
        // Create missing profile if trigger didn't run
        final fallback = UserProfile(
          id: user.id,
          fullName: (user.userMetadata?['full_name'] as String?) ??
              user.email?.split('@').first ??
              'Pengguna WijiBumi',
          email: user.email,
          phone: user.userMetadata?['phone'] as String?,
          role: (user.userMetadata?['role'] as String?) ?? 'buyer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final payload = Map<String, dynamic>.from(fallback.toJson())
          ..removeWhere((k, v) => (k == 'birth_date' || k == 'gender') && v == null);
        await client.from('profiles').upsert(payload);
        _activeDemoUser = fallback;
        return fallback;
      } catch (e) {
        debugPrint('Supabase getProfile error: $e');
        return null;
      }
    }
    return _activeDemoUser;
  }

  String _normalizeIndonesianPhone(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (trimmed.startsWith('+')) return trimmed;
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      return '+62${digits.substring(1)}';
    }
    if (digits.startsWith('62')) {
      return '+$digits';
    }
    return '+62$digits';
  }

  Future<AuthResult> login(String identifier, String password) async {
    final trimmed = identifier.trim();
    if (!isConnected) {
      if (buyerLoginTestHook != null) {
        return buyerLoginTestHook!(trimmed, password);
      }
      return const AuthResult(
        success: false,
        message: 'Layanan autentikasi belum terhubung ke server.',
      );
    }

    try {
      final client = SupabaseConfig.client!;
      final isEmail = trimmed.contains('@');
      String? resolvedEmail;
      if (!isEmail) {
        try {
          final lookup = await client.rpc(
            'resolve_login_email_by_phone',
            params: {'p_phone': _normalizeIndonesianPhone(trimmed)},
          );
          if (lookup is String && lookup.trim().contains('@')) {
            resolvedEmail = lookup.trim().toLowerCase();
          }
        } catch (e) {
          debugPrint('Phone login lookup warning: $e');
        }
      }
      final AuthResponse res = isEmail
          ? await client.auth.signInWithPassword(
              email: trimmed.toLowerCase(),
              password: password,
            )
          : resolvedEmail != null
              ? await client.auth.signInWithPassword(
                  email: resolvedEmail,
                  password: password,
                )
              : await client.auth.signInWithPassword(
                  phone: _normalizeIndonesianPhone(trimmed),
                  password: password,
                );

      if (res.user != null) {
        final profile = await getCurrentProfile();
        return AuthResult(success: true, profile: profile);
      }
      return const AuthResult(
        success: false,
        message: 'Gagal masuk. Periksa kembali akun dan kata sandi Anda.',
      );
    } on AuthException catch (e) {
      final lower = e.message.toLowerCase();
      if (lower.contains('email not confirmed')) {
        return const AuthResult(
          success: false,
          message:
              'Email Anda belum diverifikasi. Silakan cek kotak masuk email Anda terlebih dahulu.',
        );
      }
      if (lower.contains('invalid login credentials')) {
        return const AuthResult(
          success: false,
          message: 'Nomor HP/Email atau kata sandi salah. Silakan periksa kembali.',
        );
      }
      if (lower.contains('phone') &&
          (lower.contains('disabled') ||
              lower.contains('unsupported') ||
              lower.contains('provider'))) {
        return const AuthResult(
          success: false,
          message:
              'Login menggunakan nomor HP belum diaktifkan di server. Silakan masuk dengan email Anda.',
        );
      }
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: 'Gagal login: $e');
    }
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!isConnected) {
      if (buyerRegisterTestHook != null) {
        return buyerRegisterTestHook!(
          fullName: fullName.trim(),
          email: normalizedEmail,
          password: password,
          phone: phone.trim(),
        );
      }
      return const AuthResult(
        success: false,
        message: 'Layanan pendaftaran belum terhubung ke server.',
      );
    }

    try {
      final client = SupabaseConfig.client!;
      final res = await client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'role': 'buyer',
        },
      );
      if (res.user != null) {
        if (res.user!.identities != null && res.user!.identities!.isEmpty) {
          return const AuthResult(
            success: false,
            message: 'Email sudah terdaftar. Silakan masuk menggunakan akun Anda.',
          );
        }
        final needsConfirm = res.session == null;
        if (!needsConfirm) {
          await getCurrentProfile();
          try {
            await client.auth.signOut();
          } catch (_) {}
        }
        _activeDemoUser = null;
        return AuthResult(
          success: true,
          requiresEmailConfirmation: needsConfirm,
          message: needsConfirm
              ? 'Pendaftaran berhasil! Cek email Anda untuk verifikasi sebelum masuk.'
              : 'Akun berhasil didaftarkan! Silakan masuk menggunakan akun yang baru didaftarkan.',
        );
      }
      return const AuthResult(success: false, message: 'Pendaftaran gagal.');
    } on AuthException catch (e) {
      final lower = e.message.toLowerCase();
      if (lower.contains('already registered') || lower.contains('user already')) {
        return const AuthResult(
          success: false,
          message: 'Email sudah terdaftar. Silakan masuk menggunakan akun Anda.',
        );
      }
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: 'Gagal mendaftar: $e');
    }
  }

  Future<void> logout() async {
    if (isConnected) {
      try {
        await SupabaseConfig.client!.auth.signOut();
      } catch (e) {
        debugPrint('Supabase signOut error: $e');
      }
    }
    _activeDemoUser = null;
  }

  // ------------------ SELLER AUTH (SUPABASE AUTH) ------------------

  Future<SellerAuthResult> loginSeller(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!isConnected) {
      if (sellerLoginTestHook != null) {
        return sellerLoginTestHook!(normalizedEmail, password);
      }
      return const SellerAuthResult(
        status: SellerAuthStatus.notConfigured,
        message:
            'Layanan autentikasi penjual belum terhubung ke server. Silakan hubungi administrator atau coba beberapa saat lagi.',
      );
    }

    try {
      final client = SupabaseConfig.client!;
      final res = await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      final authUser = res.user;
      if (authUser == null) {
        return const SellerAuthResult(
          status: SellerAuthStatus.error,
          message: 'Gagal masuk. Periksa kembali email dan kata sandi Anda.',
        );
      }

      final profile = await getCurrentProfile();
      final sellerRow = await client
          .from('seller_profiles')
          .select()
          .eq('user_id', authUser.id)
          .maybeSingle();
      final storeRow = await client
          .from('stores')
          .select()
          .eq('owner_id', authUser.id)
          .maybeSingle();

      final hasSellerRole = (profile?.hasSellerAccess ?? false) ||
          (sellerRow != null && (sellerRow['is_seller_active'] as bool? ?? true)) ||
          storeRow != null;

      if (!hasSellerRole) {
        await client.auth.signOut();
        _activeDemoUser = null;
        return const SellerAuthResult(
          status: SellerAuthStatus.notSeller,
          message:
              'Akun ini belum terdaftar sebagai akun penjual. Silakan daftar akun penjual terlebih dahulu.',
        );
      }

      if (storeRow == null) {
        return SellerAuthResult(
          status: SellerAuthStatus.needsStoreRegistration,
          profile: profile,
          message: 'Akun penjual aktif. Lengkapi pendaftaran toko Anda untuk mulai berjualan.',
        );
      }

      return SellerAuthResult(
        status: SellerAuthStatus.success,
        profile: profile,
        store: Store.fromJson(storeRow),
      );
    } on AuthException catch (e) {
      final lower = e.message.toLowerCase();
      if (lower.contains('email not confirmed')) {
        return const SellerAuthResult(
          status: SellerAuthStatus.emailNotVerified,
          message: 'Email Anda belum diverifikasi. Silakan cek kotak masuk email Anda terlebih dahulu.',
        );
      }
      if (lower.contains('invalid login credentials')) {
        return const SellerAuthResult(
          status: SellerAuthStatus.error,
          message: 'Email atau password salah. Silakan periksa kembali.',
        );
      }
      return SellerAuthResult(status: SellerAuthStatus.error, message: e.message);
    } catch (e) {
      return SellerAuthResult(
        status: SellerAuthStatus.error,
        message: 'Terjadi kesalahan saat login penjual: $e',
      );
    }
  }

  Future<SellerAuthResult> registerSeller({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!isConnected) {
      if (sellerRegisterTestHook != null) {
        return sellerRegisterTestHook!(
          fullName: fullName.trim(),
          email: normalizedEmail,
          password: password,
          phone: phone.trim(),
        );
      }
      return const SellerAuthResult(
        status: SellerAuthStatus.notConfigured,
        message:
            'Layanan pendaftaran penjual belum terhubung ke server. Silakan hubungi administrator atau coba beberapa saat lagi.',
      );
    }

    try {
      final client = SupabaseConfig.client!;
      final res = await client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'role': 'seller',
        },
      );

      final authUser = res.user;
      if (authUser == null) {
        return const SellerAuthResult(
          status: SellerAuthStatus.error,
          message: 'Pendaftaran akun penjual gagal. Silakan coba lagi.',
        );
      }

      if (authUser.identities != null && authUser.identities!.isEmpty) {
        return const SellerAuthResult(
          status: SellerAuthStatus.error,
          message:
              'Email sudah terdaftar. Silakan masuk melalui Login Penjual atau aktifkan akun penjual Anda.',
        );
      }

      if (res.session == null) {
        return const SellerAuthResult(
          status: SellerAuthStatus.emailNotVerified,
          message:
              'Pendaftaran berhasil! Tautan verifikasi telah dikirim ke email Anda. Silakan verifikasi email sebelum masuk melalui Login Penjual.',
        );
      }

      // Ensure seller_profiles & role are created in database
      try {
        await client.rpc('activate_seller_account', params: {
          'p_full_name': fullName.trim(),
          'p_phone': phone.trim(),
        });
      } catch (_) {
        await client.from('profiles').upsert({
          'id': authUser.id,
          'full_name': fullName.trim(),
          'email': normalizedEmail,
          'phone': phone.trim(),
          'role': 'seller',
        });
        await client.from('seller_profiles').upsert({
          'user_id': authUser.id,
          'full_name': fullName.trim(),
          'email': normalizedEmail,
          'phone': phone.trim(),
          'is_seller_active': true,
        }, onConflict: 'user_id');
      }

      try {
        await client.auth.signOut();
      } catch (_) {}
      _activeDemoUser = null;

      return const SellerAuthResult(
        status: SellerAuthStatus.success,
        message:
            'Akun penjual berhasil didaftarkan! Silakan login terlebih dahulu menggunakan email dan password yang sudah didaftarkan.',
      );
    } on AuthException catch (e) {
      final lower = e.message.toLowerCase();
      if (lower.contains('already registered') || lower.contains('user already')) {
        return const SellerAuthResult(
          status: SellerAuthStatus.error,
          message: 'Email sudah terdaftar. Silakan masuk melalui Login Penjual.',
        );
      }
      return SellerAuthResult(status: SellerAuthStatus.error, message: e.message);
    } catch (e) {
      return SellerAuthResult(
        status: SellerAuthStatus.error,
        message: 'Gagal mendaftarkan akun penjual: $e',
      );
    }
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    final normalized = email.trim().toLowerCase();
    if (!isConnected) {
      if (forgotPasswordTestHook != null) {
        return forgotPasswordTestHook!(normalized);
      }
      return const AuthResult(
        success: false,
        message: 'Layanan reset password membutuhkan koneksi server yang aktif.',
      );
    }
    try {
      await SupabaseConfig.client!.auth.resetPasswordForEmail(normalized);
      return const AuthResult(
        success: true,
        message: 'Tautan reset password telah dikirim ke email Anda.',
      );
    } on AuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: 'Gagal mengirim reset password: $e');
    }
  }

  Future<ProfileUpdateResult> updateProfile(
    UserProfile profile, {
    String? newEmail,
  }) async {
    final trimmedNewEmail = newEmail?.trim();
    final emailChanged = trimmedNewEmail != null &&
        trimmedNewEmail.isNotEmpty &&
        trimmedNewEmail.toLowerCase() != (profile.email ?? '').toLowerCase();

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final uid = client.auth.currentUser?.id;
        if (uid == null) {
          return const ProfileUpdateResult(success: false, errorMessage: 'Sesi tidak aktif.');
        }

        bool verificationSent = false;
        if (emailChanged) {
          await client.auth.updateUser(UserAttributes(email: trimmedNewEmail));
          verificationSent = true;
        }

        final birthDateSql = profile.birthDate != null
            ? DateFormatter.formatSqlDate(profile.birthDate!)
            : null;
        final fullPayload = <String, dynamic>{
          'full_name': profile.fullName,
          'phone': profile.phone,
          'avatar_path': profile.avatarPath,
          'birth_date': birthDateSql,
          'gender': profile.gender,
          if (!emailChanged) 'email': profile.email,
          'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          await client.from('profiles').update(fullPayload).eq('id', uid);
        } on PostgrestException catch (e) {
          final msgLower = e.message.toLowerCase();
          final missingExtendedCol =
              msgLower.contains('birth_date') || msgLower.contains('gender');
          if (!missingExtendedCol) rethrow;
          if (profile.birthDate != null || profile.gender != null) {
            return const ProfileUpdateResult(
              success: false,
              errorMessage:
                  'Kolom tanggal lahir / jenis kelamin belum tersedia di database. Jalankan migrasi 006_add_profile_birth_date_gender.sql terlebih dahulu.',
            );
          }
          await client.from('profiles').update({
            'full_name': profile.fullName,
            'phone': profile.phone,
            'avatar_path': profile.avatarPath,
            if (!emailChanged) 'email': profile.email,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', uid);
        }

        if (profile.hasSellerAccess) {
          try {
            await client.from('seller_profiles').update({
              'full_name': profile.fullName,
              'phone': profile.phone,
              if (!emailChanged) 'email': profile.email,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('user_id', uid);
          } catch (_) {}
        }

        _activeDemoUser = profile;
        return ProfileUpdateResult(success: true, emailVerificationSent: verificationSent);
      } on AuthException catch (e) {
        return ProfileUpdateResult(success: false, errorMessage: e.message);
      } catch (e) {
        return ProfileUpdateResult(success: false, errorMessage: 'Gagal memperbarui profil: $e');
      }
    }

    final updated = emailChanged ? profile.copyWith(email: trimmedNewEmail) : profile;
    _activeDemoUser = updated;
    final idx = _demoUsers.indexWhere((u) => u.id == updated.id);
    if (idx != -1) {
      _demoUsers[idx] = updated;
    }
    return ProfileUpdateResult(success: true, emailVerificationSent: emailChanged);
  }

  Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final user = client.auth.currentUser;
        if (user == null ||
            ((user.email ?? '').isEmpty && (user.phone ?? '').isEmpty)) {
          return const AuthResult(
            success: false,
            message: 'Pengguna tidak terautentikasi.',
          );
        }
        // Re-authenticate with old password to validate ownership
        if (user.email != null && user.email!.isNotEmpty) {
          await client.auth.signInWithPassword(
            email: user.email!,
            password: oldPassword,
          );
        } else {
          await client.auth.signInWithPassword(
            phone: user.phone!,
            password: oldPassword,
          );
        }
        await client.auth.updateUser(UserAttributes(password: newPassword));
        return const AuthResult(
          success: true,
          message: 'Password berhasil diperbarui melalui Supabase Auth.',
        );
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase().contains('invalid')
            ? 'Password lama tidak sesuai.'
            : e.message;
        return AuthResult(success: false, message: msg);
      } catch (e) {
        return AuthResult(success: false, message: 'Gagal mengubah password: $e');
      }
    }

    // Demo mode password change (kept strictly in memory, never in DB)
    final uid = _activeDemoUser?.id;
    if (uid == null) {
      return const AuthResult(success: false, message: 'Silakan masuk terlebih dahulu.');
    }
    final expectedOld = _demoPasswords[uid] ?? 'password123';
    if (oldPassword != expectedOld) {
      return const AuthResult(success: false, message: 'Password lama tidak sesuai.');
    }
    _demoPasswords[uid] = newPassword;
    return const AuthResult(success: true, message: 'Password akun berhasil diperbarui.');
  }

  Future<void> refreshAuthUser() async {
    if (!isConnected) return;
    try {
      await SupabaseConfig.client?.auth.getUser();
    } catch (e) {
      debugPrint('Supabase auth.getUser refresh note: $e');
    }
  }

  Future<AuthResult> resendVerificationEmail() async {
    if (!isConnected) {
      return const AuthResult(
        success: false,
        message: 'Pengiriman ulang email verifikasi memerlukan koneksi server.',
      );
    }
    try {
      final client = SupabaseConfig.client!;
      final user = client.auth.currentUser;
      if (user == null) {
        return const AuthResult(
          success: false,
          message: 'Silakan masuk terlebih dahulu untuk mengirim verifikasi email.',
        );
      }
      final pendingEmail = user.newEmail?.trim();
      if (pendingEmail != null && pendingEmail.isNotEmpty) {
        await client.auth.resend(
          type: OtpType.emailChange,
          email: pendingEmail,
        );
        return AuthResult(
          success: true,
          message: 'Tautan konfirmasi email baru telah dikirim ulang ke $pendingEmail.',
        );
      }
      final email = user.email?.trim();
      if (email == null || email.isEmpty) {
        return const AuthResult(
          success: false,
          message: 'Alamat email belum terdaftar pada akun ini.',
        );
      }
      if (user.emailConfirmedAt != null) {
        return const AuthResult(
          success: true,
          message: 'Email akun Anda sudah terverifikasi.',
        );
      }
      await client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      return AuthResult(
        success: true,
        message: 'Tautan verifikasi email telah dikirim ulang ke $email.',
      );
    } on AuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Gagal mengirim ulang email verifikasi: $e',
      );
    }
  }

  Future<AuthResult> updateRecoveredPassword(String newPassword) async {
    if (!isConnected) {
      return const AuthResult(
        success: false,
        message: 'Pembaruan kata sandi membutuhkan koneksi server.',
      );
    }
    try {
      await SupabaseConfig.client!.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return const AuthResult(
        success: true,
        message: 'Kata sandi baru berhasil disimpan.',
      );
    } on AuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Gagal menyimpan kata sandi baru: $e',
      );
    }
  }

  Future<AuthResult> deleteAccount() async {
    if (!isConnected && deleteAccountTestHook != null) {
      final result = await deleteAccountTestHook!();
      if (result.success) {
        _activeDemoUser = null;
      }
      return result;
    }

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final user = client.auth.currentUser;
        if (user == null) {
          return const AuthResult(
            success: false,
            message: 'Sesi pengguna tidak ditemukan. Silakan masuk kembali.',
          );
        }
        await client.rpc('delete_my_account');
        try {
          await client.auth.signOut();
        } catch (_) {}
        _activeDemoUser = null;
        return const AuthResult(
          success: true,
          message: 'Akun Anda telah dihapus secara permanen.',
        );
      } on PostgrestException catch (e) {
        return AuthResult(success: false, message: e.message);
      } on AuthException catch (e) {
        return AuthResult(success: false, message: e.message);
      } catch (e) {
        return AuthResult(success: false, message: 'Gagal menghapus akun: $e');
      }
    }

    final uid = _activeDemoUser?.id;
    if (uid == null) {
      return const AuthResult(
        success: false,
        message: 'Silakan masuk terlebih dahulu.',
      );
    }
    const activeStatuses = {
      'pending_payment',
      'awaiting_confirmation',
      'processing',
      'ready_to_ship',
      'shipped',
    };
    final hasActiveOrders = orders.any(
      (o) => o.buyerId == uid && activeStatuses.contains(o.status),
    );
    if (hasActiveOrders) {
      return const AuthResult(
        success: false,
        message:
            'Selesaikan atau batalkan seluruh pesanan aktif Anda sebelum menghapus akun.',
      );
    }
    final myStoreIds = stores.where((s) => s.ownerId == uid).map((s) => s.id).toSet();
    final hasSellerOrderHistory = orders.any((o) => myStoreIds.contains(o.storeId));
    if (hasSellerOrderHistory) {
      return const AuthResult(
        success: false,
        message:
            'Akun pemilik toko yang memiliki riwayat pesanan tidak dapat dihapus otomatis.',
      );
    }

    _demoUsers.removeWhere((u) => u.id == uid);
    _demoPasswords.remove(uid);
    addresses.removeWhere((a) => a.userId == uid);
    cartItems.clear();
    _activeDemoUser = null;
    return const AuthResult(
      success: true,
      message: 'Akun berhasil dihapus.',
    );
  }

  Map<String, dynamic> getSecurityInfo() {
    if (isConnected) {
      final user = SupabaseConfig.client?.auth.currentUser;
      return {
        'email': user?.email ?? '-',
        'pendingEmail': user?.newEmail,
        'emailVerified': user?.emailConfirmedAt != null,
        'phone': user?.phone,
        'phoneVerified': user?.phoneConfirmedAt != null,
        'lastSignInAt': user?.lastSignInAt,
        'provider': (user?.appMetadata['provider'] as String?) ?? 'email',
        'isSupabaseLive': true,
      };
    }
    return {
      'email': _activeDemoUser?.email ?? '-',
      'pendingEmail': null,
      'emailVerified': false,
      'phone': _activeDemoUser?.phone,
      'phoneVerified': false,
      'lastSignInAt': DateTime.now().toIso8601String(),
      'provider': 'Mode Demo Lokal',
      'isSupabaseLive': false,
    };
  }

  Map<String, dynamic> getProfileVerificationStatus({
    String? draftEmail,
    String? draftPhone,
  }) {
    if (!isConnected && profileVerificationTestHook != null) {
      return profileVerificationTestHook!(draftEmail, draftPhone);
    }
    if (!isConnected) {
      return {
        'emailVerified': false,
        'phoneVerified': false,
        'pendingEmail': null,
        'isSupabaseLive': false,
      };
    }

    final user = SupabaseConfig.client?.auth.currentUser;
    final authEmail = (user?.email ?? '').trim().toLowerCase();
    final targetEmail = (draftEmail ?? authEmail).trim().toLowerCase();
    final pendingEmail = user?.newEmail;
    final isEmailVerified = user != null &&
        user.emailConfirmedAt != null &&
        targetEmail.isNotEmpty &&
        targetEmail == authEmail &&
        (pendingEmail == null || pendingEmail.trim().toLowerCase() != targetEmail);

    final authPhone = (user?.phone ?? '').trim();
    final targetPhone = (draftPhone ?? authPhone).trim();
    final normalizedAuthPhone =
        authPhone.isNotEmpty ? _normalizeIndonesianPhone(authPhone) : '';
    final normalizedTargetPhone =
        targetPhone.isNotEmpty ? _normalizeIndonesianPhone(targetPhone) : '';
    final isPhoneVerified = user != null &&
        user.phoneConfirmedAt != null &&
        normalizedAuthPhone.isNotEmpty &&
        normalizedTargetPhone == normalizedAuthPhone;

    return {
      'emailVerified': isEmailVerified,
      'phoneVerified': isPhoneVerified,
      'pendingEmail': (pendingEmail != null && pendingEmail.isNotEmpty)
          ? pendingEmail
          : null,
      'isSupabaseLive': true,
    };
  }

  // ------------------ STORES ------------------

  Future<List<Store>> getStores() async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client
            .from('stores')
            .select()
            .eq('verification_status', 'approved')
            .eq('is_active', true);
        return (res as List).map((e) => Store.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getStores error: $e');
        rethrow;
      }
    }
    return stores.where((s) => s.isApproved).toList();
  }

  Future<Store?> getStoreById(String storeId) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('stores').select().eq('id', storeId).maybeSingle();
        return res != null ? Store.fromJson(res) : null;
      } catch (e) {
        debugPrint('Supabase getStoreById error: $e');
        rethrow;
      }
    }
    try {
      return stores.firstWhere((s) => s.id == storeId);
    } catch (_) {
      return null;
    }
  }

  Future<Store?> getMyStore() async {
    final uid = activeUserId;
    if (uid == null) return null;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('stores').select().eq('owner_id', uid).maybeSingle();
        if (res != null) return Store.fromJson(res);
        return null;
      } catch (e) {
        debugPrint('Supabase getMyStore error: $e');
        return null;
      }
    }
    try {
      return stores.firstWhere((s) => s.ownerId == uid);
    } catch (_) {
      return null;
    }
  }

  Future<Store> registerStore({
    required String storeName,
    required String description,
    required String email,
    required String phone,
    required String address,
    required String province,
    required String city,
    required String district,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? logoPath,
    String? operatingHours,
  }) async {
    final uid = activeUserId ?? currentUser.id;
    final rawSlug =
        storeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final slugBase = rawSlug.isNotEmpty ? rawSlug : 'toko';
    final slug = '$slugBase-${DateTime.now().millisecondsSinceEpoch % 1000000}';

    // Enforce pending verification status by default (never auto-approved by client)
    final newStore = Store(
      id: 'store-${DateTime.now().millisecondsSinceEpoch}',
      ownerId: uid,
      storeName: storeName,
      slug: slug,
      description: description,
      email: email,
      phone: phone,
      address: address,
      province: province,
      city: city,
      district: district,
      postalCode: postalCode,
      latitude: latitude,
      longitude: longitude,
      operatingHours: operatingHours ?? '06:00 - 17:00 WIB',
      logoPath: logoPath ??
          'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&w=300&q=80',
      verificationStatus: 'pending',
      verificationNote: 'Menunggu verifikasi tim WijiBumi.',
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isConnected) {
      final client = SupabaseConfig.client!;
      final payload = newStore.toJson(includeId: false, includeVerification: false);
      final res = await client.from('stores').insert(payload).select().single();
      final created = Store.fromJson(res);
      try {
        await client.rpc('activate_seller_account');
      } catch (_) {}
      await _createNotification(
        userId: uid,
        type: 'system',
        title: 'Pendaftaran Toko Dikirim',
        body: 'Toko "${created.storeName}" sedang menunggu verifikasi tim WijiBumi.',
        referenceId: created.id,
      );
      return created;
    }

    stores.add(newStore);
    await _createNotification(
      userId: uid,
      type: 'system',
      title: 'Pendaftaran Toko Dikirim',
      body: 'Toko "${newStore.storeName}" sedang menunggu verifikasi tim WijiBumi.',
      referenceId: newStore.id,
    );
    return newStore;
  }

  Future<bool> updateStore(Store store) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final payload = {
          'store_name': store.storeName,
          'description': store.description,
          'logo_path': store.logoPath,
          'email': store.email,
          'phone': store.phone,
          'address': store.address,
          'province': store.province,
          'city': store.city,
          'district': store.district,
          'postal_code': store.postalCode,
          'latitude': store.latitude,
          'longitude': store.longitude,
          'operating_hours': store.operatingHours,
          'updated_at': DateTime.now().toIso8601String(),
        };
        await client.from('stores').update(payload).eq('id', store.id);
        return true;
      } catch (e) {
        debugPrint('Supabase updateStore error: $e');
        return false;
      }
    }

    final idx = stores.indexWhere((s) => s.id == store.id);
    if (idx != -1) stores[idx] = store;
    return true;
  }

  // ------------------ PRODUCTS ------------------

  Future<List<Category>> getCategories() async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('categories').select();
        final fetched = (res as List).map((e) => Category.fromJson(e)).toList();
        if (fetched.isNotEmpty) {
          final existingSlugs = fetched.map((c) => c.slug.toLowerCase()).toSet();
          final merged = [
            ...fetched,
            ...MockData.categories.where(
              (fallback) => !existingSlugs.contains(fallback.slug.toLowerCase()),
            ),
          ];
          categories = merged;
          return merged;
        }
        return [];
      } catch (e) {
        debugPrint('Supabase getCategories error: $e');
        rethrow;
      }
    }
    return categories;
  }

  bool _matchesProductSearch(Product p, String queryLower) {
    return p.name.toLowerCase().contains(queryLower) ||
        (p.storeName?.toLowerCase().contains(queryLower) ?? false) ||
        (p.categoryName?.toLowerCase().contains(queryLower) ?? false) ||
        (p.description?.toLowerCase().contains(queryLower) ?? false) ||
        (p.farmLocation?.toLowerCase().contains(queryLower) ?? false);
  }

  Future<List<Product>> getProducts({String? categoryId, String? searchQuery, String? storeId}) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        var query = client.from('products').select('''
          *,
          stores!inner (store_name, city, logo_path, verification_status, is_active),
          categories (name),
          product_images (storage_path)
        ''').eq('status', 'active').eq('stores.verification_status', 'approved').eq('stores.is_active', true);

        if (categoryId != null && categoryId.isNotEmpty) {
          final isUuid = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          ).hasMatch(categoryId);
          if (!isUuid) {
            return [];
          }
          query = query.eq('category_id', categoryId);
        }
        if (storeId != null && storeId.isNotEmpty) {
          query = query.eq('store_id', storeId);
        }

        final res = await query;
        var list = (res as List).map((e) => Product.fromJson(e)).toList();
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final q = searchQuery.trim().toLowerCase();
          list = list.where((p) => _matchesProductSearch(p, q)).toList();
        }
        return list;
      } catch (e) {
        debugPrint('Supabase getProducts error: $e');
        rethrow;
      }
    }

    final approvedStoreIds = stores.where((s) => s.isApproved).map((s) => s.id).toSet();
    var list = products
        .where((p) => p.status == 'active' && approvedStoreIds.contains(p.storeId))
        .toList();
    if (categoryId != null && categoryId.isNotEmpty) {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }
    if (storeId != null && storeId.isNotEmpty) {
      list = list.where((p) => p.storeId == storeId).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((p) => _matchesProductSearch(p, q)).toList();
    }
    return list;
  }

  Future<List<Product>> getStoreProducts(String storeId) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('products').select('''
          *,
          stores (store_name, city, logo_path),
          categories (name),
          product_images (storage_path)
        ''').eq('store_id', storeId).order('created_at', ascending: false);
        return (res as List).map((e) => Product.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getStoreProducts error: $e');
        rethrow;
      }
    }
    return products.where((p) => p.storeId == storeId).toList();
  }

  Future<Product> addProduct(Product product) async {
    if (isConnected) {
      final client = SupabaseConfig.client!;
      final payload = product.toJson(includeId: false);
      final res = await client.from('products').insert(payload).select('''
        *,
        stores (store_name, city, logo_path),
        categories (name)
      ''').single();
      final created = Product.fromJson(res);
      if (product.images.isNotEmpty) {
        for (int i = 0; i < product.images.length; i++) {
          await client.from('product_images').insert({
            'product_id': created.id,
            'storage_path': product.images[i],
            'sort_order': i,
            'is_primary': i == 0,
          });
        }
      }
      return created.copyWith(images: product.images);
    }

    products.insert(0, product);
    return product;
  }

  Future<bool> updateProduct(Product product) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client
            .from('products')
            .update(product.toJson(includeId: false))
            .eq('id', product.id);
        if (product.images.isNotEmpty) {
          await client.from('product_images').delete().eq('product_id', product.id);
          for (int i = 0; i < product.images.length; i++) {
            await client.from('product_images').insert({
              'product_id': product.id,
              'storage_path': product.images[i],
              'sort_order': i,
              'is_primary': i == 0,
            });
          }
        }
        return true;
      } catch (e) {
        debugPrint('Supabase updateProduct error: $e');
        return false;
      }
    }

    final idx = products.indexWhere((p) => p.id == product.id);
    if (idx != -1) products[idx] = product;
    return true;
  }

  Future<bool> deleteProduct(String productId) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client.from('products').delete().eq('id', productId);
        return true;
      } catch (e) {
        debugPrint('Supabase deleteProduct error: $e');
        return false;
      }
    }
    products.removeWhere((p) => p.id == productId);
    return true;
  }

  // ------------------ CART ------------------

  Future<List<CartItem>> getCart() async {
    final uid = activeUserId;
    if (uid == null) return [];

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('cart_items').select('''
          *,
          products (
            *,
            stores (store_name, city, logo_path),
            categories (name),
            product_images (storage_path)
          )
        ''').eq('user_id', uid);
        return (res as List).map((e) => CartItem.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getCart error: $e');
        rethrow;
      }
    }
    return cartItems.where((c) => c.userId == uid).toList();
  }

  Future<bool> addToCart(Product product, int quantity) async {
    final uid = activeUserId;
    if (uid == null || quantity <= 0 || !product.isAvailable) return false;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final existing = await client
            .from('cart_items')
            .select()
            .eq('user_id', uid)
            .eq('product_id', product.id)
            .maybeSingle();
        final nextQty = ((existing?['quantity'] as num?)?.toInt() ?? 0) + quantity;
        if (nextQty > product.stock) return false;
        await client.from('cart_items').upsert({
          'user_id': uid,
          'product_id': product.id,
          'quantity': nextQty,
        }, onConflict: 'user_id,product_id');
        return true;
      } catch (e) {
        debugPrint('Supabase addToCart error: $e');
        return false;
      }
    }

    final existingIdx = cartItems.indexWhere((c) => c.userId == uid && c.productId == product.id);
    if (existingIdx != -1) {
      if (cartItems[existingIdx].quantity + quantity > product.stock) {
        return false;
      }
      cartItems[existingIdx].quantity += quantity;
    } else {
      if (quantity > product.stock) return false;
      cartItems.add(
        CartItem(
          id: 'cart-${DateTime.now().millisecondsSinceEpoch}',
          userId: uid,
          productId: product.id,
          quantity: quantity,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          product: product,
        ),
      );
    }
    return true;
  }

  Future<bool> updateCartQuantity(String cartItemId, int newQty) async {
    final uid = activeUserId;
    if (uid == null) return false;

    if (newQty <= 0) {
      return await removeFromCart(cartItemId);
    }

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final existing = await client
            .from('cart_items')
            .select('id, products(stock, status)')
            .eq('id', cartItemId)
            .eq('user_id', uid)
            .maybeSingle();
        if (existing == null || existing['products'] is! Map) return false;
        final productMap = existing['products'] as Map<String, dynamic>;
        final status = productMap['status'] as String? ?? 'inactive';
        final stock = (productMap['stock'] as num?)?.toInt() ?? 0;
        if (status != 'active' || stock <= 0 || newQty > stock) {
          return false;
        }
        await client
            .from('cart_items')
            .update({'quantity': newQty})
            .eq('id', cartItemId)
            .eq('user_id', uid);
        return true;
      } catch (e) {
        debugPrint('Supabase updateCartQuantity error: $e');
        return false;
      }
    }

    final idx = cartItems.indexWhere((c) => c.id == cartItemId && c.userId == uid);
    if (idx == -1) return false;
    final item = cartItems[idx];
    final linkedProduct = products.where((p) => p.id == item.productId).firstOrNull ?? item.product;
    if (linkedProduct == null || !linkedProduct.isAvailable || newQty > linkedProduct.stock) {
      return false;
    }
    item.quantity = newQty;
    return true;
  }

  Future<bool> removeFromCart(String cartItemId) async {
    final uid = activeUserId;
    if (uid == null) return false;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client
            .from('cart_items')
            .delete()
            .eq('id', cartItemId)
            .eq('user_id', uid);
        return true;
      } catch (e) {
        debugPrint('Supabase removeFromCart error: $e');
        return false;
      }
    }
    cartItems.removeWhere((c) => c.id == cartItemId && c.userId == uid);
    return true;
  }

  Future<bool> clearCart() async {
    final uid = activeUserId;
    if (uid == null) return false;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client.from('cart_items').delete().eq('user_id', uid);
        return true;
      } catch (e) {
        debugPrint('Supabase clearCart error: $e');
        return false;
      }
    }
    cartItems.removeWhere((c) => c.userId == uid);
    return true;
  }

  // ------------------ ADDRESSES ------------------

  Future<List<Address>> getAddresses() async {
    final uid = activeUserId;
    if (uid == null) return [];

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client
            .from('addresses')
            .select()
            .eq('user_id', uid)
            .order('is_default', ascending: false)
            .order('created_at', ascending: false);
        return (res as List).map((e) => Address.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getAddresses error: $e');
        rethrow;
      }
    }
    final list = addresses.where((a) => a.userId == uid).toList();
    list.sort((a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
    return list;
  }

  Future<Address> addAddress(Address address) async {
    final uid = activeUserId ?? address.userId;

    if (isConnected) {
      final client = SupabaseConfig.client!;
      final payload = address.copyWith().toJson(includeId: false)..['user_id'] = uid;
      final res = await client.from('addresses').insert(payload).select().single();
      final created = Address.fromJson(res);
      if (address.isDefault) {
        try {
          await client
              .from('addresses')
              .update({'is_default': false})
              .eq('user_id', uid)
              .neq('id', created.id)
              .eq('is_default', true);
        } catch (e) {
          debugPrint('Supabase clear previous default address note: $e');
        }
      }
      return created;
    }

    if (address.isDefault) {
      for (int i = 0; i < addresses.length; i++) {
        if (addresses[i].userId == uid && addresses[i].isDefault) {
          addresses[i] = addresses[i].copyWith(isDefault: false);
        }
      }
    }
    addresses.insert(0, address);
    return address;
  }

  Future<bool> updateAddress(Address address) async {
    final uid = activeUserId ?? address.userId;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client
            .from('addresses')
            .update(address.toJson(includeId: false))
            .eq('id', address.id)
            .eq('user_id', uid);
        if (address.isDefault) {
          await client
              .from('addresses')
              .update({'is_default': false})
              .eq('user_id', uid)
              .neq('id', address.id)
              .eq('is_default', true);
        }
        return true;
      } catch (e) {
        debugPrint('Supabase updateAddress error: $e');
        return false;
      }
    }

    if (address.isDefault) {
      for (int i = 0; i < addresses.length; i++) {
        if (addresses[i].userId == uid && addresses[i].isDefault) {
          addresses[i] = addresses[i].copyWith(isDefault: false);
        }
      }
    }
    final idx = addresses.indexWhere((a) => a.id == address.id);
    if (idx != -1) addresses[idx] = address;
    return true;
  }

  Future<bool> deleteAddress(String addressId) async {
    final uid = activeUserId;
    if (uid == null) return false;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client.from('addresses').delete().eq('id', addressId).eq('user_id', uid);
        return true;
      } catch (e) {
        debugPrint('Supabase deleteAddress error: $e');
        return false;
      }
    }
    addresses.removeWhere((a) => a.id == addressId && a.userId == uid);
    return true;
  }

  Future<bool> setDefaultAddress(String addressId) async {
    final uid = activeUserId;
    if (uid == null) return false;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        try {
          await client.rpc(
            'set_default_address',
            params: {'p_address_id': addressId},
          );
          return true;
        } on PostgrestException catch (e) {
          final lower = e.message.toLowerCase();
          final rpcMissing = e.code == 'PGRST202' ||
              e.code == '42883' ||
              lower.contains('set_default_address');
          if (!rpcMissing) rethrow;
        }

        // Legacy fallback when migration 010 RPC hasn't been applied yet
        final owned = await client
            .from('addresses')
            .select('id')
            .eq('id', addressId)
            .eq('user_id', uid)
            .maybeSingle();
        if (owned == null) return false;

        await client
            .from('addresses')
            .update({'is_default': true})
            .eq('id', addressId)
            .eq('user_id', uid);
        await client
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', uid)
            .neq('id', addressId)
            .eq('is_default', true);
        return true;
      } catch (e) {
        debugPrint('Supabase setDefaultAddress error: $e');
        return false;
      }
    }

    for (int i = 0; i < addresses.length; i++) {
      if (addresses[i].userId == uid) {
        addresses[i] = addresses[i].copyWith(isDefault: addresses[i].id == addressId);
      }
    }
    return true;
  }

  // ------------------ ORDERS & CHECKOUT ------------------

  Future<List<Order>> getOrders({String? status, String? storeId}) async {
    final uid = activeUserId;
    if (uid == null) return [];

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        var query = client.from('orders').select('''
          *,
          stores (store_name),
          profiles:buyer_id (full_name),
          order_items (*),
          shipments (
            *,
            shipment_tracking (*)
          ),
          payments (*)
        ''');

        if (storeId != null && storeId.isNotEmpty) {
          query = query.eq('store_id', storeId);
        } else {
          query = query.eq('buyer_id', uid);
        }

        if (status != null && status.isNotEmpty) {
          query = query.eq('status', status);
        }

        final res = await query.order('created_at', ascending: false);
        return (res as List).map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          if (map['profiles'] is Map) {
            map['buyer_name'] = map['profiles']['full_name'];
          }
          return Order.fromJson(map);
        }).toList();
      } catch (e) {
        debugPrint('Supabase getOrders error: $e');
        rethrow;
      }
    }

    var list = List<Order>.from(orders);
    if (storeId != null && storeId.isNotEmpty) {
      list = list.where((o) => o.storeId == storeId).toList();
    } else {
      list = list.where((o) => o.buyerId == uid).toList();
    }
    if (status != null && status.isNotEmpty) {
      list = list.where((o) => o.status == status).toList();
    }
    return list;
  }

  Future<List<Order>> createCheckoutOrders({
    required Address address,
    required String paymentMethod,
    required String courierName,
    required String? buyerNote,
  }) async {
    final uid = activeUserId;
    if (uid == null) {
      throw Exception('Silakan masuk ke akun WijiBumi terlebih dahulu.');
    }

    if (isConnected) {
      final client = SupabaseConfig.client!;
      final res = await client.rpc('create_checkout_orders', params: {
        'p_address_id': address.id,
        'p_payment_method': paymentMethod,
        'p_courier_name': courierName,
        'p_buyer_note': buyerNote,
      });
      return _hydrateCreatedOrders(res as List);
    }

    final userCart = cartItems.where((c) => c.userId == uid).toList();
    if (userCart.isEmpty) {
      throw Exception('Keranjang belanja kosong.');
    }
    final validEntries = <({Product product, int quantity})>[];
    for (final item in userCart) {
      final linkedProduct = products.where((p) => p.id == item.productId).firstOrNull ?? item.product;
      if (linkedProduct == null) {
        throw Exception('Sebagian produk di keranjang sudah tidak tersedia.');
      }
      validEntries.add((product: linkedProduct, quantity: item.quantity));
    }

    return _buildAndStoreDemoOrders(
      uid: uid,
      entries: validEntries,
      address: address,
      paymentMethod: paymentMethod,
      courierName: courierName,
      buyerNote: buyerNote,
      clearCartAfter: true,
    );
  }

  Future<List<Order>> createDirectOrder({
    required Address address,
    required Product product,
    required int quantity,
    required String paymentMethod,
    required String courierName,
    required String? buyerNote,
  }) async {
    final uid = activeUserId;
    if (uid == null) {
      throw Exception('Silakan masuk ke akun WijiBumi terlebih dahulu.');
    }
    if (quantity <= 0) {
      throw Exception('Jumlah pembelian minimal 1.');
    }

    if (isConnected) {
      final client = SupabaseConfig.client!;
      try {
        final res = await client.rpc('create_direct_order', params: {
          'p_address_id': address.id,
          'p_product_id': product.id,
          'p_quantity': quantity,
          'p_payment_method': paymentMethod,
          'p_courier_name': courierName,
          'p_buyer_note': buyerNote,
        });
        return await _hydrateCreatedOrders(res as List);
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST202' ||
            e.message.toLowerCase().contains('create_direct_order')) {
          throw Exception(
            'Fungsi Beli Sekarang belum tersedia di server. Jalankan migrasi 007 atau gunakan keranjang.',
          );
        }
        rethrow;
      }
    }

    final liveProduct = products.where((p) => p.id == product.id).firstOrNull ?? product;
    return _buildAndStoreDemoOrders(
      uid: uid,
      entries: [(product: liveProduct, quantity: quantity)],
      address: address,
      paymentMethod: paymentMethod,
      courierName: courierName,
      buyerNote: buyerNote,
      clearCartAfter: false,
    );
  }

  Future<List<Order>> _hydrateCreatedOrders(List<dynamic> createdRows) async {
    final createdIds = createdRows
        .map((r) => (r as Map)['id']?.toString())
        .whereType<String>()
        .toSet();
    if (createdIds.isEmpty) return [];
    try {
      final allBuyerOrders = await getOrders();
      final matched = allBuyerOrders.where((o) => createdIds.contains(o.id)).toList();
      if (matched.isNotEmpty) return matched;
    } catch (e) {
      debugPrint('Supabase hydrate created orders warning: $e');
    }
    return createdRows
        .map((r) => Order.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<List<Order>> _buildAndStoreDemoOrders({
    required String uid,
    required List<({Product product, int quantity})> entries,
    required Address address,
    required String paymentMethod,
    required String courierName,
    required String? buyerNote,
    required bool clearCartAfter,
  }) async {
    if (entries.isEmpty) {
      throw Exception('Tidak ada produk yang dapat diproses.');
    }

    // Aggregate quantities per product to validate stock atomically first
    final requestedByProduct = <String, int>{};
    for (final entry in entries) {
      if (!entry.product.isAvailable) {
        throw Exception('Produk "${entry.product.name}" sedang tidak aktif atau habis.');
      }
      requestedByProduct[entry.product.id] =
          (requestedByProduct[entry.product.id] ?? 0) + entry.quantity;
    }
    for (final entry in entries) {
      final needed = requestedByProduct[entry.product.id] ?? entry.quantity;
      if (entry.product.stock < needed) {
        throw Exception(
          'Stok produk "${entry.product.name}" tidak mencukupi (tersisa ${entry.product.stock}).',
        );
      }
    }

    final itemsByStore = <String, List<({Product product, int quantity})>>{};
    for (final entry in entries) {
      itemsByStore.putIfAbsent(entry.product.storeId, () => []).add(entry);
    }

    final shippingFee = AppConstants.getCourierShippingFee(courierName);
    final serviceName = AppConstants.getCourierServiceName(courierName);
    final isCod = paymentMethod == 'COD (Bayar di Tempat)';
    final initialStatus = isCod ? 'awaiting_confirmation' : 'pending_payment';
    final paymentStatus = isCod ? 'pending' : 'unpaid';
    final List<Order> createdOrders = [];

    for (final storeEntry in itemsByStore.entries) {
      final storeId = storeEntry.key;
      final storeItems = storeEntry.value;
      final store = stores.firstWhere(
        (s) => s.id == storeId,
        orElse: () => stores.first,
      );

      double subtotal = 0;
      final List<OrderItem> orderItemsList = [];
      final now = DateTime.now();
      final orderId = 'ord-${now.millisecondsSinceEpoch}-${createdOrders.length}';
      final orderCode =
          'WIJI-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${100 + orders.length + createdOrders.length}';

      for (final ci in storeItems) {
        final p = ci.product;
        final lineTot = p.price * ci.quantity;
        subtotal += lineTot;

        orderItemsList.add(
          OrderItem(
            id: 'item-$orderId-${orderItemsList.length}',
            orderId: orderId,
            productId: p.id,
            productNameSnapshot: p.name,
            unitSnapshot: p.unit,
            unitPrice: p.price,
            quantity: ci.quantity,
            lineTotal: lineTot,
            qualityGradeSnapshot: p.qualityGrade,
            imageSnapshot: p.primaryImage,
          ),
        );

        final pIdx = products.indexWhere((prod) => prod.id == p.id);
        if (pIdx != -1) {
          final newStock = (products[pIdx].stock - ci.quantity).clamp(0, 999999);
          products[pIdx] = products[pIdx].copyWith(stock: newStock);
        }
      }

      final totalAmount = subtotal + shippingFee;
      final newOrder = Order(
        id: orderId,
        orderCode: orderCode,
        buyerId: uid,
        storeId: storeId,
        addressId: address.id,
        shippingAddressSnapshot: {
          'recipient_name': address.recipientName,
          'phone': address.phone,
          'address': address.fullAddressText,
        },
        status: initialStatus,
        paymentStatus: paymentStatus,
        subtotal: subtotal,
        shippingFee: shippingFee,
        discountTotal: 0.0,
        totalAmount: totalAmount,
        buyerNote: buyerNote,
        createdAt: now,
        updatedAt: now,
        storeName: store.storeName,
        buyerName: currentUser.fullName,
        items: orderItemsList,
        payment: Payment(
          id: 'pay-$orderId',
          orderId: orderId,
          paymentMethod: paymentMethod,
          amount: totalAmount,
          status: paymentStatus,
        ),
        shipment: Shipment(
          id: 'ship-$orderId',
          orderId: orderId,
          courierName: courierName,
          serviceName: serviceName,
          trackingNumber: null,
          status: 'waiting',
          estimatedArrival: now.add(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          trackingHistory: [
            ShipmentTracking(
              id: 'trk-$orderId-1',
              shipmentId: 'ship-$orderId',
              status: 'waiting',
              description: 'Pesanan berhasil dibuat, menunggu konfirmasi penjual',
              location: store.city ?? 'Kebun Petani',
              eventAt: now,
              createdAt: now,
            ),
          ],
        ),
      );

      orders.insert(0, newOrder);
      createdOrders.add(newOrder);

      _localOrderHistory.putIfAbsent(orderId, () => []).insert(
            0,
            OrderStatusHistoryEntry(
              id: 'osh-${now.millisecondsSinceEpoch}-${createdOrders.length}',
              orderId: orderId,
              status: initialStatus,
              actorRole: 'buyer',
              note: isCod
                  ? 'Pesanan COD dibuat oleh pembeli, menunggu konfirmasi penjual'
                  : 'Pesanan dibuat oleh pembeli, menunggu pembayaran',
              createdAt: now,
            ),
          );

      await _createNotification(
        userId: uid,
        type: 'transaction',
        title: 'Pesanan $orderCode Dibuat',
        body: 'Pesanan ke ${store.storeName} berhasil dibuat.',
        referenceId: orderId,
      );
      if (store.ownerId != uid) {
        await _createNotification(
          userId: store.ownerId,
          type: 'order',
          title: 'Pesanan Baru Masuk: $orderCode',
          body: 'Ada pesanan baru dari ${currentUser.fullName}.',
          referenceId: orderId,
        );
      }
    }

    if (clearCartAfter) {
      await clearCart();
    }
    return createdOrders;
  }

  Future<bool> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? trackingNumber,
    String? courierName,
    String? note,
    bool isSellerAction = false,
  }) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client.rpc('update_order_status_secure', params: {
          'p_order_id': orderId,
          'p_new_status': newStatus,
          'p_tracking_number': trackingNumber,
          'p_courier_name': courierName,
          'p_note': note,
        });
        return true;
      } catch (e) {
        debugPrint('Supabase updateOrderStatus error: $e');
        return false;
      }
    }

    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return false;

    final current = orders[idx];
    if (!_isValidStatusTransition(current.status, newStatus, isSellerAction: isSellerAction)) {
      return false;
    }

    var newPaymentStatus = current.paymentStatus;
    if (newStatus == 'awaiting_confirmation' || newStatus == 'completed') {
      newPaymentStatus = 'paid';
    }

    // Restore stock on cancellation
    if (newStatus == 'cancelled') {
      for (final item in current.items) {
        if (item.productId != null) {
          final pIdx = products.indexWhere((p) => p.id == item.productId);
          if (pIdx != -1) {
            products[pIdx] = products[pIdx].copyWith(stock: products[pIdx].stock + item.quantity);
          }
        }
      }
    }

    Shipment? updatedShipment = current.shipment;
    if (updatedShipment != null) {
      final trackingHist = List<ShipmentTracking>.from(updatedShipment.trackingHistory);
      String desc = note ?? 'Status diperbarui menjadi: $newStatus';
      String shipStatus = updatedShipment.status;

      if (newStatus == 'awaiting_confirmation') {
        desc = note ?? 'Pembayaran diterima, menunggu konfirmasi penjual';
      } else if (newStatus == 'processing') {
        desc = note ?? 'Penjual sedang menyiapkan dan mengemas produk hasil panen';
      } else if (newStatus == 'ready_to_ship') {
        desc = note ?? 'Paket siap dijemput oleh kurir pengiriman';
        shipStatus = 'picked_up';
      } else if (newStatus == 'shipped') {
        desc = note ??
            'Paket dibawa kurir${trackingNumber != null ? ' (Resi: $trackingNumber)' : ''}';
        shipStatus = 'in_transit';
      } else if (newStatus == 'completed') {
        desc = 'Pesanan telah diterima oleh pembeli. Transaksi selesai!';
        shipStatus = 'delivered';
      } else if (newStatus == 'cancelled') {
        desc = note ?? 'Pesanan dibatalkan';
        shipStatus = 'failed';
      }

      trackingHist.insert(
        0,
        ShipmentTracking(
          id: 'trk-${DateTime.now().millisecondsSinceEpoch}',
          shipmentId: updatedShipment.id,
          status: shipStatus,
          description: desc,
          location: newStatus == 'completed' ? 'Alamat Pembeli' : 'Lokasi Pengiriman',
          eventAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      updatedShipment = Shipment(
        id: updatedShipment.id,
        orderId: updatedShipment.orderId,
        courierName: courierName?.isNotEmpty == true ? courierName : updatedShipment.courierName,
        serviceName: updatedShipment.serviceName,
        trackingNumber:
            trackingNumber?.isNotEmpty == true ? trackingNumber : updatedShipment.trackingNumber,
        status: shipStatus,
        estimatedArrival: updatedShipment.estimatedArrival,
        shippedAt: newStatus == 'shipped'
            ? (updatedShipment.shippedAt ?? DateTime.now())
            : updatedShipment.shippedAt,
        deliveredAt: newStatus == 'completed' ? DateTime.now() : updatedShipment.deliveredAt,
        createdAt: updatedShipment.createdAt,
        updatedAt: DateTime.now(),
        trackingHistory: trackingHist,
      );
    }

    orders[idx] = current.copyWith(
      status: newStatus,
      paymentStatus: newPaymentStatus,
      shipment: updatedShipment,
    );

    _localOrderHistory.putIfAbsent(orderId, () => []).insert(
          0,
          OrderStatusHistoryEntry(
            id: 'osh-${DateTime.now().millisecondsSinceEpoch}',
            orderId: orderId,
            status: newStatus,
            actorRole: isSellerAction ? 'seller' : 'buyer',
            note: updatedShipment?.trackingHistory.first.description ?? note,
            createdAt: DateTime.now(),
          ),
        );

    final notifType = (newStatus == 'shipped' || newStatus == 'ready_to_ship')
        ? 'shipment'
        : (newStatus == 'awaiting_confirmation' || newStatus == 'completed')
            ? 'transaction'
            : 'order';
    await _createNotification(
      userId: current.buyerId,
      type: notifType,
      title: 'Update Pesanan ${current.orderCode}',
      body: updatedShipment?.trackingHistory.first.description ??
          'Status pesanan berubah menjadi $newStatus',
      referenceId: current.id,
    );
    return true;
  }

  bool _isValidStatusTransition(String from, String to, {bool isSellerAction = false}) {
    if (isSellerAction) {
      // Seller cannot manually validate unpaid orders or force complete shipped orders
      if (from == 'pending_payment' && to == 'awaiting_confirmation') return false;
      if (from == 'shipped' && to == 'completed') return false;
    }
    const allowed = {
      'pending_payment': ['awaiting_confirmation', 'cancelled'],
      'awaiting_confirmation': ['processing', 'cancelled'],
      'processing': ['ready_to_ship', 'shipped', 'cancelled'],
      'ready_to_ship': ['shipped'],
      'shipped': ['completed'],
    };
    return allowed[from]?.contains(to) ?? false;
  }

  Future<List<OrderStatusHistoryEntry>> getOrderStatusHistory(String orderId) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client
            .from('order_status_history')
            .select()
            .eq('order_id', orderId)
            .order('created_at', ascending: false);
        return (res as List).map((e) => OrderStatusHistoryEntry.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getOrderStatusHistory error: $e');
        rethrow;
      }
    }
    return _localOrderHistory[orderId] ?? [];
  }

  // ------------------ CHAT ------------------

  Future<List<Chat>> getChats({String? myStoreId}) async {
    final uid = activeUserId;
    if (uid == null) return [];

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('chats').select('''
          *,
          stores (store_name, logo_path),
          profiles:buyer_id (full_name, avatar_path),
          products (name)
        ''').order('last_message_at', ascending: false);

        final unreadRes = await client
            .from('chat_messages')
            .select('chat_id')
            .neq('sender_id', uid)
            .isFilter('read_at', null);

        final Map<String, int> unreadByChat = {};
        for (final row in (unreadRes as List)) {
          final cid = row['chat_id'] as String?;
          if (cid != null) {
            unreadByChat[cid] = (unreadByChat[cid] ?? 0) + 1;
          }
        }

        return (res as List).map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          map['unread_count'] = unreadByChat[map['id']] ?? 0;
          return Chat.fromJson(map);
        }).toList();
      } catch (e) {
        debugPrint('Supabase getChats error: $e');
        rethrow;
      }
    }

    return chats
        .where((c) => c.buyerId == uid || (myStoreId != null && c.storeId == myStoreId))
        .toList();
  }

  Future<List<ChatMessage>> getChatMessages(String chatId) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client
            .from('chat_messages')
            .select()
            .eq('chat_id', chatId)
            .order('created_at', ascending: true);
        return (res as List).map((e) => ChatMessage.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getChatMessages error: $e');
        rethrow;
      }
    }
    return chatMessages.where((m) => m.chatId == chatId).toList();
  }

  Future<Chat> startOrGetChat({required String storeId, String? productId}) async {
    final uid = activeUserId;
    if (uid == null) {
      throw Exception('Silakan masuk ke akun WijiBumi terlebih dahulu.');
    }

    if (isConnected) {
      final client = SupabaseConfig.client!;
      final existing = await client
          .from('chats')
          .select('''
            *,
            stores (store_name, logo_path),
            profiles:buyer_id (full_name),
            products (name)
          ''')
          .eq('buyer_id', uid)
          .eq('store_id', storeId)
          .maybeSingle();
      if (existing != null) {
        return Chat.fromJson(existing);
      }

      final inserted = await client.from('chats').insert({
        'buyer_id': uid,
        'store_id': storeId,
        'product_id': productId,
      }).select('''
        *,
        stores (store_name, logo_path),
        profiles:buyer_id (full_name),
        products (name)
      ''').single();
      return Chat.fromJson(inserted);
    }

    final existing = chats.where((c) => c.buyerId == uid && c.storeId == storeId);
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final store = stores.firstWhere((s) => s.id == storeId, orElse: () => stores.first);
    Product? p;
    if (productId != null) {
      try {
        p = products.firstWhere((prod) => prod.id == productId);
      } catch (_) {}
    }

    final newChat = Chat(
      id: 'chat-${DateTime.now().millisecondsSinceEpoch}',
      buyerId: uid,
      storeId: storeId,
      productId: productId,
      createdAt: DateTime.now(),
      storeName: store.storeName,
      storeLogo: store.logoPath,
      buyerName: currentUser.fullName,
      productName: p?.name,
      productImage: p?.primaryImage,
    );

    chats.insert(0, newChat);
    return newChat;
  }

  Future<ChatMessage> sendChatMessage({
    required String chatId,
    String? body,
    String? mediaPath,
  }) async {
    final uid = activeUserId;
    if (uid == null) {
      throw Exception('Silakan masuk ke akun WijiBumi terlebih dahulu.');
    }
    final cleanBody = body?.trim();
    final hasBody = cleanBody != null && cleanBody.isNotEmpty;
    final hasMedia = mediaPath != null && mediaPath.trim().isNotEmpty;
    if (!hasBody && !hasMedia) {
      throw Exception('Pesan atau lampiran gambar tidak boleh kosong.');
    }

    if (isConnected) {
      final client = SupabaseConfig.client!;
      final res = await client.from('chat_messages').insert({
        'chat_id': chatId,
        'sender_id': uid,
        'message_type': hasMedia ? 'image' : 'text',
        'body': hasBody ? cleanBody : null,
        'media_path': hasMedia ? mediaPath.trim() : null,
      }).select().single();
      return ChatMessage.fromJson(res);
    }

    final now = DateTime.now();
    final newMsg = ChatMessage(
      id: 'msg-${now.millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: uid,
      messageType: hasMedia ? 'image' : 'text',
      body: hasBody ? cleanBody : null,
      mediaPath: hasMedia ? mediaPath.trim() : null,
      createdAt: now,
    );

    chatMessages.add(newMsg);

    final cIdx = chats.indexWhere((c) => c.id == chatId);
    if (cIdx != -1) {
      chats[cIdx] = chats[cIdx].copyWith(
        lastMessageAt: now,
        lastMessageBody: hasBody ? cleanBody : '[Gambar]',
        unreadCount: 0,
      );
    }

    return newMsg;
  }

  Future<void> markChatMessagesAsRead(String chatId) async {
    final uid = activeUserId;
    if (uid == null) return;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client
            .from('chat_messages')
            .update({'read_at': DateTime.now().toIso8601String()})
            .eq('chat_id', chatId)
            .neq('sender_id', uid)
            .isFilter('read_at', null);
      } catch (e) {
        debugPrint('Supabase markChatMessagesAsRead error: $e');
      }
      return;
    }

    final idx = chats.indexWhere((c) => c.id == chatId);
    if (idx != -1) {
      chats[idx] = chats[idx].copyWith(unreadCount: 0);
    }
  }

  // ------------------ NOTIFICATIONS ------------------

  Future<List<AppNotification>> getNotifications() async {
    final uid = activeUserId;
    if (uid == null) return [];

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client
            .from('notifications')
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false);
        return (res as List).map((e) => AppNotification.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getNotifications error: $e');
        rethrow;
      }
    }
    return notifications.where((n) => n.userId == uid).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    final uid = activeUserId;
    if (uid == null) return false;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client
            .from('notifications')
            .update({'is_read': true})
            .eq('id', notificationId)
            .eq('user_id', uid);
        return true;
      } catch (e) {
        debugPrint('Supabase markNotificationAsRead error: $e');
        return false;
      }
    }
    final idx = notifications.indexWhere((n) => n.id == notificationId && n.userId == uid);
    if (idx != -1) {
      notifications[idx] = notifications[idx].copyWith(isRead: true);
    }
    return true;
  }

  Future<bool> markAllNotificationsAsRead() async {
    final uid = activeUserId;
    if (uid == null) return false;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', uid)
            .eq('is_read', false);
        return true;
      } catch (e) {
        debugPrint('Supabase markAllNotificationsAsRead error: $e');
        return false;
      }
    }
    for (int i = 0; i < notifications.length; i++) {
      if (notifications[i].userId == uid) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
    }
    return true;
  }

  Future<bool> deleteNotification(String notificationId) async {
    final uid = activeUserId;
    if (uid == null) return false;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client
            .from('notifications')
            .delete()
            .eq('id', notificationId)
            .eq('user_id', uid);
        return true;
      } catch (e) {
        debugPrint('Supabase deleteNotification error: $e');
        return false;
      }
    }
    notifications.removeWhere((n) => n.id == notificationId && n.userId == uid);
    return true;
  }

  Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? referenceId,
  }) async {
    final notif = AppNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}-${notifications.length}',
      userId: userId,
      type: type,
      title: title,
      body: body,
      referenceId: referenceId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        if (userId == client.auth.currentUser?.id) {
          await client.from('notifications').insert(notif.toJson(includeId: false));
        }
        return;
      } catch (e) {
        debugPrint('Supabase insert notification note: $e');
      }
    }
    notifications.insert(0, notif);
  }

  // ------------------ REVIEWS ------------------

  Future<List<Review>> getStoreReviews(String storeId) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('reviews').select('''
          *,
          profiles:reviewer_id (full_name, avatar_path),
          products (name)
        ''').eq('store_id', storeId).order('created_at', ascending: false);
        return (res as List).map((e) => Review.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getStoreReviews error: $e');
        rethrow;
      }
    }
    return reviews.where((r) => r.storeId == storeId).toList();
  }

  Future<List<Review>> getProductReviews(String productId) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('reviews').select('''
          *,
          profiles:reviewer_id (full_name, avatar_path),
          products (name)
        ''').eq('product_id', productId).order('created_at', ascending: false);
        return (res as List).map((e) => Review.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getProductReviews error: $e');
        rethrow;
      }
    }
    return reviews.where((r) => r.productId == productId).toList();
  }

  Future<Map<String, Set<String>>> getBuyerReviewedProductMap() async {
    final uid = activeUserId;
    if (uid == null) return {};

    final result = <String, Set<String>>{};
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client
            .from('reviews')
            .select('order_id, product_id')
            .eq('reviewer_id', uid);
        for (final row in (res as List)) {
          final orderId = row['order_id']?.toString();
          if (orderId == null || orderId.isEmpty) continue;
          final key = row['product_id']?.toString() ?? '__order__';
          result.putIfAbsent(orderId, () => <String>{}).add(key);
        }
        return result;
      } catch (e) {
        debugPrint('Supabase getBuyerReviewedProductMap error: $e');
        rethrow;
      }
    }

    for (final r in reviews.where((rev) => rev.reviewerId == uid)) {
      final key = r.productId ?? '__order__';
      result.putIfAbsent(r.orderId, () => <String>{}).add(key);
    }
    return result;
  }

  Future<Review> addReview({
    required String orderId,
    required String storeId,
    String? productId,
    required int rating,
    required String reviewText,
  }) async {
    final uid = activeUserId;
    if (uid == null) {
      throw Exception('Silakan masuk ke akun WijiBumi terlebih dahulu.');
    }

    if (isConnected) {
      final client = SupabaseConfig.client!;
      var dupQuery = client
          .from('reviews')
          .select('id')
          .eq('order_id', orderId)
          .eq('reviewer_id', uid);
      if (productId != null && productId.isNotEmpty) {
        dupQuery = dupQuery.eq('product_id', productId);
      } else {
        dupQuery = dupQuery.isFilter('product_id', null);
      }
      final existing = await dupQuery.maybeSingle();
      if (existing != null) {
        throw Exception('Produk pada pesanan ini sudah pernah Anda ulas.');
      }

      try {
        final res = await client.from('reviews').insert({
          'order_id': orderId,
          'reviewer_id': uid,
          'store_id': storeId,
          'product_id': productId,
          'rating': rating,
          'review_text': reviewText,
        }).select('''
          *,
          profiles:reviewer_id (full_name, avatar_path),
          products (name)
        ''').single();
        return Review.fromJson(res);
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          throw Exception('Produk pada pesanan ini sudah pernah Anda ulas.');
        }
        rethrow;
      }
    }

    final alreadyExists = reviews.any(
      (r) =>
          r.orderId == orderId &&
          r.reviewerId == uid &&
          (productId == null ? r.productId == null : r.productId == productId),
    );
    if (alreadyExists) {
      throw Exception('Produk pada pesanan ini sudah pernah Anda ulas.');
    }

    String? productName;
    if (productId != null) {
      productName = products.where((p) => p.id == productId).firstOrNull?.name;
    }

    final newReview = Review(
      id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      reviewerId: uid,
      storeId: storeId,
      productId: productId,
      rating: rating,
      reviewText: reviewText,
      createdAt: DateTime.now(),
      reviewerName: currentUser.fullName,
      reviewerAvatar: currentUser.avatarPath,
      productName: productName,
    );
    reviews.insert(0, newReview);

    // Sync local store & product ratings in demo mode
    final storeReviews = reviews.where((r) => r.storeId == storeId).toList();
    if (storeReviews.isNotEmpty) {
      final avgStore =
          storeReviews.fold<int>(0, (sum, r) => sum + r.rating) / storeReviews.length;
      final sIdx = stores.indexWhere((s) => s.id == storeId);
      if (sIdx != -1) {
        stores[sIdx] = stores[sIdx].copyWith(
          rating: double.parse(avgStore.toStringAsFixed(2)),
          totalReviews: storeReviews.length,
        );
      }
    }
    if (productId != null) {
      final prodReviews = reviews.where((r) => r.productId == productId).toList();
      if (prodReviews.isNotEmpty) {
        final avgProd =
            prodReviews.fold<int>(0, (sum, r) => sum + r.rating) / prodReviews.length;
        final pIdx = products.indexWhere((p) => p.id == productId);
        if (pIdx != -1) {
          products[pIdx] = products[pIdx].copyWith(
            rating: double.parse(avgProd.toStringAsFixed(2)),
          );
        }
      }
    }

    return newReview;
  }

  Future<bool> replyReview(String reviewId, String replyText) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client.from('reviews').update({
          'reply_text': replyText,
          'replied_at': DateTime.now().toIso8601String(),
        }).eq('id', reviewId);
        return true;
      } catch (e) {
        debugPrint('Supabase replyReview error: $e');
        return false;
      }
    }

    final idx = reviews.indexWhere((r) => r.id == reviewId);
    if (idx != -1) {
      reviews[idx] = reviews[idx].copyWith(
        replyText: replyText,
        repliedAt: DateTime.now(),
      );
      return true;
    }
    return false;
  }

  // ------------------ PROMOTIONS ------------------

  Future<List<Promotion>> getStorePromotions(String storeId) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client
            .from('promotions')
            .select()
            .eq('store_id', storeId)
            .order('created_at', ascending: false);
        return (res as List).map((e) => Promotion.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getStorePromotions error: $e');
      }
    }
    return promotions.where((p) => p.storeId == storeId).toList();
  }

  Future<Promotion> addPromotion(Promotion promo) async {
    if (isConnected) {
      final client = SupabaseConfig.client!;
      final res = await client
          .from('promotions')
          .insert(promo.toJson(includeId: false))
          .select()
          .single();
      return Promotion.fromJson(res);
    }
    promotions.insert(0, promo);
    return promo;
  }

  // ------------------ PAYOUTS ------------------

  Future<List<PayoutAccount>> getPayoutAccounts(String storeId) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('payout_accounts').select().eq('store_id', storeId);
        return (res as List).map((e) => PayoutAccount.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getPayoutAccounts error: $e');
      }
    }
    return payoutAccounts.where((p) => p.storeId == storeId).toList();
  }

  Future<PayoutAccount> addPayoutAccount({
    required String storeId,
    required String method,
    required String providerName,
    required String accountHolder,
    required String accountNumber,
  }) async {
    final cleaned = accountNumber.replaceAll(RegExp(r'\s+'), '');
    final last4 = cleaned.length > 4 ? cleaned.substring(cleaned.length - 4) : cleaned;
    final acc = PayoutAccount(
      id: 'payacc-${DateTime.now().millisecondsSinceEpoch}',
      storeId: storeId,
      method: method,
      providerName: providerName,
      accountHolder: accountHolder,
      accountNumberLast4: last4,
      isDefault: payoutAccounts.where((a) => a.storeId == storeId).isEmpty,
      createdAt: DateTime.now(),
    );

    if (isConnected) {
      final client = SupabaseConfig.client!;
      final res = await client.from('payout_accounts').insert({
        'store_id': storeId,
        'method': method,
        'provider_name': providerName,
        'account_holder': accountHolder,
        'account_number_last4': last4,
        'is_default': acc.isDefault,
      }).select().single();
      return PayoutAccount.fromJson(res);
    }

    payoutAccounts.add(acc);
    return acc;
  }

  Future<List<PayoutRequest>> getPayoutRequests(String storeId) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client
            .from('payout_requests')
            .select('*, payout_accounts(*)')
            .eq('store_id', storeId)
            .order('requested_at', ascending: false);
        return (res as List).map((e) => PayoutRequest.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getPayoutRequests error: $e');
      }
    }
    return payoutRequests.where((p) => p.storeId == storeId).toList();
  }

  Future<PayoutRequest> requestPayout({
    required String storeId,
    required String payoutAccountId,
    required double amount,
    String? note,
  }) async {
    final ref = 'PO-${DateTime.now().millisecondsSinceEpoch}';
    if (isConnected) {
      final client = SupabaseConfig.client!;
      final res = await client.from('payout_requests').insert({
        'store_id': storeId,
        'payout_account_id': payoutAccountId,
        'amount': amount,
        'status': 'requested',
        'reference_number': ref,
        'note': note,
      }).select('*, payout_accounts(*)').single();
      return PayoutRequest.fromJson(res);
    }

    final acc = payoutAccounts.firstWhere((a) => a.id == payoutAccountId);
    final req = PayoutRequest(
      id: 'preq-${DateTime.now().millisecondsSinceEpoch}',
      storeId: storeId,
      payoutAccountId: payoutAccountId,
      amount: amount,
      status: 'requested',
      referenceNumber: ref,
      note: note,
      requestedAt: DateTime.now(),
      account: acc,
    );
    payoutRequests.insert(0, req);
    return req;
  }

  // ------------------ SUPPORT & USER SETTINGS ------------------

  Future<SupportTicket> submitSupportTicket({
    required String category,
    required String subject,
    required String message,
  }) async {
    final uid = activeUserId ?? currentUser.id;
    if (isConnected) {
      final client = SupabaseConfig.client!;
      final res = await client.from('support_tickets').insert({
        'user_id': uid,
        'category': category,
        'subject': subject,
        'message': message,
      }).select().single();
      return SupportTicket.fromJson(res);
    }

    final ticket = SupportTicket(
      id: 'tkt-${DateTime.now().millisecondsSinceEpoch}',
      userId: uid,
      category: category,
      subject: subject,
      message: message,
      createdAt: DateTime.now(),
    );
    supportTickets.insert(0, ticket);
    return ticket;
  }

  Future<List<SupportTicket>> getMySupportTickets() async {
    final uid = activeUserId;
    if (uid == null) return [];
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client
            .from('support_tickets')
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false);
        return (res as List)
            .map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (e) {
        debugPrint('Supabase getMySupportTickets error: $e');
        rethrow;
      }
    }
    return supportTickets.where((t) => t.userId == uid).toList();
  }

  Future<AppSettings?> fetchRemoteUserSettings() async {
    if (!isConnected) return null;
    try {
      final client = SupabaseConfig.client!;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return null;
      final res = await client.from('user_settings').select().eq('user_id', uid).maybeSingle();
      if (res != null) return AppSettings.fromJson(res);
    } catch (e) {
      debugPrint('Supabase fetchRemoteUserSettings error: $e');
    }
    return null;
  }

  Future<bool> saveRemoteUserSettings(AppSettings settings) async {
    if (!isConnected) return true;
    try {
      final client = SupabaseConfig.client!;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return false;
      await client.from('user_settings').upsert(settings.toJson(uid));
      return true;
    } catch (e) {
      debugPrint('Supabase saveRemoteUserSettings error: $e');
      return false;
    }
  }
}
