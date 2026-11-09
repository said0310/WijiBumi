import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Notifikasi & Peringatan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          SwitchListTile(
            title: const Text('Notifikasi Status Pesanan'),
            subtitle: const Text('Terima pembaruan status panen & tracking paket'),
            value: _pushNotifications,
            onChanged: (val) => setState(() => _pushNotifications = val),
          ),
          SwitchListTile(
            title: const Text('Info Panen Raya & Promo'),
            subtitle: const Text('Dapatkan voucher panen dari petani mitra'),
            value: _emailUpdates,
            onChanged: (val) => setState(() => _emailUpdates = val),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Tentang Aplikasi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const ListTile(
            title: Text('Versi Aplikasi'),
            subtitle: Text('TaniHub v2.0 (Mobile Agritech Marketplace)'),
            trailing: Text('Build 2026.11', style: TextStyle(color: Colors.grey)),
          ),
          const ListTile(
            title: Text('Platform'),
            subtitle: Text('Mobile Application with Supabase PostgreSQL'),
          ),
          const ListTile(
            title: Text('Ketentuan Layanan & Kebijakan Privasi'),
            trailing: Icon(Icons.arrow_forward_ios, size: 14),
          ),
        ],
      ),
    );
  }
}
