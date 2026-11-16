import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/support_ticket.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glass_widgets.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFaqCategory = 'Semua';
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Cara Membeli & Checkout';
  bool _isSubmitting = false;
  List<SupportTicket> _myTickets = [];
  bool _isLoadingTickets = false;

  static const List<String> _faqCategories = [
    'Semua',
    'Pembelian',
    'Checkout',
    'Pelacakan',
    'Toko Saya',
    'Produk Penjual',
    'Bantuan',
  ];

  static const List<Map<String, String>> _faqItems = [
    {
      'category': 'Pembelian',
      'question': 'Bagaimana cara membeli produk di WijiBumi?',
      'answer':
          '1. Buka halaman Beranda atau tab Toko untuk menjelajahi bunga, sayuran, dan buah-buahan.\n'
              '2. Pilih produk yang diinginkan, cek Grade Kualitas (A/B/C), tanggal panen, dan stok.\n'
              '3. Klik "+ Keranjang" untuk mengumpulkan belanjaan atau "Beli Sekarang" untuk langsung ke Checkout.',
    },
    {
      'category': 'Checkout',
      'question': 'Bagaimana cara melakukan checkout pesanan?',
      'answer':
          '1. Buka ikon Keranjang Belanja di Beranda.\n'
              '2. Periksa jumlah dan toko asal produk lalu tekan "Checkout".\n'
              '3. Pilih atau tambahkan Alamat Pengiriman yang tepat.\n'
              '4. Pilih layanan kurir segar berpendingin dan metode pembayaran (Transfer Bank, E-Wallet, atau COD).\n'
              '5. Tekan "Buat Pesanan" untuk menyelesaikan transaksi.',
    },
    {
      'category': 'Pelacakan',
      'question': 'Bagaimana cara melacak pesanan saya?',
      'answer':
          '1. Buka menu Pesanan di navigasi bawah atau Riwayat Pembelian di Profile.\n'
              '2. Pilih pesanan yang berstatus Diproses, Siap Dikirim, atau Sedang Dikirim.\n'
              '3. Tekan tombol "Lacak" untuk melihat nomor resi, kurir, estimasi tiba, dan linimasa perjalanan paket secara real-time.',
    },
    {
      'category': 'Toko Saya',
      'question': 'Bagaimana cara mendaftarkan toko untuk berjualan?',
      'answer':
          '1. Buka tab Profile -> tekan kartu "Toko Saya".\n'
              '2. Jika belum memiliki toko, tekan tombol "Daftarkan Toko".\n'
              '3. Lengkapi nama toko, foto profil toko, deskripsi, email, nomor HP, alamat lengkap, provinsi, kota/kabupaten, kecamatan, dan titik lokasi.\n'
              '4. Setelah dikirim, status toko akan menjadi "Menunggu Verifikasi" sebelum dapat mulai menjual.',
    },
    {
      'category': 'Produk Penjual',
      'question': 'Bagaimana cara menambahkan produk ke toko saya?',
      'answer':
          '1. Pastikan toko Anda telah disetujui dan terverifikasi.\n'
              '2. Buka Dashboard Toko Saya -> pilih "Manajemen Produk".\n'
              '3. Tekan "+ Tambah Produk", pilih kategori (Bunga, Sayuran, atau Buah-buahan), unggah foto produk, isi harga, satuan, stok, grade kualitas, tanggal panen, daya tahan, dan lokasi kebun.',
    },
    {
      'category': 'Bantuan',
      'question': 'Bagaimana cara menghubungi Customer Service WijiBumi?',
      'answer':
          'Anda dapat mengirimkan pertanyaan atau kendala melalui formulir Hubungi Customer Service di bawah halaman ini, atau melalui email dukungan@wijibumi.id pada jam operasional Senin - Minggu pukul 08.00 - 20.00 WIB.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    if (SupabaseService.instance.activeUserId == null) return;
    setState(() => _isLoadingTickets = true);
    try {
      final list = await SupabaseService.instance.getMySupportTickets();
      if (!mounted) return;
      setState(() {
        _myTickets = list;
        _isLoadingTickets = false;
      });
    } catch (e) {
      debugPrint('Error loading support tickets: $e');
      if (mounted) setState(() => _isLoadingTickets = false);
    }
  }

  Future<void> _copySupportEmail() async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(const ClipboardData(text: 'dukungan@wijibumi.id'));
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Email dukungan@wijibumi.id disalin ke clipboard.'),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await ensureBuyerAuthenticated(context)) return;
    if (!mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final created = await SupabaseService.instance.submitSupportTicket(
        category: _selectedCategory,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _myTickets = [created, ..._myTickets];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesan berhasil dikirim ke Customer Service WijiBumi!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim pesan bantuan. Periksa koneksi Anda.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredFaqs = _faqItems.where((item) {
      final matchesCategory = _selectedFaqCategory == 'Semua' ||
          item['category'] == _selectedFaqCategory;
      if (!matchesCategory) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item['question']!.toLowerCase().contains(q) ||
          item['answer']!.toLowerCase().contains(q) ||
          item['category']!.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Bantuan'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Search FAQ
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari panduan atau pertanyaan (mis. checkout, resi, toko)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                  ),
                ),

          const SizedBox(height: 18),
          const Text(
            'Pertanyaan Umum (FAQ) & Panduan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _faqCategories.map((cat) {
                final selected = _selectedFaqCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedFaqCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          if (filteredFaqs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Topik bantuan tidak ditemukan.')),
            )
          else
            ...filteredFaqs.map((faq) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  borderRadius: 14,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: const Icon(Icons.help_outline, color: AppColors.primary),
                    title: Text(
                      faq['question']!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      faq['category']!,
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryEmerald),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          faq['answer']!,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),

          // Contact Customer Service Form
          GlassContainer(
            borderRadius: 16,
            enableGlow: true,
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.support_agent, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hubungi Customer Service',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Layanan dukungan aktif setiap hari 08.00 - 20.00 WIB',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _copySupportEmail,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email_outlined, size: 14, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'dukungan@wijibumi.id',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.copy_outlined, size: 13, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Kategori Bantuan'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Cara Membeli & Checkout',
                        child: Text('Cara Membeli & Checkout', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'Pesanan & Pengiriman',
                        child: Text('Pesanan & Pengiriman', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'Pendaftaran & Verifikasi Toko',
                        child: Text('Pendaftaran & Verifikasi Toko', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'Akun & Keamanan',
                        child: Text('Akun & Keamanan', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Subjek Kendala',
                    hint: 'Contoh: Kendala pengiriman pesanan',
                    controller: _subjectController,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Subjek wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Detail Pesan',
                    hint: 'Ceritakan pertanyaan atau kendala Anda secara rinci...',
                    controller: _messageController,
                    maxLines: 4,
                    validator: (v) =>
                        v == null || v.trim().length < 10 ? 'Jelaskan minimal 10 karakter' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Kirim ke Customer Service',
                    icon: Icons.send,
                    width: double.infinity,
                    isLoading: _isSubmitting,
                    onPressed: _submitTicket,
                  ),
                ],
              ),
            ),
          ),

          if (SupabaseService.instance.activeUserId != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Riwayat Tiket Bantuan Saya',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_isLoadingTickets)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_myTickets.isEmpty)
              GlassContainer(
                borderRadius: 14,
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Belum ada tiket bantuan yang Anda kirim.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              )
            else
              ..._myTickets.map((ticket) {
                final (statusLabel, statusColor) = switch (ticket.status) {
                  'resolved' => ('Selesai', AppColors.success),
                  'in_progress' => ('Diproses', AppColors.primary),
                  _ => ('Terbuka', AppColors.warning),
                };
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: GlassContainer(
                    borderRadius: 14,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ticket.subject,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ticket.category} • ${DateFormatter.formatShort(ticket.createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ticket.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ],
            ),
          ),
        ),
      ),
    );
  }
}

