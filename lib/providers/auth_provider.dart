import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  UserProfile? _user;
  bool _isLoading = false;
  bool _initialized = false;
  bool _isSellerSessionAuthenticated = false;
  String? _errorMessage;

  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;
  bool get hasSellerAccess => _user?.hasSellerAccess ?? false;
  bool get isSellerSessionAuthenticated => _isSellerSessionAuthenticated;
  bool get hasActiveRemoteSession => SupabaseService.instance.hasActiveRemoteSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    loadUser();
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await SupabaseService.instance.getCurrentProfile();
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      _isLoading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> checkRemoteSession() async {
    if (!SupabaseService.instance.hasActiveRemoteSession) {
      if (SupabaseService.instance.isConnected &&
          (_user != null || _isSellerSessionAuthenticated || !_initialized)) {
        _user = null;
        _isSellerSessionAuthenticated = false;
        _initialized = true;
        await Future<void>.value();
        notifyListeners();
      }
      return false;
    }
    _user = await SupabaseService.instance.getCurrentProfile();
    _initialized = true;
    notifyListeners();
    return _user != null;
  }

  void restoreSellerSessionIfEligible() {
    if (_user != null && _user!.hasSellerAccess) {
      _isSellerSessionAuthenticated = true;
      notifyListeners();
    }
  }

  Future<AuthResult> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await SupabaseService.instance.login(email, password);
      if (result.success) {
        _user = result.profile;
      } else {
        _errorMessage = result.message;
      }
      return result;
    } catch (e) {
      _errorMessage = 'Login error: $e';
      return AuthResult(success: false, message: _errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await SupabaseService.instance.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
      if (result.success) {
        // Tetap arahkan pengguna untuk login terlebih dahulu setelah registrasi
        _user = null;
        _isSellerSessionAuthenticated = false;
      } else {
        _errorMessage = result.message;
      }
      return result;
    } catch (e) {
      _errorMessage = 'Register error: $e';
      return AuthResult(success: false, message: _errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SellerAuthResult> loginSeller(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await SupabaseService.instance.loginSeller(email, password);
      if (result.isSuccess) {
        _user = result.profile;
        _isSellerSessionAuthenticated = true;
      } else {
        _isSellerSessionAuthenticated = false;
        _errorMessage = result.message;
      }
      return result;
    } catch (e) {
      _errorMessage = 'Gagal login penjual: $e';
      return SellerAuthResult(status: SellerAuthStatus.error, message: _errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SellerAuthResult> registerSeller({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await SupabaseService.instance.registerSeller(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
      _isSellerSessionAuthenticated = false;
      if (!result.isSuccess &&
          result.status != SellerAuthStatus.emailNotVerified) {
        _errorMessage = result.message;
      }
      return result;
    } catch (e) {
      _errorMessage = 'Gagal mendaftar akun penjual: $e';
      return SellerAuthResult(status: SellerAuthStatus.error, message: _errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    return SupabaseService.instance.sendPasswordReset(email);
  }

  Future<ProfileUpdateResult> updateProfile({
    required String fullName,
    required String phone,
    String? email,
    String? avatarPath,
    bool removeAvatar = false,
    DateTime? birthDate,
    bool clearBirthDate = false,
    String? gender,
    bool clearGender = false,
  }) async {
    if (_user == null) {
      return const ProfileUpdateResult(success: false, errorMessage: 'Pengguna tidak ditemukan.');
    }
    final updatedLocal = _user!.copyWith(
      fullName: fullName,
      phone: phone,
      avatarPath: removeAvatar ? null : (avatarPath ?? _user!.avatarPath),
      clearAvatarPath: removeAvatar,
      birthDate: birthDate,
      clearBirthDate: clearBirthDate,
      gender: gender,
      clearGender: clearGender,
    );

    final result = await SupabaseService.instance.updateProfile(
      updatedLocal,
      newEmail: email,
    );

    if (result.success) {
      if (email != null &&
          email.trim().isNotEmpty &&
          !SupabaseService.instance.isConnected) {
        _user = updatedLocal.copyWith(email: email.trim());
      } else {
        _user = updatedLocal;
      }
      notifyListeners();
    }
    return result;
  }

  Future<void> refreshVerificationStatus() async {
    await SupabaseService.instance.refreshAuthUser();
    if (SupabaseService.instance.hasActiveRemoteSession) {
      final synced = await SupabaseService.instance.getCurrentProfile();
      if (synced != null) {
        _user = synced;
      }
    }
    notifyListeners();
  }

  Map<String, dynamic> getProfileVerificationStatus({
    String? draftEmail,
    String? draftPhone,
  }) {
    return SupabaseService.instance.getProfileVerificationStatus(
      draftEmail: draftEmail,
      draftPhone: draftPhone,
    );
  }

  Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return SupabaseService.instance.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  Map<String, dynamic> getSecurityInfo() {
    return SupabaseService.instance.getSecurityInfo();
  }

  Future<AuthResult> resendVerificationEmail() async {
    return SupabaseService.instance.resendVerificationEmail();
  }

  Future<AuthResult> updateRecoveredPassword(String newPassword) async {
    return SupabaseService.instance.updateRecoveredPassword(newPassword);
  }

  Future<AuthResult> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await SupabaseService.instance.deleteAccount();
      if (result.success) {
        _user = null;
        _isSellerSessionAuthenticated = false;
        _errorMessage = null;
      }
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await SupabaseService.instance.logout();
    _user = null;
    _isSellerSessionAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logoutSeller() async {
    await logout();
  }
}
