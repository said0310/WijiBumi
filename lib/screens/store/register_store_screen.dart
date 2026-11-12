import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/smart_image.dart';
import 'seller_dashboard/seller_main_navigation_screen.dart';

class RegisterStoreScreen extends StatefulWidget {
  const RegisterStoreScreen({super.key});

  @override
  State<RegisterStoreScreen> createState() => _RegisterStoreScreenState();
}

class _RegisterStoreScreenState extends State<RegisterStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _hoursController = TextEditingController(text: '06:00 - 17:00 WIB');
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  Uint8List? _logoBytes;
  String? _logoFileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

  Future<void> _pickStoreLogo(ImageSource source) async {
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
        SnackBar(content: Text('Gagal memilih foto toko: $e')),
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
              'Foto Profil Toko',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickStoreLogo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Ambil Foto dengan Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickStoreLogo(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickCoordinates() {
    showGlassBottomSheet(
      context,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Titik Lokasi Kebun / Toko',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih area referensi atau isi koordinat manual.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.my_location, color: AppColors.primary),
              title: const Text('Lembang, Bandung Barat'),
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
            ListTile(
              leading: const Icon(Icons.my_location, color: AppColors.primary),
              title: const Text('Tamansari, Bogor'),
              subtitle: const Text('-6.6432, 106.7721'),
              onTap: () {
                setState(() {
                  _latController.text = '-6.6432';
                  _lngController.text = '106.7721';
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? logoUrl;
    if (_logoBytes != null) {
      logoUrl = await SupabaseService.instance.uploadImageBytes(
        bytes: _logoBytes!,
        bucket: 'store-assets',
        fileName: _logoFileName ?? 'store_logo.jpg',
      );
    }

    if (!mounted) return;
    final success = await context.read<StoreProvider>().registerStore(
          storeName: _nameController.text.trim(),
          description: _descController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          province: _provinceController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          postalCode: _postalCodeController.text.trim().isNotEmpty
              ? _postalCodeController.text.trim()
              : null,
          latitude: double.tryParse(_latController.text.trim()),
          longitude: double.tryParse(_lngController.text.trim()),
          logoPath: logoUrl,
          operatingHours: _hoursController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toko berhasil didaftarkan! Status saat ini: Menunggu Verifikasi.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SellerMainNavigationScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mendaftarkan toko. Periksa koneksi dan data Anda.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftarkan Toko Baru'),
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
            GlassContainer(
              borderRadius: 14,
              padding: const EdgeInsets.all(14),
              tintColor: AppColors.primaryContainer.withValues(alpha: 0.65),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lengkapi data toko/kebun Anda. Setelah dikirim, tim WijiBumi akan memverifikasi toko sebelum penjualan diaktifkan.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Store Logo Picker
            Center(
              child: GestureDetector(
                onTap: _showLogoPicker,
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.secondaryEmerald.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _logoBytes != null
                            ? SmartImage(memoryBytes: _logoBytes, fit: BoxFit.cover)
                            : Container(
                                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined,
                                        color: AppColors.primary, size: 28),
                                    SizedBox(height: 4),
                                    Text('Logo Toko',
                                        style: TextStyle(fontSize: 10, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap untuk unggah foto profil toko',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            CustomTextField(
              label: 'Nama Toko / Kebun',
              hint: 'Contoh: Kebun Berkah Organik',
              controller: _nameController,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nama toko wajib diisi';
                if (v.trim().length < 3) return 'Nama toko minimal 3 karakter';
                return null;
              },
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'Deskripsi Toko',
              hint: 'Jelaskan hasil panen utama dan keunggulan kebun Anda...',
              controller: _descController,
              maxLines: 3,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Deskripsi toko wajib diisi';
                if (v.trim().length < 10) return 'Deskripsi minimal 10 karakter';
                return null;
              },
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'Email Toko',
              hint: 'kontak@kebunanda.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final val = (v ?? '').trim();
                if (val.isEmpty) return 'Email toko wajib diisi';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(val)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'Nomor WhatsApp / HP Toko',
              hint: '081234567890',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nomor telepon wajib diisi';
                if (v.trim().length < 9) return 'Nomor telepon minimal 9 digit';
                return null;
              },
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'Alamat Lengkap Toko / Kebun',
              hint: 'Nama jalan, nomor, desa/kelurahan',
              controller: _addressController,
              maxLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Alamat toko wajib diisi' : null,
            ),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Provinsi',
                    hint: 'Jawa Barat',
                    controller: _provinceController,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Provinsi wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Kota / Kabupaten',
                    hint: 'Bandung Barat',
                    controller: _cityController,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Kota wajib diisi' : null,
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
                    hint: 'Parongpong',
                    controller: _districtController,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Kecamatan wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Kode Pos (Opsional)',
                    hint: '40559',
                    controller: _postalCodeController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'Jam Operasional Toko',
              hint: '06:00 - 17:00 WIB',
              controller: _hoursController,
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Lokasi & Titik Koordinat Toko (Opsional)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.pin_drop_outlined, size: 16),
                  label: const Text('Pilih Titik', style: TextStyle(fontSize: 12)),
                  onPressed: _pickCoordinates,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Latitude',
                    hint: '-6.8123',
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Longitude',
                    hint: '107.5932',
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            CustomButton(
              text: 'Kirim Pendaftaran Toko',
              isLoading: _isLoading,
              onPressed: _submitForm,
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
