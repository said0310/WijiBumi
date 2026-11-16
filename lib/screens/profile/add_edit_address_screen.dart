import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_guard.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glass_widgets.dart';

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
  late TextEditingController _latController;
  late TextEditingController _lngController;

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
  late String _initialLat;
  late String _initialLng;
  late bool _initialIsDefault;

  @override
  void initState() {
    super.initState();
    final a = widget.addressToEdit;
    final user = context.read<AuthProvider>().user;

    _labelController = TextEditingController(text: a?.label ?? 'Rumah');
    _recipientController = TextEditingController(text: a?.recipientName ?? user?.fullName ?? '');
    _phoneController = TextEditingController(text: a?.phone ?? user?.phone ?? '');
    _addressController = TextEditingController(text: a?.address ?? '');
    _provinceController = TextEditingController(text: a?.province ?? '');
    _cityController = TextEditingController(text: a?.city ?? '');
    _districtController = TextEditingController(text: a?.district ?? '');
    _kelurahanController = TextEditingController(text: a?.kelurahan ?? '');
    _postalCodeController = TextEditingController(text: a?.postalCode ?? '');
    _noteController = TextEditingController(text: a?.note ?? '');
    _latController = TextEditingController(text: a?.latitude?.toString() ?? '');
    _lngController = TextEditingController(text: a?.longitude?.toString() ?? '');
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
    _initialLat = _latController.text;
    _initialLng = _lngController.text;
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
        _latController.text != _initialLat ||
        _lngController.text != _initialLng ||
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
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _pickPresetCoordinates() {
    showGlassBottomSheet(
      context,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Titik Lokasi Pengiriman',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Siap dihubungkan dengan Google Maps / GPS SDK. Pilih titik area atau isi koordinat manual.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.my_location, color: AppColors.primary),
              title: const Text('Jakarta Pusat (Menteng)'),
              subtitle: const Text('-6.1944, 106.8229'),
              onTap: () {
                setState(() {
                  _latController.text = '-6.1944';
                  _lngController.text = '106.8229';
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.my_location, color: AppColors.primary),
              title: const Text('Bandung (Lembang)'),
              subtitle: const Text('-6.8123, 107.5932'),
              onTap: () {
                setState(() {
                  _latController.text = '-6.8123';
                  _lngController.text = '107.5932';
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.my_location, color: AppColors.primary),
              title: const Text('Kota Batu, Malang'),
              subtitle: const Text('-7.8214, 112.5298'),
              onTap: () {
                setState(() {
                  _latController.text = '-7.8214';
                  _lngController.text = '112.5298';
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

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

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

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
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      latitude: lat,
      longitude: lng,
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
            isEditing ? 'Alamat berhasil diperbarui!' : 'Alamat baru berhasil ditambahkan!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, savedAddress);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.lastError ?? 'Gagal menyimpan alamat. Silakan coba lagi.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.addressToEdit != null;

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
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: ['Rumah', 'Kantor', 'Kebun', 'Gudang'].map((lbl) {
                      final selected = _labelController.text.trim() == lbl;
                      return ChoiceChip(
                        label: Text(lbl),
                        selected: selected,
                        onSelected: (_) => setState(() => _labelController.text = lbl),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Label Alamat',
                    hint: 'Rumah / Kantor / Lainnya',
                    controller: _labelController,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Label wajib diisi' : null,
                  ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Nama Penerima',
              hint: 'Budi Santoso',
              controller: _recipientController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nama penerima wajib diisi' : null,
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
              validator: (v) => v == null || v.trim().isEmpty ? 'Alamat lengkap wajib diisi' : null,
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
                    validator: (v) => v == null || v.trim().isEmpty ? 'Provinsi wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Kota / Kabupaten',
                    hint: 'Jakarta Pusat',
                    controller: _cityController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Kota wajib diisi' : null,
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
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Kecamatan wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Kelurahan',
                    hint: 'Gondangdia',
                    controller: _kelurahanController,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Kelurahan wajib diisi' : null,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Titik Lokasi Peta (Opsional)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.pin_drop_outlined, size: 16),
                  label: const Text('Pin Lokasi', style: TextStyle(fontSize: 12)),
                  onPressed: _pickPresetCoordinates,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Latitude',
                    hint: '-6.1944',
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final val = (v ?? '').trim();
                      final lngVal = _lngController.text.trim();
                      if (val.isEmpty) {
                        return lngVal.isNotEmpty
                            ? 'Latitude wajib diisi bersama Longitude'
                            : null;
                      }
                      final numVal = double.tryParse(val);
                      if (numVal == null || numVal < -90 || numVal > 90) {
                        return 'Latitude tidak valid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Longitude',
                    hint: '106.8229',
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final val = (v ?? '').trim();
                      final latVal = _latController.text.trim();
                      if (val.isEmpty) {
                        return latVal.isNotEmpty
                            ? 'Longitude wajib diisi bersama Latitude'
                            : null;
                      }
                      final numVal = double.tryParse(val);
                      if (numVal == null || numVal < -180 || numVal > 180) {
                        return 'Longitude tidak valid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
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
              title: const Text('Jadikan Alamat Utama', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Otomatis dipilih saat melakukan checkout'),
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
}

