import 'dart:ui';
import 'package:flutter/material.dart';
import '../model/forecast_item.dart';

class ForecastScreen extends StatefulWidget {
  final String cityName;
  final List<ForecastItem> forecast;
  final List<Color> backgroundGradient;
  final Color primaryOrb;
  final Color secondaryOrb;
  final bool isCelsius;

  const ForecastScreen({
    super.key,
    required this.cityName,
    required this.forecast,
    this.backgroundGradient = const [
      Color(0xFF0F172A),
      Color(0xFF1E293B),
      Color(0xFF0D2538),
    ],
    this.primaryOrb = Colors.cyanAccent,
    this.secondaryOrb = Colors.purpleAccent,
    this.isCelsius = true,
  });

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  late bool _isCelsius;

  @override
  void initState() {
    super.initState();
    _isCelsius = widget.isCelsius;
  }

  IconData _getWeatherIcon(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('rain') || d.contains('drizzle')) return Icons.water_drop;
    if (d.contains('thunder') || d.contains('storm')) return Icons.bolt;
    if (d.contains('snow')) return Icons.ac_unit;
    if (d.contains('cloud')) return Icons.cloud_outlined;
    if (d.contains('clear')) return Icons.wb_sunny_rounded;
    return Icons.wb_cloudy_rounded;
  }

  Color _getWeatherIconColor(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('rain') || d.contains('drizzle')) return Colors.lightBlueAccent;
    if (d.contains('thunder') || d.contains('storm')) return Colors.amberAccent;
    if (d.contains('snow')) return Colors.cyanAccent;
    if (d.contains('clear')) return Colors.orangeAccent;
    return Colors.amber.shade200;
  }

  double _toDisplayTemp(double celsius) {
    return _isCelsius ? celsius : (celsius * 9 / 5) + 32;
  }

  String get _tempUnit => _isCelsius ? '°C' : '°F';

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dt.year, dt.month, dt.day);

    final difference = targetDate.difference(today).inDays;
    String dayLabel;
    if (difference == 0) {
      dayLabel = 'Today';
    } else if (difference == 1) {
      dayLabel = 'Tomorrow';
    } else {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dayLabel = weekdays[dt.weekday - 1];
    }

    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$dayLabel, $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Hourly Forecast',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
            Text(
              widget.cityName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Celsius / Fahrenheit Toggle Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.white.withOpacity(0.14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      _isCelsius = !_isCelsius;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '°C',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                _isCelsius ? FontWeight.bold : FontWeight.normal,
                            color: _isCelsius ? Colors.white : Colors.white54,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            '|',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                        ),
                        Text(
                          '°F',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                !_isCelsius ? FontWeight.bold : FontWeight.normal,
                            color: !_isCelsius ? Colors.white : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.backgroundGradient,
              ),
            ),
          ),

          // Ambient Glowing Orbs for Refraction
          Positioned(
            top: 60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.primaryOrb.withOpacity(0.35),
                    widget.primaryOrb.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -30,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.secondaryOrb.withOpacity(0.3),
                    widget.secondaryOrb.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Forecast List Content
          SafeArea(
            child: widget.forecast.isEmpty
                ? const Center(
                    child: Text(
                      'No forecast data available',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    itemCount: widget.forecast.length,
                    itemBuilder: (context, index) {
                      final item = widget.forecast[index];
                      final icon = _getWeatherIcon(item.description);
                      final iconColor = _getWeatherIconColor(item.description);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18.0,
                                vertical: 16.0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.18),
                                    Colors.white.withOpacity(0.06),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.28),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Time and Day
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatDateTime(item.dateTime),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description.toUpperCase(),
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.65),
                                            fontSize: 12,
                                            letterSpacing: 1.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Weather Icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: iconColor,
                                      size: 28,
                                    ),
                                  ),

                                  const SizedBox(width: 18),

                                  // Temperature (Tappable to toggle °C / °F)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isCelsius = !_isCelsius;
                                      });
                                    },
                                    child: Text(
                                      '${_toDisplayTemp(item.temperature).round()}$_tempUnit',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
