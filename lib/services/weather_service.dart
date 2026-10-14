import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/weather.dart';
import '../model/forecast_item.dart';

class WeatherService {
  final String apiKey = '6c874bcd72c089f26552c0ddf3120f00';

  Future<Weather> fetchWeather(String cityName) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=${Uri.encodeComponent(cityName)}&appid=$apiKey&units=metric');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<Weather> fetchWeatherByCoordinates(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather for current location');
    }
  }

  Future<List<ForecastItem>> fetchForecast(String cityName) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=${Uri.encodeComponent(cityName)}&appid=$apiKey&units=metric');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List list = data['list'];
      return list.map((item) => ForecastItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load forecast data');
    }
  }

  Future<List<ForecastItem>> fetchForecastByCoordinates(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List list = data['list'];
      return list.map((item) => ForecastItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load forecast data');
    }
  }

  Future<List<String>> fetchCitySuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final url = Uri.parse(
        'https://api.openweathermap.org/geo/1.0/direct?q=${Uri.encodeComponent(trimmed)}&limit=5&appid=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final Set<String> results = {};
        for (var item in data) {
          final name = item['name'] as String?;
          final country = item['country'] as String?;
          if (name != null) {
            if (country != null && country.isNotEmpty) {
              results.add('$name, $country');
            } else {
              results.add(name);
            }
          }
        }
        return results.toList();
      }
    } catch (_) {}
    return [];
  }
}