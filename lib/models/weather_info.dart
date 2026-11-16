import 'package:flutter/material.dart';

class WeatherInfo {
  final double temperature;
  final int humidity;
  final double windSpeed;
  final double precipitation;
  final int weatherCode;

  WeatherInfo({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.weatherCode,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    return WeatherInfo(
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      precipitation: (current['precipitation'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
    );
  }

  String get description {
    if (weatherCode == 0) return 'Cerah';
    if (weatherCode <= 3) return 'Berawan';
    if (weatherCode == 45 || weatherCode == 48) return 'Berkabut';
    if (weatherCode >= 51 && weatherCode <= 67) return 'Hujan';
    if (weatherCode >= 71 && weatherCode <= 82) return 'Hujan lebat';
    if (weatherCode >= 95) return 'Badai petir';
    return 'Tidak diketahui';
  }

  IconData get icon {
    if (weatherCode == 0) return Icons.wb_sunny_outlined;
    if (weatherCode <= 3) return Icons.cloud_outlined;
    if (weatherCode == 45 || weatherCode == 48) return Icons.foggy;
    if (weatherCode >= 95) return Icons.thunderstorm_outlined;
    if (weatherCode >= 51) return Icons.water_drop_outlined;
    return Icons.cloud_outlined;
  }

  String get farmingTip {
    if (weatherCode >= 95) {
      return 'Ada potensi badai. Tunda panen dan amankan tanaman.';
    }
    if (weatherCode >= 51) {
      return 'Sedang hujan. Pengiriman hasil panen bisa tertunda.';
    }
    if (temperature >= 32) {
      return 'Cuaca panas. Siram tanaman lebih sering.';
    }
    return 'Cuaca mendukung untuk panen dan pengiriman.';
  }
}
