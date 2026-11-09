import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/product.dart';
import '../../../providers/store_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? productToEdit;

  const AddEditProductScreen({super.key, this.productToEdit});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController;
  late TextEditingController _shelfLifeController;
  late TextEditingController _farmLocationController;

  String _selectedCategory = 'Sayuran';
  String _selectedUnit = 'kg';
  String _selectedGrade = 'A';
  DateTime _harvestDate = DateTime.now();
  bool _isLoading = false;

  final Map<String, String> _categoryMap = {
    'Bunga': 'cat-1-bunga',
    'Sayuran': 'cat-2-sayuran',
    'Buah-buahan': 'cat-3-buah',
  };

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(text: p != null ? '${p.price.toInt()}' : '');
    _stockController = TextEditingController(text: p != null ? '${p.stock}' : '');
    _imageUrlController = TextEditingController(text: p?.images.isNotEmpty == true ? p!.images.first : '');
    _shelfLifeController = TextEditingController(text: p?.shelfLifeDays != null ? '${p!.shelfLifeDays}' : '7');
    _farmLocationController = TextEditingController(text: p?.farmLocation ?? '');

    if (p != null) {
      if (p.categoryName != null && _categoryMap.containsKey(p.categoryName)) {
        _selectedCategory = p.categoryName!;
      }
      _selectedUnit = p.unit;
      if (p.qualityGrade != null) _selectedGrade = p.qualityGrade!;
      if (p.harvestDate != null) _harvestDate = p.harvestDate!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _shelfLifeController.dispose();
    _farmLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Produk' : 'Tambah Produk Baru'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nama Produk
            CustomTextField(
              label: 'Nama Produk Pertanian',
              hint: 'Contoh: Mawar Merah Holland / Brokoli Organik',
              controller: _nameController,
              validator: (v) => v == null || v.isEmpty ? 'Nama produk wajib diisi' : null,
            ),

            const SizedBox(height: 14),

            // Kategori
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kategori Produk',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(),
                  items: _categoryMap.keys.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Harga & Satuan
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: 'Harga Jual (Rp)',
                    hint: '25000',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Harga wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Satuan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: AppConstants.productUnits.contains(_selectedUnit)
                            ? _selectedUnit
                            : AppConstants.productUnits.first,
                        decoration: const InputDecoration(),
                        items: AppConstants.productUnits.map((u) {
                          return DropdownMenuItem(value: u, child: Text(u));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Stok & Grade Kualitas
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: 'Jumlah Stok',
                    hint: '50',
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Stok wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Grade Kualitas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedGrade,
                        decoration: const InputDecoration(),
                        items: AppConstants.qualityGrades.map((g) {
                          return DropdownMenuItem(value: g, child: Text('Grade $g'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGrade = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Foto URL
            CustomTextField(
              label: 'URL Foto Produk',
              hint: 'https://images.unsplash.com/... (atau biarkan default)',
              controller: _imageUrlController,
            ),

            const SizedBox(height: 14),

            // Tanggal Panen Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tanggal Panen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _harvestDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _harvestDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_harvestDate.day}/${_harvestDate.month}/${_harvestDate.year}'),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Daya Tahan & Lokasi Kebun
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Daya Tahan (Hari)',
                    hint: '7',
                    controller: _shelfLifeController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Lokasi Kebun',
                    hint: 'Lembang, Bandung Barat',
                    controller: _farmLocationController,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Deskripsi
            CustomTextField(
              label: 'Deskripsi Produk',
              hint: 'Jelaskan kesegaran produk, cara penyimpanan, dan spesifikasi panen...',
              controller: _descController,
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            CustomButton(
              text: isEditing ? 'Simpan Perubahan' : 'Terbitkan Produk',
              isLoading: _isLoading,
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  final storeProvider = context.read<StoreProvider>();
                  final store = storeProvider.myStore!;

                  final img = _imageUrlController.text.trim().isNotEmpty
                      ? _imageUrlController.text.trim()
                      : (_selectedCategory == 'Bunga'
                          ? 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&q=80'
                          : _selectedCategory == 'Sayuran'
                              ? 'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?auto=format&fit=crop&w=600&q=80'
                              : 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=80');

                  final newProd = Product(
                    id: isEditing ? widget.productToEdit!.id : 'prod-${DateTime.now().millisecondsSinceEpoch}',
                    storeId: store.id,
                    categoryId: _categoryMap[_selectedCategory] ?? 'cat-2-sayuran',
                    name: _nameController.text.trim(),
                    description: _descController.text.trim(),
                    price: double.tryParse(_priceController.text.trim()) ?? 0,
                    unit: _selectedUnit,
                    stock: int.tryParse(_stockController.text.trim()) ?? 0,
                    qualityGrade: _selectedGrade,
                    harvestDate: _harvestDate,
                    shelfLifeDays: int.tryParse(_shelfLifeController.text.trim()),
                    farmLocation: _farmLocationController.text.trim().isNotEmpty
                        ? _farmLocationController.text.trim()
                        : store.city,
                    status: 'active',
                    createdAt: isEditing ? widget.productToEdit!.createdAt : DateTime.now(),
                    updatedAt: DateTime.now(),
                    images: [img],
                    categoryName: _selectedCategory,
                    storeName: store.storeName,
                    storeCity: store.city,
                    storeLogo: store.logoPath,
                  );

                  if (isEditing) {
                    await storeProvider.updateProduct(newProd);
                  } else {
                    await storeProvider.addProduct(newProd);
                  }

                  setState(() => _isLoading = false);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing ? 'Produk berhasil diubah!' : 'Produk berhasil ditambahkan!',
                        ),
                      ),
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
