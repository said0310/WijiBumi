import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wijibumi/models/address.dart';
import 'package:wijibumi/providers/address_provider.dart';
import 'package:wijibumi/providers/auth_provider.dart';
import 'package:wijibumi/screens/profile/add_edit_address_screen.dart';
import 'package:wijibumi/screens/profile/pick_location_screen.dart';
import 'package:wijibumi/services/location_service.dart';

Widget _wrapWithApp(Widget child, {AuthProvider? auth, AddressProvider? addr}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => auth ?? AuthProvider()),
      ChangeNotifierProvider<AddressProvider>(create: (_) => addr ?? AddressProvider()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('LocationAddressDetails Unit Tests', () {
    test('shortTitle formats road, district and city correctly', () {
      const details = LocationAddressDetails(
        latitude: -6.1944,
        longitude: 106.8229,
        displayName: 'Jalan Teuku Umar, Menteng, Kota Jakarta Pusat, DKI Jakarta',
        road: 'Jalan Teuku Umar',
        district: 'Menteng',
        city: 'Jakarta Pusat',
        province: 'DKI Jakarta',
        postalCode: '10350',
      );

      expect(details.shortTitle, 'Jalan Teuku Umar, Menteng, Jakarta Pusat');
      expect(details.isFallback, isFalse);
    });

    test('fallback returns displayName when details are missing', () {
      const fallback = LocationAddressDetails(
        latitude: -6.1944,
        longitude: 106.8229,
        displayName: 'Titik Koordinat: -6.19440, 106.82290',
        isFallback: true,
      );

      expect(fallback.shortTitle, 'Titik Koordinat: -6.19440, 106.82290');
      expect(fallback.isFallback, isTrue);
    });
  });

  group('PickLocationScreen Widget Tests', () {
    testWidgets('renders map screen with controls and confirmation button', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          const PickLocationScreen(
            initialLatitude: -6.1944,
            initialLongitude: 106.8229,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pilih Lokasi di Peta'), findsOneWidget);
      expect(find.text('Lokasi Saya'), findsOneWidget);
      expect(find.text('Konfirmasi Lokasi'), findsOneWidget);
      expect(find.text('Titik Lokasi Pengiriman Terpilih'), findsOneWidget);
    });
  });

  group('AddEditAddressScreen Widget Tests', () {
    testWidgets('renders delivery location section with unselected status by default', (tester) async {
      final authProv = AuthProvider();
      await tester.runAsync(() => authProv.loadUser());

      await tester.pumpWidget(
        _wrapWithApp(const AddEditAddressScreen(), auth: authProv),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lokasi Pengiriman'), findsOneWidget);
      expect(find.text('Lokasi belum ditentukan'), findsOneWidget);
      expect(find.text('Pilih Lokasi di Peta'), findsOneWidget);
      // Ensure no manual numeric latitude/longitude text inputs are displayed to customer
      expect(find.text('Latitude'), findsNothing);
      expect(find.text('Longitude'), findsNothing);
    });

    testWidgets('renders delivery location with active map preview when address has coordinates', (tester) async {
      final existingAddress = Address(
        id: 'addr-1',
        userId: 'demo-user-1',
        label: 'Kantor',
        recipientName: 'Ahmad Dahlan',
        phone: '081234567890',
        address: 'Jl. Jenderal Sudirman No. 45',
        province: 'DKI Jakarta',
        city: 'Jakarta Pusat',
        district: 'Tanah Abang',
        kelurahan: 'Karet Tengsin',
        postalCode: '10220',
        latitude: -6.2088,
        longitude: 106.8456,
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authProv = AuthProvider();
      await tester.runAsync(() => authProv.loadUser());

      await tester.pumpWidget(
        _wrapWithApp(
          AddEditAddressScreen(addressToEdit: existingAddress),
          auth: authProv,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lokasi berhasil ditentukan'), findsOneWidget);
      expect(find.text('Ubah Titik di Peta'), findsOneWidget);
      expect(find.text('-6.2088, 106.8456'), findsOneWidget);
    });
  });
}

