import 'package:flutter/material.dart';
import '../../models/wishlist_item.dart';
import '../../services/wishlist_service.dart';
import '../../widgets/smart_image.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  Future<void> _editNote(
      BuildContext context, int index, WishlistItem item) async {
    String text = item.note;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catatan'),
        content: TextFormField(
          initialValue: item.note,
          maxLines: 2,
          onChanged: (v) => text = v,
          decoration: const InputDecoration(hintText: 'Mis. beli untuk acara Sabtu'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result != null) await WishlistService.updateNote(index, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist Saya')),
      body: ValueListenableBuilder(
        valueListenable: WishlistService.listenable,
        builder: (context, box, child) {
          if (WishlistService.count == 0) {
            return const Center(child: Text('Belum ada produk di wishlist'));
          }
          return ListView.builder(
            itemCount: WishlistService.count,
            itemBuilder: (context, index) {
              final item = WishlistService.getAt(index)!;
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SmartImage(source: item.imageUrl, width: 56, height: 56),
                ),
                title: Text(item.displayTitle),
                subtitle: Text(
                  item.note.isEmpty
                      ? item.displaySubtitle
                      : '${item.displaySubtitle}\n📝 ${item.note}',
                ),
                isThreeLine: item.note.isNotEmpty,
                onTap: () => _editNote(context, index, item),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Hapus',
                  onPressed: () async {
                    await WishlistService.removeAt(index);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.displayTitle} dihapus')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}