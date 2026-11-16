import 'package:flutter/material.dart';

import '../models/weather_info.dart';
import '../services/weather_service.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  static const List<Map<String, dynamic>> _sites = [
    {'name': 'Lembang', 'lat': -6.8118, 'lng': 107.6177},
    {'name': 'Batu, Malang', 'lat': -7.8672, 'lng': 112.5239},
    {'name': 'Bogor', 'lat': -6.5971, 'lng': 106.8060},
  ];

  int _selected = 0;
  WeatherInfo? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather(); // fetch saat halaman dibuka
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final site = _sites[_selected];
      final result = await WeatherService.getCurrentWeather(
        site['lat'] as double,
        site['lng'] as double,
      );
      if (!mounted) return;
      setState(() {
        _weather = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak bisa memuat cuaca. Periksa koneksi internet.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cuaca Kebun',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownButton<int>(
                  value: _selected,
                  underline: const SizedBox.shrink(),
                  items: List.generate(
                    _sites.length,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(_sites[i]['name'] as String),
                    ),
                  ),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _selected = val);
                    _fetchWeather();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Conditional rendering: loading / error / data
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null) ...[
              Text(_error!, style: TextStyle(color: scheme.error)),
              TextButton(
                onPressed: _fetchWeather,
                child: const Text('Coba lagi'),
              ),
            ] else if (_weather != null) ...[
              Row(
                children: [
                  Icon(_weather!.icon, size: 40, color: scheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    '${_weather!.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_weather!.description),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Kelembapan ${_weather!.humidity}%  •  '
                'Angin ${_weather!.windSpeed.toStringAsFixed(0)} km/j  •  '
                'Hujan ${_weather!.precipitation} mm',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                _weather!.farmingTip,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
