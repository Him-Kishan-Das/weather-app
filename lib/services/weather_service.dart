import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/weather.dart';

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
}