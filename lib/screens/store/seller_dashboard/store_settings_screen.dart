import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';

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
  late TextEditingController _cityController;
  late TextEditingController _provinceController;
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
    _cityController = TextEditingController(text: store?.city ?? '');
    _provinceController = TextEditingController(text: store?.province ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Profil Toko'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              label: 'Nama Toko',
              controller: _nameController,
              validator: (v) => v == null || v.isEmpty ? 'Nama toko wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Deskripsi Toko',
              controller: _descController,
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Nomor WhatsApp / HP Toko',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Email Toko',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Alamat Kebun / Toko',
              controller: _addressController,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Kota / Kabupaten',
                    controller: _cityController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Provinsi',
                    controller: _provinceController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Simpan Perubahan Toko',
              isLoading: _isLoading,
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  final storeProvider = context.read<StoreProvider>();
                  final updatedStore = storeProvider.myStore!.copyWith(
                    storeName: _nameController.text.trim(),
                    description: _descController.text.trim(),
                    phone: _phoneController.text.trim(),
                    email: _emailController.text.trim(),
                    address: _addressController.text.trim(),
                    city: _cityController.text.trim(),
                    province: _provinceController.text.trim(),
                  );
                  await storeProvider.updateStore(updatedStore);
                  setState(() => _isLoading = false);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informasi toko berhasil disimpan!')),
                    );
                    Navigator.pop(context);
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
