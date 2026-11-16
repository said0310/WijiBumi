class AppConstants {
  static const String appName = 'WijiBumi';
  static const String appTagline = 'Tumbuh Bersama, Sejahtera Bersama';

  // Categories
  static const String catFlowers = 'Bunga';
  static const String catVegetables = 'Sayuran';
  static const String catFruits = 'Buah-buahan';
  static const String catSpices = 'Rempah-rempah';
  static const String catSeeds = 'Bibit & Benih';
  static const String catTubers = 'Umbi-umbian';

  static const List<String> productCategories = [
    catFlowers,
    catVegetables,
    catFruits,
    catSpices,
    catSeeds,
    catTubers,
  ];

  // Order Statuses (English codes matching SQL schema, with Indonesian UI labels)
  static const String statusPendingPayment = 'pending_payment';
  static const String statusAwaitingConfirmation = 'awaiting_confirmation';
  static const String statusProcessing = 'processing';
  static const String statusReadyToShip = 'ready_to_ship';
  static const String statusShipped = 'shipped';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Quality Grades
  static const List<String> qualityGrades = ['A', 'B', 'C'];

  // Product Units
  static const List<String> productUnits = [
    'kg',
    'gram',
    'ikat',
    'tangkai',
    'box',
    'keranjang',
    'pack',
    'butir',
  ];

  static String getStatusLabel(String status) {
    switch (status) {
      case statusPendingPayment:
        return 'Menunggu Pembayaran';
      case statusAwaitingConfirmation:
        return 'Menunggu Konfirmasi';
      case statusProcessing:
        return 'Pesanan Diproses';
      case statusReadyToShip:
        return 'Siap Dikirim';
      case statusShipped:
        return 'Sedang Dikirim';
      case statusCompleted:
        return 'Selesai';
      case statusCancelled:
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  static String getPaymentStatusLabel(String status) {
    switch (status) {
      case 'unpaid':
        return 'Belum Bayar';
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'paid':
        return 'Lunas';
      case 'failed':
        return 'Gagal';
      case 'refunded':
        return 'Dikembalikan';
      default:
        return status;
    }
  }

  // Couriers & Shipping Fees
  static const Map<String, double> courierShippingFees = {
    'J&T Express Cargo Tani': 15000.0,
    'SiCepat Cargo Fresh': 18000.0,
    'AnterAja Sameday': 25000.0,
  };

  static List<String> get availableCouriers => courierShippingFees.keys.toList();

  static double getCourierShippingFee(String courierName) {
    return courierShippingFees[courierName] ?? 15000.0;
  }

  static String getCourierServiceName(String courierName) {
    switch (courierName) {
      case 'SiCepat Cargo Fresh':
        return 'Best Fresh 1-2 Hari';
      case 'AnterAja Sameday':
        return 'Sameday Petik Pagi';
      case 'J&T Express Cargo Tani':
      default:
        return 'Reguler Fresh Cargo';
    }
  }
}
