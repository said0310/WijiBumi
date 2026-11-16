import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Status izin dan layanan lokasi perangkat.
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Model data hasil reverse geocoding dari koordinat peta.
class LocationAddressDetails {
  final double latitude;
  final double longitude;
  final String displayName;
  final String? road;
  final String? kelurahan;
  final String? district;
  final String? city;
  final String? province;
  final String? postalCode;
  final bool isFallback;

  const LocationAddressDetails({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    this.road,
    this.kelurahan,
    this.district,
    this.city,
    this.province,
    this.postalCode,
    this.isFallback = false,
  });

  /// Ringkasan area untuk tampilan singkat (misal: Jl. Sudirman, Menteng, Jakarta Pusat).
  String get shortTitle {
    final parts = <String>[];
    if (road != null && road!.trim().isNotEmpty) {
      parts.add(road!.trim());
    } else if (kelurahan != null && kelurahan!.trim().isNotEmpty) {
      parts.add(kelurahan!.trim());
    }
    if (district != null && district!.trim().isNotEmpty) {
      parts.add(district!.trim());
    }
    if (city != null && city!.trim().isNotEmpty) {
      parts.add(city!.trim());
    }
    return parts.isNotEmpty ? parts.join(', ') : displayName;
  }
}

/// Layanan untuk mengelola GPS perangkat dan reverse geocoding via OpenStreetMap Nominatim.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // Cache lokal untuk mengurangi request ke OSM Nominatim
  final Map<String, LocationAddressDetails> _cache = {};

  /// Cek ketersediaan layanan GPS perangkat.
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  /// Cek dan minta izin lokasi perangkat dengan penanganan lengkap.
  Future<LocationPermissionStatus> checkAndRequestPermission() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionStatus.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }

    return LocationPermissionStatus.granted;
  }

  /// Ambil koordinat GPS perangkat saat ini.
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      // Coba fallback dengan last known position jika GPS lambat terkunci
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Buka pengaturan aplikasi untuk mengaktifkan izin lokasi secara manual.
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  /// Buka pengaturan lokasi (GPS) sistem.
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Error opening location settings: $e');
      return false;
    }
  }

  /// Reverse geocoding menggunakan OpenStreetMap Nominatim API.
  /// Menghormati batas request OSM dengan User-Agent unik dan caching in-memory.
  Future<LocationAddressDetails> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    // Kunci cache berbasis 4 angka desimal (~11 meter)
    final cacheKey =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final fallback = LocationAddressDetails(
      latitude: latitude,
      longitude: longitude,
      displayName:
          'Titik Koordinat: ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
      isFallback: true,
    );

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'WijiBumiApp/1.0 (academic.delivery.app; support@wijibumi.local)',
          'Accept-Language': 'id,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return fallback;
      }

      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final displayName = data['display_name'] as String? ?? fallback.displayName;
      final address = data['address'] as Map<String, dynamic>? ?? {};

      // Parsing field alamat administratif Indonesia
      final road = _firstNonEmpty(address, [
        'road',
        'pedestrian',
        'residential',
        'footway',
        'path',
        'street',
      ]);

      final kelurahan = _firstNonEmpty(address, [
        'village',
        'suburb',
        'neighbourhood',
        'hamlet',
        'quarter',
      ]);

      final district = _firstNonEmpty(address, [
        'city_district',
        'subdistrict',
        'district',
        'municipality',
      ]);

      final city = _firstNonEmpty(address, [
        'city',
        'town',
        'county',
        'regency',
      ]);

      final province = _firstNonEmpty(address, [
        'state',
        'province',
        'region',
      ]);

      final postalCode = _firstNonEmpty(address, [
        'postcode',
        'postal_code',
      ]);

      final result = LocationAddressDetails(
        latitude: latitude,
        longitude: longitude,
        displayName: displayName,
        road: _cleanPrefix(road, ['Jalan ', 'Jl. ']),
        kelurahan: _cleanPrefix(kelurahan, ['Kelurahan ', 'Desa ']),
        district: _cleanPrefix(district, ['Kecamatan ']),
        city: _cleanPrefix(city, ['Kota Administrasi ', 'Kota Adm. ', 'Kota ', 'Kabupaten ']),
        province: province,
        postalCode: postalCode,
        isFallback: false,
      );

      _cache[cacheKey] = result;
      return result;
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
      return fallback;
    }
  }

  String? _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String? _cleanPrefix(String? value, List<String> prefixes) {
    if (value == null) return null;
    String clean = value.trim();
    for (final prefix in prefixes) {
      if (clean.toLowerCase().startsWith(prefix.toLowerCase())) {
        clean = clean.substring(prefix.length).trim();
        break;
      }
    }
    return clean;
  }
}

