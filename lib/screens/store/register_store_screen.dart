import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'seller_dashboard/seller_dashboard_screen.dart';

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
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftarkan Toko Baru'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Buka toko untuk menjual hasil pertanian bunga, sayuran, dan buah langsung ke pembeli.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            CustomTextField(
              label: 'Nama Toko / Kebun',
              hint: 'Contoh: Kebun Berkah Organik',
              controller: _nameController,
              validator: (v) => v == null || v.isEmpty ? 'Nama toko wajib diisi' : null,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              label: 'Deskripsi Toko',
              hint: 'Jelaskan hasil panen utama dan keunggulan kebun Anda...',
              controller: _descController,
              maxLines: 3,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              label: 'Email Toko',
              hint: 'kontak@kebunanda.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              label: 'Nomor WhatsApp / Telepon Toko',
              hint: '081234567890',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.isEmpty ? 'Nomor telepon wajib diisi' : null,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              label: 'Alamat Kebun / Toko',
              hint: 'Nama jalan, nomor, desa/kelurahan',
              controller: _addressController,
              maxLines: 2,
              validator: (v) => v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Kota / Kabupaten',
                    hint: 'Bandung Barat',
                    controller: _cityController,
                    validator: (v) => v == null || v.isEmpty ? 'Kota wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Provinsi',
                    hint: 'Jawa Barat',
                    controller: _provinceController,
                    validator: (v) => v == null || v.isEmpty ? 'Provinsi wajib diisi' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            CustomButton(
              text: 'Daftarkan & Buka Toko',
              isLoading: _isLoading,
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  final success = await context.read<StoreProvider>().registerStore(
                        storeName: _nameController.text.trim(),
                        description: _descController.text.trim(),
                        email: _emailController.text.trim(),
                        phone: _phoneController.text.trim(),
                        address: _addressController.text.trim(),
                        city: _cityController.text.trim(),
                        province: _provinceController.text.trim(),
                      );
                  setState(() => _isLoading = false);

                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Toko berhasil didaftarkan! Selamat berjualan.')),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SellerDashboardScreen()),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
