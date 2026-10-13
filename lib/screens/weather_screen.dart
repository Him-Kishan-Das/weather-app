import 'package:flutter/material.dart';
import '../model/weather.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _cityController = TextEditingController(text: 'Guwahati');
  final WeatherService _weatherService = WeatherService();

  Weather? _weather;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Fetch weather automatically for default city on start
    _getWeather();
  }

  Future<void> _getWeather() async {
    final cityName = _cityController.text.trim();
    if (cityName.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final weatherData = await _weatherService.fetchWeather(cityName);
      setState(() {
        _weather = weatherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not find weather for "$cityName". Please check the city name.';
        _isLoading = false;
        _weather = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _cityController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _getWeather(),
              decoration: InputDecoration(
                labelText: 'Enter city name',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _getWeather,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Loading / Error / Results Display
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              )
            else if (_weather != null)
                Column(
                  children: [
                    Icon(
                      _weather!.description.contains('rain')
                          ? Icons.grain
                          : Icons.wb_sunny,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _weather!.cityName,
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_weather!.temperature.round()}°C',
                      style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _weather!.description.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}