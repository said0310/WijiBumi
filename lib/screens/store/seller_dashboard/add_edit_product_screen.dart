import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../widgets/smart_image.dart';

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

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  static const List<String> _allowedCategories = AppConstants.productCategories;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(text: p != null ? '${p.price.toInt()}' : '');
    _stockController = TextEditingController(text: p != null ? '${p.stock}' : '');
    _imageUrlController = TextEditingController(
      text: p?.images.isNotEmpty == true ? p!.images.first : '',
    );
    _shelfLifeController = TextEditingController(
      text: p?.shelfLifeDays != null ? '${p!.shelfLifeDays}' : '7',
    );
    _farmLocationController = TextEditingController(text: p?.farmLocation ?? '');

    if (p != null) {
      if (p.categoryName != null && _allowedCategories.contains(p.categoryName)) {
        _selectedCategory = p.categoryName!;
      }
      _selectedUnit = p.unit;
      if (p.qualityGrade != null && AppConstants.qualityGrades.contains(p.qualityGrade)) {
        _selectedGrade = p.qualityGrade!;
      }
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

  Future<void> _pickProductPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageName = picked.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto produk: $e')),
      );
    }
  }

  void _showPhotoOptions() {
    showGlassBottomSheet(
      context,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unggah Foto Produk',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickProductPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Ambil Foto dengan Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickProductPhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _resolveCategoryId(ProductProvider productProvider, String catName) {
    for (final c in productProvider.categories) {
      if (c.name.toLowerCase() == catName.toLowerCase()) {
        return c.id;
      }
    }
    return switch (catName) {
      'Bunga' => 'cat-1-bunga',
      'Sayuran' => 'cat-2-sayuran',
      'Buah-buahan' => 'cat-3-buah',
      'Rempah-rempah' => 'cat-4-rempah',
      'Bibit & Benih' => 'cat-5-bibit',
      'Umbi-umbian' => 'cat-6-umbi',
      _ => 'cat-2-sayuran',
    };
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final storeProvider = context.read<StoreProvider>();
    final productProvider = context.read<ProductProvider>();
    final store = storeProvider.myStore;
    if (store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data toko tidak ditemukan.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final isEditing = widget.productToEdit != null;

    if (!store.isApproved && !isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toko belum terverifikasi sehingga belum dapat menerbitkan produk.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (productProvider.categories.isEmpty) {
      await productProvider.initData();
      if (!mounted) return;
    }

    String imageUrl = _imageUrlController.text.trim();
    if (_pickedImageBytes != null) {
      final uploaded = await SupabaseService.instance.uploadImageBytes(
        bytes: _pickedImageBytes!,
        bucket: 'product-images',
        fileName: _pickedImageName ?? 'product.jpg',
      );
      if (!mounted) return;
      if (uploaded == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengunggah foto produk. Coba lagi nanti.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      imageUrl = uploaded;
    }

    if (imageUrl.isEmpty) {
      imageUrl = _selectedCategory == 'Bunga'
          ? 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&q=80'
          : _selectedCategory == 'Sayuran'
              ? 'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?auto=format&fit=crop&w=600&q=80'
              : 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=80';
    }

    final newProd = Product(
      id: isEditing ? widget.productToEdit!.id : 'prod-${DateTime.now().millisecondsSinceEpoch}',
      storeId: store.id,
      categoryId: _resolveCategoryId(productProvider, _selectedCategory),
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      unit: _selectedUnit,
      stock: int.parse(_stockController.text.trim()),
      qualityGrade: _selectedGrade,
      harvestDate: _harvestDate,
      shelfLifeDays: int.tryParse(_shelfLifeController.text.trim()),
      farmLocation: _farmLocationController.text.trim().isNotEmpty
          ? _farmLocationController.text.trim()
          : store.city,
      status: isEditing
          ? widget.productToEdit!.status
          : (store.isApproved ? 'active' : 'draft'),
      createdAt: isEditing ? widget.productToEdit!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
      images: [imageUrl],
      categoryName: _selectedCategory,
      storeName: store.storeName,
      storeCity: store.city,
      storeLogo: store.logoPath,
    );

    final ok = isEditing
        ? await storeProvider.updateProduct(newProd)
        : await storeProvider.addProduct(newProd);
    if (ok) {
      await productProvider.fetchProducts();
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Produk berhasil diubah!' : 'Produk berhasil ditambahkan!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Gagal mengubah produk.' : 'Gagal menambahkan produk.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;
    final previewSource = _imageUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Produk' : 'Tambah Produk Baru'),
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
            if (isEditing) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ID Produk: ${widget.productToEdit!.id}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Photo Upload & Preview
            const Text(
              'Foto Produk',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showPhotoOptions,
              child: GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: _pickedImageBytes != null || previewSource.isNotEmpty
                            ? SmartImage(
                                memoryBytes: _pickedImageBytes,
                                source: previewSource,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.primaryContainer.withValues(alpha: 0.4),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 42, color: AppColors.primary),
                                    SizedBox(height: 8),
                                    Text('Tap untuk pilih foto dari galeri / kamera',
                                        style: TextStyle(fontSize: 12, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _pickedImageBytes != null
                                ? 'Foto siap diunggah ($_pickedImageName)'
                                : 'Unggah ke Supabase Storage',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Atau URL Foto Produk (Opsional)',
              hint: 'https://images.unsplash.com/...',
              controller: _imageUrlController,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 14),

            CustomTextField(
              label: 'Nama Produk Pertanian',
              hint: 'Contoh: Mawar Merah Holland / Brokoli Organik',
              controller: _nameController,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nama produk wajib diisi' : null,
            ),

            const SizedBox(height: 14),

            // Kategori (strictly Bunga, Sayuran, Buah-buahan)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kategori Produk',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  items: _allowedCategories.map((cat) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: 'Harga Jual (Rp)',
                    hint: '25000',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Harga wajib diisi';
                      final price = double.tryParse(v.trim());
                      if (price == null || price <= 0) return 'Harga harus > 0';
                      return null;
                    },
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
                        initialValue: AppConstants.productUnits.contains(_selectedUnit)
                            ? _selectedUnit
                            : AppConstants.productUnits.first,
                        isExpanded: true,
                        decoration: const InputDecoration(),
                        items: AppConstants.productUnits.map((u) {
                          return DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis));
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: 'Jumlah Stok',
                    hint: '50',
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Stok wajib diisi';
                      final stock = int.tryParse(v.trim());
                      if (stock == null || stock < 0) return 'Stok harus >= 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Grade Kualitas',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGrade,
                        isExpanded: true,
                        decoration: const InputDecoration(),
                        items: AppConstants.qualityGrades.map((g) {
                          return DropdownMenuItem(
                            value: g,
                            child: Text('Grade $g', overflow: TextOverflow.ellipsis),
                          );
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

            // Tanggal Panen
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tanggal Panen',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _harvestDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 60)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _harvestDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Daya Tahan (Hari)',
                    hint: '7',
                    controller: _shelfLifeController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final days = int.tryParse(v.trim());
                      if (days == null || days <= 0) return 'Minimal 1 hari';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Lokasi Kebun',
                    hint: 'Lembang, Bandung Barat',
                    controller: _farmLocationController,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Lokasi kebun wajib diisi' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            CustomTextField(
              label: 'Deskripsi Produk',
              hint: 'Jelaskan kesegaran produk, cara penyimpanan, dan spesifikasi panen...',
              controller: _descController,
              maxLines: 4,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Deskripsi produk wajib diisi' : null,
            ),

            const SizedBox(height: 28),

            CustomButton(
              text: isEditing ? 'Simpan Perubahan' : 'Terbitkan Produk',
              isLoading: _isLoading,
              onPressed: _saveProduct,
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
