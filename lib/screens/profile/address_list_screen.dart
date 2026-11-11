import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_widgets.dart';
import 'add_edit_address_screen.dart';

class AddressListScreen extends StatelessWidget {
  final bool selectionMode;

  const AddressListScreen({super.key, this.selectionMode = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addressProvider = context.watch<AddressProvider>();
    final addresses = addressProvider.addresses;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectionMode ? 'Pilih Alamat Pengiriman' : 'Alamat Pengiriman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Tambah Alamat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => addressProvider.loadAddresses(),
        child: addressProvider.isLoading && addresses.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : addresses.isEmpty
                ? EmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'Belum Ada Alamat Pengiriman',
                    message: 'Tambahkan alamat pengiriman Anda agar proses checkout lebih cepat.',
                    buttonText: '+ Tambah Alamat Baru',
                    onButtonPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
                      );
                    },
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      92 + MediaQuery.paddingOf(context).bottom,
                    ),
                    itemCount: addresses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final addr = addresses[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: _buildAddressCard(context, addr, addressProvider, isDark),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Alamat'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    Address addr,
    AddressProvider provider,
    bool isDark,
  ) {
    return InkWell(
      onTap: selectionMode
          ? () => Navigator.pop(context, addr)
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditAddressScreen(addressToEdit: addr)),
              );
            },
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        borderRadius: 16,
        enableGlow: addr.isDefault,
        padding: const EdgeInsets.all(14),
        border: Border.all(
          color: addr.isDefault
              ? AppColors.secondaryEmerald
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: addr.isDefault ? 1.5 : 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 18,
                  color: addr.isDefault ? AppColors.secondaryEmerald : AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        addr.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (addr.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryEmerald.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Alamat Utama',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryEmerald,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditAddressScreen(addressToEdit: addr),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  tooltip: 'Hapus',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    final confirm = await showGlassConfirmDialog(
                      context,
                      title: 'Hapus Alamat?',
                      message: 'Apakah Anda yakin ingin menghapus alamat "${addr.label}"?',
                      confirmText: 'Hapus',
                      confirmColor: AppColors.error,
                      icon: Icons.delete_forever_outlined,
                    );
                    if (confirm) {
                      final ok = await provider.deleteAddress(addr.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Alamat berhasil dihapus.'
                                  : 'Gagal menghapus alamat.',
                            ),
                            backgroundColor: ok ? null : AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${addr.recipientName} • ${addr.phone}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              addr.fullAddressText,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            if (addr.note != null && addr.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Catatan: ${addr.note}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ],
            if (addr.latitude != null && addr.longitude != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.my_location, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Titik Peta: ${addr.latitude!.toStringAsFixed(4)}, ${addr.longitude!.toStringAsFixed(4)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
            if (!addr.isDefault) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Jadikan Alamat Utama', style: TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final ok = await provider.setDefaultAddress(addr.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? '${addr.label} ditetapkan sebagai alamat utama.'
                                : 'Gagal memperbarui alamat utama.',
                          ),
                          backgroundColor: ok ? null : AppColors.error,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

