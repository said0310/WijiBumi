import 'package:flutter/foundation.dart';
import '../models/address.dart';
import '../services/supabase_service.dart';

class AddressProvider with ChangeNotifier {
  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _lastError;

  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  Address? get defaultAddress {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );
  }

  AddressProvider() {
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    _isLoading = true;
    notifyListeners();
    try {
      _addresses = await SupabaseService.instance.getAddresses();
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress(Address address) async {
    final created = await addAddressAndReturn(address);
    return created != null;
  }

  Future<Address?> addAddressAndReturn(Address address) async {
    _lastError = null;
    try {
      final created = await SupabaseService.instance.addAddress(address);
      await loadAddresses();
      return created;
    } catch (e) {
      debugPrint('Error adding address: $e');
      _lastError = 'Gagal menyimpan alamat. Periksa koneksi Anda lalu coba lagi.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateAddress(Address address) async {
    _lastError = null;
    final ok = await SupabaseService.instance.updateAddress(address);
    if (ok) {
      await loadAddresses();
    } else {
      _lastError = 'Gagal memperbarui alamat. Silakan coba lagi.';
      notifyListeners();
    }
    return ok;
  }

  Future<bool> deleteAddress(String addressId) async {
    _lastError = null;
    final ok = await SupabaseService.instance.deleteAddress(addressId);
    if (ok) {
      await loadAddresses();
    } else {
      _lastError = 'Gagal menghapus alamat.';
      notifyListeners();
    }
    return ok;
  }

  Future<bool> setDefaultAddress(String addressId) async {
    _lastError = null;
    final ok = await SupabaseService.instance.setDefaultAddress(addressId);
    if (ok) {
      await loadAddresses();
    } else {
      _lastError = 'Gagal mengubah alamat utama.';
      notifyListeners();
    }
    return ok;
  }

  void clearSession() {
    _addresses = [];
    _lastError = null;
    notifyListeners();
  }
}

