import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/store_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../widgets/smart_image.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _provinceController;
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _postalCodeController;
  late TextEditingController _hoursController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  Uint8List? _logoBytes;
  String? _logoFileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final store = context.read<StoreProvider>().myStore;
    _nameController = TextEditingController(text: store?.storeName ?? '');
    _descController = TextEditingController(text: store?.description ?? '');
    _phoneController = TextEditingController(text: store?.phone ?? '');
    _emailController = TextEditingController(text: store?.email ?? '');
    _addressController = TextEditingController(text: store?.address ?? '');
    _provinceController = TextEditingController(text: store?.province ?? '');
    _cityController = TextEditingController(text: store?.city ?? '');
    _districtController = TextEditingController(text: store?.district ?? '');
    _postalCodeController = TextEditingController(text: store?.postalCode ?? '');
    _hoursController =
        TextEditingController(text: store?.operatingHours ?? '06:00 - 17:00 WIB');
    _latController = TextEditingController(text: store?.latitude?.toString() ?? '');
    _lngController = TextEditingController(text: store?.longitude?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    _hoursController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _logoBytes = bytes;
          _logoFileName = picked.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat memilih foto toko: $e')),
      );
    }
  }

  void _showLogoPicker() {
    showGlassBottomSheet(
      context,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah Foto Profil Toko',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Ambil Foto dengan Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogo(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final storeProvider = context.read<StoreProvider>();
    final currentStore = storeProvider.myStore!;
    String? logoUrl = currentStore.logoPath;

    if (_logoBytes != null) {
      final uploaded = await SupabaseService.instance.uploadImageBytes(
        bytes: _logoBytes!,
        bucket: 'store-assets',
        fileName: _logoFileName ?? 'store_logo.jpg',
      );
      if (!mounted) return;
      if (uploaded == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengunggah foto profil toko. Silakan coba lagi.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      logoUrl = uploaded;
    }

    final updatedStore = currentStore.copyWith(
      storeName: _nameController.text.trim(),
      description: _descController.text.trim(),
      logoPath: logoUrl,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      province: _provinceController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      postalCode: _postalCodeController.text.trim().isNotEmpty
          ? _postalCodeController.text.trim()
          : null,
      operatingHours: _hoursController.text.trim(),
      latitude: double.tryParse(_latController.text.trim()),
      longitude: double.tryParse(_lngController.text.trim()),
    );

    final ok = await storeProvider.updateStore(updatedStore);
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Informasi toko berhasil disimpan!'
              : 'Gagal menyimpan pengaturan toko.',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>().myStore;
    if (store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengaturan Toko')),
        body: const Center(child: Text('Toko tidak ditemukan')),
      );
    }

    final statusColor = store.isApproved ? AppColors.success : AppColors.warning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Toko'),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
            // Read-only Verification Status Card
            GlassContainer(
              borderRadius: 14,
              padding: const EdgeInsets.all(14),
              tintColor: statusColor.withValues(alpha: 0.1),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              child: Row(
                children: [
                  Icon(
                    store.isApproved ? Icons.verified : Icons.hourglass_top,
                    color: statusColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Verifikasi: ${store.verificationStatusLabel}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: statusColor,
                          ),
                        ),
                        if (store.verificationNote != null)
                          Text(
                            store.verificationNote!,
                            style: const TextStyle(fontSize: 11.5),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Store Profile Photo
            Center(
              child: GestureDetector(
                onTap: _showLogoPicker,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 88,
                            height: 88,
                            child: SmartImage(
                              memoryBytes: _logoBytes,
                              source: store.logoPath ??
                                  'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&w=300&q=80',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Ubah Foto Profil Toko',
                        style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            CustomTextField(
              label: 'Nama Toko',
              controller: _nameController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nama toko wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Deskripsi Toko',
              controller: _descController,
              maxLines: 3,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Deskripsi toko wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Nomor WhatsApp / HP Toko',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nomor HP wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Email Toko',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                if (!v.contains('@') || !v.contains('.')) return 'Email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Jam Operasional Toko',
              hint: '06:00 - 17:00 WIB',
              controller: _hoursController,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Alamat Kebun / Toko',
              controller: _addressController,
              maxLines: 2,
              validator: (v) => v == null || v.trim().isEmpty ? 'Alamat wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Provinsi',
                    controller: _provinceController,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Provinsi wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Kota / Kabupaten',
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
                    controller: _districtController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Kode Pos',
                    controller: _postalCodeController,
                    keyboardType: TextInputType.number,
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
                    label: 'Latitude Lokasi',
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Longitude Lokasi',
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: 'Simpan Perubahan Toko',
              isLoading: _isLoading,
              onPressed: _saveSettings,
            ),
          ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
