import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/glass_widgets.dart';

class StoreFinanceScreen extends StatefulWidget {
  const StoreFinanceScreen({super.key});

  @override
  State<StoreFinanceScreen> createState() => _StoreFinanceScreenState();
}

class _StoreFinanceScreenState extends State<StoreFinanceScreen> {
  Future<void> _showAddAccountDialog(BuildContext context, StoreProvider provider) async {
    final formKey = GlobalKey<FormState>();
    String method = 'bank_transfer';
    final providerController = TextEditingController();
    final holderController = TextEditingController();
    final numberController = TextEditingController();
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Rekening / E-Wallet'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: method,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Metode'),
                        items: const [
                          DropdownMenuItem(value: 'bank_transfer', child: Text('Transfer Bank')),
                          DropdownMenuItem(value: 'e_wallet', child: Text('E-Wallet')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => method = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: providerController,
                        decoration: InputDecoration(
                          labelText: method == 'bank_transfer' ? 'Nama Bank' : 'Nama E-Wallet',
                          hintText: method == 'bank_transfer' ? 'BCA / Mandiri / BRI' : 'GoPay / OVO',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: holderController,
                        decoration: const InputDecoration(labelText: 'Nama Pemilik Rekening'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Nomor Rekening / Akun'),
                        validator: (v) =>
                            v == null || v.trim().length < 6 ? 'Minimal 6 digit' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          final messenger = ScaffoldMessenger.of(this.context);
                          try {
                            await provider.addPayoutAccount(
                              method: method,
                              providerName: providerController.text.trim(),
                              accountHolder: holderController.text.trim(),
                              accountNumber: numberController.text.trim(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (_) {
                            setDialogState(() => isSaving = false);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Gagal menyimpan rekening pencairan.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      providerController.dispose();
      holderController.dispose();
      numberController.dispose();
    }
  }

  Future<void> _showPayoutDialog(BuildContext context, StoreProvider provider) async {
    if (provider.myPayoutAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan rekening atau e-wallet terlebih dahulu.')),
      );
      return;
    }

    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedAccountId = provider.myPayoutAccounts.first.id;
    bool isSubmitting = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Ajukan Pencairan Dana'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Tersedia: ${CurrencyFormatter.format(provider.availableBalance)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Permintaan dicatat dan akan diproses saat integrasi payment gateway / disbursement aktif.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedAccountId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Tujuan Pencairan'),
                      items: provider.myPayoutAccounts.map((acc) {
                        return DropdownMenuItem(
                          value: acc.id,
                          child: Text(
                            '${acc.providerName} - ****${acc.accountNumberLast4}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedAccountId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nominal Pencairan (Rp)',
                        hintText: 'Minimal Rp 50.000',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (Opsional)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(this.context);
                          final amount = double.tryParse(amountController.text.trim()) ?? 0;
                          if (amount < 50000) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Minimal pencairan adalah Rp 50.000')),
                            );
                            return;
                          }
                          if (amount > provider.availableBalance) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Saldo tidak mencukupi')),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          try {
                            await provider.requestPayout(
                              amount,
                              selectedAccountId,
                              noteController.text.trim(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Permintaan pencairan dana berhasil dicatat!'),
                              ),
                            );
                          } catch (_) {
                            setDialogState(() => isSubmitting = false);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Gagal mengajukan pencairan dana.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  child: const Text('Ajukan Sekarang'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      amountController.dispose();
      noteController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storeProvider = context.watch<StoreProvider>();
    final paidOrders = storeProvider.myStoreOrders
        .where((o) =>
            (o.paymentStatus == 'paid' || o.status == 'completed') &&
            o.status != 'cancelled')
        .toList();
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final miniCardExtent = (94.0 * textScale.clamp(1.0, 1.35)).ceilToDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan & Pendapatan'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Saldo Card (Dynamic Glass)
                GlassContainer(
                  borderRadius: 18,
                  enableGlow: true,
                  glowColor: AppColors.secondaryEmerald,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Tersedia',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(storeProvider.availableBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Pendapatan',
                                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                                Text(
                                  CurrencyFormatter.format(storeProvider.totalRevenue),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_upward, size: 16),
                            label: const Text('Tarik Dana', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => _showPayoutDialog(context, storeProvider),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Revenue Period Breakdown Grid
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisExtent: miniCardExtent,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  children: [
                    _buildRevenueMiniCard(
                      'Pendapatan Hari Ini',
                      CurrencyFormatter.format(storeProvider.todayRevenue),
                      Icons.today,
                      isDark,
                    ),
                    _buildRevenueMiniCard(
                      'Pendapatan Minggu Ini',
                      CurrencyFormatter.format(storeProvider.weeklyRevenue),
                      Icons.date_range,
                      isDark,
                    ),
                    _buildRevenueMiniCard(
                      'Pendapatan Bulan Ini',
                      CurrencyFormatter.format(storeProvider.monthlyRevenue),
                      Icons.calendar_month,
                      isDark,
                    ),
                    _buildRevenueMiniCard(
                      'Pesanan Selesai',
                      '${storeProvider.completedOrdersCount} Transaksi',
                      Icons.check_circle_outline,
                      isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Payout Accounts Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Rekening & E-Wallet Penjual',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showAddAccountDialog(context, storeProvider),
                    ),
                  ],
                ),
          const SizedBox(height: 8),

          if (storeProvider.myPayoutAccounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Belum ada rekening pencairan tersimpan.',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            )
          else
            ...storeProvider.myPayoutAccounts.map((acc) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassContainer(
                    borderRadius: 14,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(acc.providerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('a.n ${acc.accountHolder} • ****${acc.accountNumberLast4}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        if (acc.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Utama',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                )),

          const SizedBox(height: 20),

          // Riwayat Transaksi Toko
          const Text(
            'Riwayat Transaksi Masuk',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          if (paidOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: const Text('Belum ada transaksi penjualan tercatat.',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            )
          else
            ...paidOrders.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassContainer(
                    borderRadius: 14,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.orderCode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${o.buyerName ?? 'Pembeli'} • ${DateFormatter.formatShort(o.createdAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+ ${CurrencyFormatter.format(o.subtotal)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.secondaryEmerald,
                              ),
                            ),
                            Text(
                              o.status == 'completed' ? 'Selesai' : 'Terbayar',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),

          const SizedBox(height: 20),

          // Riwayat Pencairan Dana
          const Text(
            'Riwayat Pencairan Dana',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          if (storeProvider.myPayoutRequests.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: const Text('Belum ada riwayat pencairan dana.',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            )
          else
            ...storeProvider.myPayoutRequests.map((req) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassContainer(
                    borderRadius: 14,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyFormatter.format(req.amount),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${req.referenceNumber ?? ''} • ${DateFormatter.formatShort(req.requestedAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: req.status == 'paid'
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              req.status == 'paid' ? 'Selesai Ditransfer' : 'Menunggu Proses',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: req.status == 'paid' ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueMiniCard(String label, String value, IconData icon, bool isDark) {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.secondaryEmerald),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
