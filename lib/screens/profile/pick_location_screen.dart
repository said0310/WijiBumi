import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../services/location_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_widgets.dart';

/// Halaman pemilihan lokasi pengiriman menggunakan Flutter Map dan OpenStreetMap.
class PickLocationScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const PickLocationScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  final MapController _mapController = MapController();

  late LatLng _selectedPoint;
  LocationAddressDetails? _locationDetails;
  bool _isGeocoding = false;
  bool _isLocatingUser = false;
  Timer? _debounceTimer;

  // Koordinat default jika belum ada lokasi (Pusat Jakarta - Monas)
  static const LatLng _defaultCenter = LatLng(-6.1754, 106.8272);

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPoint = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    } else {
      _selectedPoint = _defaultCenter;
    }

    // Lakukan reverse geocoding awal untuk titik yang dipilih
    _fetchAddressForPoint(_selectedPoint);

    // Jika pengguna belum menentukan lokasi sebelumnya, coba deteksi lokasi GPS otomatis sekali
    if (widget.initialLatitude == null || widget.initialLongitude == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getUserLocation(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      setState(() {
        _selectedPoint = camera.center;
      });
      _debounceGeocode(camera.center);
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedPoint = point;
    });
    _mapController.move(point, _mapController.camera.zoom);
    _debounceGeocode(point);
  }

  void _debounceGeocode(LatLng point) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _fetchAddressForPoint(point);
    });
  }

  Future<void> _fetchAddressForPoint(LatLng point) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    try {
      final details = await LocationService.instance.reverseGeocode(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (mounted) {
        setState(() {
          _locationDetails = details;
          _isGeocoding = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeocoding = false);
      }
    }
  }

  /// Meminta dan mengambil lokasi GPS perangkat pengguna
  Future<void> _getUserLocation({bool silent = false}) async {
    if (_isLocatingUser) return;
    setState(() => _isLocatingUser = true);

    try {
      final status = await LocationService.instance.checkAndRequestPermission();

      if (!mounted) return;

      switch (status) {
        case LocationPermissionStatus.serviceDisabled:
          setState(() => _isLocatingUser = false);
          if (!silent) {
            _showServiceDisabledDialog();
          }
          return;

        case LocationPermissionStatus.denied:
          setState(() => _isLocatingUser = false);
          if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Izin akses lokasi ditolak. Aktifkan izin untuk mendeteksi posisi Anda.',
                ),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          return;

        case LocationPermissionStatus.deniedForever:
          setState(() => _isLocatingUser = false);
          if (!silent) {
            _showPermissionDeniedForeverDialog();
          }
          return;

        case LocationPermissionStatus.granted:
          final position = await LocationService.instance.getCurrentPosition();
          if (!mounted) return;
          setState(() => _isLocatingUser = false);

          if (position != null) {
            final userPoint = LatLng(position.latitude, position.longitude);
            setState(() {
              _selectedPoint = userPoint;
            });
            _mapController.move(userPoint, 16.5);
            _fetchAddressForPoint(userPoint);

            if (!silent) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lokasi GPS berhasil ditemukan!'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal mendapatkan sinyal GPS. Coba lagi.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocatingUser = false);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan deteksi lokasi: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showServiceDisabledDialog() {
    showGlassConfirmDialog(
      context,
      title: 'Layanan Lokasi Mati',
      message:
          'GPS/Layanan lokasi perangkat tidak aktif. Harap aktifkan GPS perangkat Anda untuk menggunakan fitur ini.',
      cancelText: 'Nanti Saja',
      confirmText: 'Buka Pengaturan',
      icon: Icons.location_off_outlined,
    ).then((confirmed) {
      if (confirmed) {
        LocationService.instance.openLocationSettings();
      }
    });
  }

  void _showPermissionDeniedForeverDialog() {
    showGlassConfirmDialog(
      context,
      title: 'Izin Lokasi Ditolak Permanen',
      message:
          'Aplikasi tidak memiliki izin akses lokasi. Silakan buka Pengaturan Aplikasi untuk mengaktifkan izin lokasi.',
      cancelText: 'Tutup',
      confirmText: 'Pengaturan Aplikasi',
      icon: Icons.security_outlined,
    ).then((confirmed) {
      if (confirmed) {
        LocationService.instance.openAppSettings();
      }
    });
  }

  void _confirmLocation() {
    // Buat data details fallback jika belum selesai geocoding
    final details = _locationDetails ??
        LocationAddressDetails(
          latitude: _selectedPoint.latitude,
          longitude: _selectedPoint.longitude,
          displayName:
              'Koordinat: ${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
          isFallback: true,
        );

    Navigator.pop(context, details);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi di Peta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Petunjuk',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Geser peta atau sentuh titik mana pun untuk menentukan lokasi kurir.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Peta Flutter Map + OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint,
              initialZoom: 15.5,
              minZoom: 4,
              maxZoom: 18.5,
              onPositionChanged: _onPositionChanged,
              onTap: _onMapTapped,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.wijibumi.app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPoint,
                    width: 52,
                    height: 52,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: 4,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Banner Panduan Atas
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app_outlined,
                        size: 16,
                        color: AppColors.secondaryEmerald,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Geser peta atau sentuh lokasi pengiriman Anda',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tombol Kontrol Peta Floating (Zoom & GPS)
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFloatingButton(
                  icon: Icons.add,
                  tooltip: 'Perbesar Peta',
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_selectedPoint, currentZoom + 1);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildFloatingButton(
                  icon: Icons.remove,
                  tooltip: 'Perkecil Peta',
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_selectedPoint, currentZoom - 1);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                // Tombol "Gunakan Lokasi Saya"
                FloatingActionButton.extended(
                  heroTag: 'btn_my_location',
                  onPressed: _isLocatingUser ? null : () => _getUserLocation(),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: _isLocatingUser
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(
                    _isLocatingUser ? 'Mencari...' : 'Lokasi Saya',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Kartu Informasi & Konfirmasi Lokasi Bawah
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: GlassContainer(
                  borderRadius: 20,
                  enableGlow: true,
                  glowColor: AppColors.secondaryEmerald,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Status Geocoding
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryEmerald.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              size: 18,
                              color: AppColors.secondaryEmerald,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Titik Lokasi Pengiriman Terpilih',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Koordinat: ${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isGeocoding)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.secondaryEmerald,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 18),

                      // Alamat Terpilih / Loading State / Fallback State
                      if (_isGeocoding)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Mencari informasi alamat melalui OpenStreetMap...',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_locationDetails != null) ...[
                        Text(
                          _locationDetails!.shortTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locationDetails!.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        if (_locationDetails!.isFallback) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Rincian alamat belum terdeteksi otomatis. Koordinat tetap tersimpan dan silakan lengkapi form alamat secara manual.',
                                    style: TextStyle(fontSize: 11, color: AppColors.warning),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else ...[
                        const Text(
                          'Geser peta untuk memilih titik pengiriman...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Tombol Konfirmasi Lokasi
                      CustomButton(
                        text: 'Konfirmasi Lokasi',
                        icon: Icons.check_circle_outline,
                        backgroundColor: AppColors.primary,
                        onPressed: _confirmLocation,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ),
    );
  }
}
