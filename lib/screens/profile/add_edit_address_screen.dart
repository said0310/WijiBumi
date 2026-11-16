import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_guard.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glass_widgets.dart';
import 'pick_location_screen.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Address? addressToEdit;

  const AddEditAddressScreen({super.key, this.addressToEdit});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _labelController;
  late TextEditingController _recipientController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _provinceController;
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _kelurahanController;
  late TextEditingController _postalCodeController;
  late TextEditingController _noteController;

  // Koordinat lokasi pengiriman
  double? _latitude;
  double? _longitude;
  String? _selectedLocationAddress;

  bool _isDefault = false;
  bool _isLoading = false;
  bool _allowPop = false;

  late String _initialLabel;
  late String _initialRecipient;
  late String _initialPhone;
  late String _initialAddress;
  late String _initialProvince;
  late String _initialCity;
  late String _initialDistrict;
  late String _initialKelurahan;
  late String _initialPostalCode;
  late String _initialNote;
  double? _initialLatitude;
  double? _initialLongitude;
  late bool _initialIsDefault;

  @override
  void initState() {
    super.initState();
    final a = widget.addressToEdit;
    final user = context.read<AuthProvider>().user;

    _labelController = TextEditingController(text: a?.label ?? 'Rumah');
    _recipientController =
        TextEditingController(text: a?.recipientName ?? user?.fullName ?? '');
    _phoneController =
        TextEditingController(text: a?.phone ?? user?.phone ?? '');
    _addressController = TextEditingController(text: a?.address ?? '');
    _provinceController = TextEditingController(text: a?.province ?? '');
    _cityController = TextEditingController(text: a?.city ?? '');
    _districtController = TextEditingController(text: a?.district ?? '');
    _kelurahanController = TextEditingController(text: a?.kelurahan ?? '');
    _postalCodeController = TextEditingController(text: a?.postalCode ?? '');
    _noteController = TextEditingController(text: a?.note ?? '');

    _latitude = a?.latitude;
    _longitude = a?.longitude;
    _selectedLocationAddress = a?.fullAddressText;
    _isDefault = a?.isDefault ?? false;

    _initialLabel = _labelController.text;
    _initialRecipient = _recipientController.text;
    _initialPhone = _phoneController.text;
    _initialAddress = _addressController.text;
    _initialProvince = _provinceController.text;
    _initialCity = _cityController.text;
    _initialDistrict = _districtController.text;
    _initialKelurahan = _kelurahanController.text;
    _initialPostalCode = _postalCodeController.text;
    _initialNote = _noteController.text;
    _initialLatitude = _latitude;
    _initialLongitude = _longitude;
    _initialIsDefault = _isDefault;
  }

  bool _hasUnsavedChanges() {
    return _labelController.text != _initialLabel ||
        _recipientController.text != _initialRecipient ||
        _phoneController.text != _initialPhone ||
        _addressController.text != _initialAddress ||
        _provinceController.text != _initialProvince ||
        _cityController.text != _initialCity ||
        _districtController.text != _initialDistrict ||
        _kelurahanController.text != _initialKelurahan ||
        _postalCodeController.text != _initialPostalCode ||
        _noteController.text != _initialNote ||
        _latitude != _initialLatitude ||
        _longitude != _initialLongitude ||
        _isDefault != _initialIsDefault;
  }

  Future<void> _handleCancel() async {
    if (_isLoading) return;
    if (!_hasUnsavedChanges()) {
      setState(() => _allowPop = true);
      if (mounted) Navigator.pop(context);
      return;
    }
    final discard = await showGlassConfirmDialog(
      context,
      title: 'Batalkan Perubahan?',
      message:
          'Perubahan pada formulir alamat belum disimpan. Yakin ingin keluar?',
      cancelText: 'Lanjut Edit',
      confirmText: 'Keluar',
      confirmColor: AppColors.error,
      icon: Icons.warning_amber_outlined,
    );
    if (discard && mounted) {
      setState(() => _allowPop = true);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _recipientController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _kelurahanController.dispose();
    _postalCodeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Membuka halaman pemilihan lokasi di peta menggunakan Flutter Map dan OSM
  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LocationAddressDetails>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _selectedLocationAddress = result.shortTitle;

        // Auto-fill field yang masih kosong
        if (result.road != null && result.road!.isNotEmpty) {
          if (_addressController.text.trim().isEmpty) {
            _addressController.text = result.road!;
          }
        } else if (_addressController.text.trim().isEmpty && !result.isFallback) {
          _addressController.text = result.displayName;
        }

        if (result.province != null && result.province!.isNotEmpty) {
          if (_provinceController.text.trim().isEmpty) {
            _provinceController.text = result.province!;
          }
        }
        if (result.city != null && result.city!.isNotEmpty) {
          if (_cityController.text.trim().isEmpty) {
            _cityController.text = result.city!;
          }
        }
        if (result.district != null && result.district!.isNotEmpty) {
          if (_districtController.text.trim().isEmpty) {
            _districtController.text = result.district!;
          }
        }
        if (result.kelurahan != null && result.kelurahan!.isNotEmpty) {
          if (_kelurahanController.text.trim().isEmpty) {
            _kelurahanController.text = result.kelurahan!;
          }
        }
        if (result.postalCode != null && result.postalCode!.isNotEmpty) {
          if (_postalCodeController.text.trim().isEmpty) {
            _postalCodeController.text = result.postalCode!;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi berhasil ditentukan dari peta!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Harap tentukan titik lokasi pengiriman di peta terlebih dahulu.',
          ),
          backgroundColor: AppColors.warning,
          action: SnackBarAction(
            label: 'Pilih Peta',
            textColor: Colors.white,
            onPressed: _openMapPicker,
          ),
        ),
      );
      return;
    }

    final uid = context.read<AuthProvider>().user?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu untuk menyimpan alamat.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<AddressProvider>();
    final isEditing = widget.addressToEdit != null;

    final addressObj = Address(
      id: isEditing ? widget.addressToEdit!.id : '',
      userId: uid,
      label: _labelController.text.trim(),
      recipientName: _recipientController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      province: _provinceController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      kelurahan: _kelurahanController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      latitude: _latitude,
      longitude: _longitude,
      isDefault: _isDefault,
      createdAt: isEditing ? widget.addressToEdit!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Address? savedAddress;
    if (isEditing) {
      final ok = await provider.updateAddress(addressObj);
      if (ok) savedAddress = addressObj;
    } else {
      savedAddress = await provider.addAddressAndReturn(addressObj);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (savedAddress != null) {
      setState(() => _allowPop = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Alamat berhasil diperbarui!'
                : 'Alamat baru berhasil ditambahkan!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, savedAddress);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.lastError ??
                'Gagal menyimpan alamat. Silakan periksa kembali koneksi Anda.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.addressToEdit != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleCancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Alamat Pengiriman' : 'Tambah Alamat Baru'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Kembali',
            onPressed: _handleCancel,
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Pilihan Label Alamat
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: ['Rumah', 'Kantor', 'Kebun', 'Gudang'].map((lbl) {
                        final selected = _labelController.text.trim() == lbl;
                        return ChoiceChip(
                          label: Text(lbl),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _labelController.text = lbl),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Label Alamat',
                      hint: 'Rumah / Kantor / Lainnya',
                      controller: _labelController,
                      onChanged: (_) => setState(() {}),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Label wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Section Lokasi Pengiriman (Menggantikan input manual Lat/Lng)
                    _buildDeliveryLocationSection(isDark),
                    const SizedBox(height: 14),

                    CustomTextField(
                      label: 'Nama Penerima',
                      hint: 'Budi Santoso',
                      controller: _recipientController,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama penerima wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Nomor HP Penerima',
                      hint: '081234567890',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) => validateIndonesianPhoneNumber(
                        v,
                        invalidMessage:
                            'Format nomor HP Indonesia tidak valid (contoh: 081234567890)',
                      ),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Alamat Lengkap',
                      hint: 'Nama jalan, nomor rumah, RT/RW, patokan',
                      controller: _addressController,
                      maxLines: 3,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Alamat lengkap wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Provinsi',
                            hint: 'DKI Jakarta',
                            controller: _provinceController,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Provinsi wajib diisi'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Kota / Kabupaten',
                            hint: 'Jakarta Pusat',
                            controller: _cityController,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Kota wajib diisi'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Kecamatan',
                            hint: 'Menteng',
                            controller: _districtController,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Kecamatan wajib diisi'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Kelurahan',
                            hint: 'Gondangdia',
                            controller: _kelurahanController,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Kelurahan wajib diisi'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Kode Pos',
                      hint: '10310',
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final val = (v ?? '').trim();
                        if (val.isEmpty) return 'Kode pos wajib diisi';
                        if (!RegExp(r'^\d{5}$').hasMatch(val)) {
                          return 'Kode pos harus 5 digit angka';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Catatan Kurir (Opsional)',
                      hint: 'Pagar hijau, titip satpam',
                      controller: _noteController,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Jadikan Alamat Utama',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Otomatis dipilih saat melakukan checkout',
                      ),
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Batal',
                            isOutlined: true,
                            onPressed: _isLoading ? null : _handleCancel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: CustomButton(
                            text: isEditing ? 'Simpan Perubahan' : 'Simpan Alamat',
                            isLoading: _isLoading,
                            onPressed: _saveAddress,
                          ),
                        ),
                      ],
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

  /// Section Lokasi Pengiriman interaktif dengan preview peta dan status
  Widget _buildDeliveryLocationSection(bool isDark) {
    final hasLocation = _latitude != null && _longitude != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLocation
              ? AppColors.secondaryEmerald.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: hasLocation ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Lokasi Pengiriman',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasLocation
                      ? AppColors.success.withValues(alpha: 0.14)
                      : AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasLocation
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      size: 13,
                      color: hasLocation ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasLocation
                          ? 'Lokasi berhasil ditentukan'
                          : 'Lokasi belum ditentukan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            hasLocation ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (hasLocation) ...[
            // Preview peta OpenStreetMap
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(_latitude!, _longitude!),
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none, // Static preview mode
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.wijibumi.app',
                          maxZoom: 19,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_latitude!, _longitude!),
                              width: 36,
                              height: 36,
                              alignment: Alignment.topCenter,
                              child: const Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedLocationAddress != null &&
                _selectedLocationAddress!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.pin_drop_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selectedLocationAddress!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            CustomButton(
              text: 'Ubah Titik di Peta',
              icon: Icons.edit_location_alt_outlined,
              isOutlined: true,
              height: 40,
              onPressed: _openMapPicker,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.sageBorder.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.location_searching,
                    size: 38,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Titik Lokasi Pengiriman Belum Ditentukan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih titik pengiriman di peta OpenStreetMap agar lokasi kurir akurat tanpa perlu memasukkan koordinat manual.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    text: 'Pilih Lokasi di Peta',
                    icon: Icons.add_location_alt_outlined,
                    height: 40,
                    backgroundColor: AppColors.primary,
                    onPressed: _openMapPicker,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
