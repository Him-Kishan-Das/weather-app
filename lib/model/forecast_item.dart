class ForecastItem {
  final DateTime dateTime;
  final double temperature;
  final String description;

  ForecastItem({
    required this.dateTime,
    required this.temperature,
    required this.description,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    return ForecastItem(
      dateTime: DateTime.parse(json['dt_txt']),
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
    );
  }
}