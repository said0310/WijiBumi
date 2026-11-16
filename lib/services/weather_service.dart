import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_info.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  // Static method (Modul 5): dipanggil WeatherService.getCurrentWeather(...)
  static Future<WeatherInfo> getCurrentWeather(double lat, double lng) async {
    final uri = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lng'
      '&current=temperature_2m,relative_humidity_2m,precipitation,'
      'weather_code,wind_speed_10m'
      '&timezone=Asia%2FJakarta',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body); // JSON -> Map
      return WeatherInfo.fromJson(data);
    } else {
      throw Exception('Gagal memuat cuaca (${response.statusCode})');
    }
  }
}
