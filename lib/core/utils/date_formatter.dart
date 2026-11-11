class DateFormatter {
  static const List<String> _shortMonths = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static const List<String> _fullMonths = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static String formatShort(DateTime date) {
    final day = date.day;
    final month = _shortMonths[date.month];
    final year = date.year;
    return '$day $month $year';
  }

  /// Formats date as `DD MMMM YYYY` (e.g. `05 Mei 2000`).
  static String formatBirthDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _fullMonths[date.month];
    final year = date.year;
    return '$day $month $year';
  }

  /// Formats date as ISO `YYYY-MM-DD` for PostgreSQL `date` columns.
  static String formatSqlDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String formatFull(DateTime date) {
    final day = date.day;
    final month = _fullMonths[date.month];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  static String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
