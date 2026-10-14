import 'dart:ui';
import 'package:flutter/material.dart';
import '../model/weather.dart';
import '../services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import '../model/forecast_item.dart';
import 'forecast_screen.dart';

class WeatherThemeColors {
  final List<Color> backgroundGradient;
  final Color primaryOrb;
  final Color secondaryOrb;
  final Color tertiaryOrb;
  final Color accentGlow;
  final Color iconColor;
  final String temperatureStatus;

  const WeatherThemeColors({
    required this.backgroundGradient,
    required this.primaryOrb,
    required this.secondaryOrb,
    required this.tertiaryOrb,
    required this.accentGlow,
    required this.iconColor,
    required this.temperatureStatus,
  });
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
  
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _cityController =
      TextEditingController(text: 'Guwahati');
  final WeatherService _weatherService = WeatherService();
  List<ForecastItem> _forecast = [];

  Weather? _weather;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isCelsius = true;
  List<String> _suggestions = [];

  static const List<String> _popularCities = [
    'Guwahati', 'Mumbai', 'Delhi', 'Bengaluru', 'Kolkata', 'Chennai', 'Hyderabad',
    'London', 'New York', 'Tokyo', 'Paris', 'Dubai', 'Singapore', 'Sydney',
    'Toronto', 'Berlin', 'Rome', 'Amsterdam', 'Chicago', 'San Francisco',
    'Seoul', 'Bangkok', 'Madrid', 'Hong Kong', 'Vienna', 'Dublin', 'Zurich'
  ];

  double _toDisplayTemp(double celsius) {
    return _isCelsius ? celsius : (celsius * 9 / 5) + 32;
  }

  String get _tempUnit => _isCelsius ? '°C' : '°F';

  void _onSearchChanged(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      if (_suggestions.isNotEmpty) {
        setState(() {
          _suggestions = [];
        });
      }
      return;
    }

    final localMatches = _popularCities
        .where((c) => c.toLowerCase().contains(trimmed.toLowerCase()))
        .toList();

    setState(() {
      _suggestions = localMatches;
    });

    try {
      final apiMatches = await _weatherService.fetchCitySuggestions(trimmed);
      if (mounted && _cityController.text.trim() == trimmed) {
        final combined = {...localMatches, ...apiMatches}.toList();
        setState(() {
          _suggestions = combined.take(5).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    // Automatically fetch weather for current GPS location on start
    _getWeatherByCurrentLocation();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  // Get current device position and fetch weather
  Future<void> _getWeatherByCurrentLocation() async {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS.';
      }

      // 2. Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      // 3. Get current coordinates
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // 4. Call service with lat/lon
      final weatherData = await _weatherService.fetchWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );
      final forecastData = await _weatherService.fetchForecastByCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _weather = weatherData;
        _forecast = forecastData; // Save forecast data
        _cityController.text = weatherData.cityName; // Sync search bar text
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _weather = null;
        _forecast = [];
      });
    }
  }

  Future<void> _getWeather() async {
    final cityName = _cityController.text.trim();
    if (cityName.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _suggestions = [];
    });

    try {
      final weatherData = await _weatherService.fetchWeather(cityName);
      final forecastData = await _weatherService.fetchForecast(cityName);

      setState(() {
        _weather = weatherData;
        _forecast = forecastData; // Save forecast data
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Could not find weather for "$cityName". Please check the city name.';
        _isLoading = false;
        _weather = null;
        _forecast = [];
      });
    }
  }

  WeatherThemeColors _getThemeColors() {
    if (_weather == null) {
      // Default sleek midnight glass palette
      return const WeatherThemeColors(
        backgroundGradient: [
          Color(0xFF0F172A),
          Color(0xFF1E293B),
          Color(0xFF0D2538),
        ],
        primaryOrb: Colors.cyanAccent,
        secondaryOrb: Colors.purpleAccent,
        tertiaryOrb: Colors.blueAccent,
        accentGlow: Colors.cyanAccent,
        iconColor: Colors.amberAccent,
        temperatureStatus: 'Loading...',
      );
    }

    final double temp = _weather!.temperature;
    final String desc = _weather!.description.toLowerCase();

    // 1. Severe Weather Overrides (Storm, Rain, Snow)
    if (desc.contains('thunder') || desc.contains('storm')) {
      return const WeatherThemeColors(
        backgroundGradient: [
          Color(0xFF120A2A),
          Color(0xFF221147),
          Color(0xFF0A051A),
        ],
        primaryOrb: Color(0xFF9D4EDD), // Electric violet
        secondaryOrb: Color(0xFFFFD166), // Lightning amber
        tertiaryOrb: Color(0xFF3A0CA3), // Deep thunder navy
        accentGlow: Color(0xFFFFD166),
        iconColor: Colors.amberAccent,
        temperatureStatus: 'Thunderstorm',
      );
    }

    if (desc.contains('snow') || temp <= 0) {
      return const WeatherThemeColors(
        backgroundGradient: [
          Color(0xFF0A192F),
          Color(0xFF1A365D),
          Color(0xFF0F2038),
        ],
        primaryOrb: Color(0xFFE2E8F0), // Frozen white
        secondaryOrb: Color(0xFF38BDF8), // Frost cyan
        tertiaryOrb: Color(0xFF0284C7), // Arctic blue
        accentGlow: Color(0xFF7DD3FC),
        iconColor: Colors.cyanAccent,
        temperatureStatus: 'Freezing',
      );
    }

    if (desc.contains('rain') || desc.contains('drizzle')) {
      return const WeatherThemeColors(
        backgroundGradient: [
          Color(0xFF081C2E),
          Color(0xFF11324D),
          Color(0xFF0E243A),
        ],
        primaryOrb: Color(0xFF38BDF8), // Rain blue
        secondaryOrb: Color(0xFF2DD4BF), // Aqua teal
        tertiaryOrb: Color(0xFF0369A1), // Deep navy
        accentGlow: Color(0xFF38BDF8),
        iconColor: Colors.lightBlueAccent,
        temperatureStatus: 'Rainy',
      );
    }

    // 2. Temperature Driven Gradient & Glow Orbs
    if (temp < 15) {
      // Cold / Chilly
      return const WeatherThemeColors(
        backgroundGradient: [
          Color(0xFF0F2027),
          Color(0xFF1A3644),
          Color(0xFF142B38),
        ],
        primaryOrb: Color(0xFF38BDF8), // Chilly blue
        secondaryOrb: Color(0xFF48CAE4), // Mist cyan
        tertiaryOrb: Color(0xFF0077B6), // Deep cold ocean
        accentGlow: Color(0xFF38BDF8),
        iconColor: Colors.cyanAccent,
        temperatureStatus: 'Cold',
      );
    } else if (temp < 25) {
      // Mild / Pleasant (Room Temperature)
      return const WeatherThemeColors(
        backgroundGradient: [
          Color(0xFF092026),
          Color(0xFF0E383F),
          Color(0xFF0A2830),
        ],
        primaryOrb: Color(0xFF10B981), // Fresh emerald
        secondaryOrb: Color(0xFF06B6D4), // Soft cyan
        tertiaryOrb: Color(0xFF0D9488), // Deep teal
        accentGlow: Color(0xFF34D399),
        iconColor: Color(0xFFFDE047),
        temperatureStatus: 'Pleasant',
      );
    } else if (temp < 32) {
      // Warm / Sunny
      return const WeatherThemeColors(
        backgroundGradient: [
          Color(0xFF2B142F),
          Color(0xFF4A1E3E),
          Color(0xFF38151D),
        ],
        primaryOrb: Color(0xFFF59E0B), // Warm amber sun
        secondaryOrb: Color(0xFFF97316), // Sunset coral
        tertiaryOrb: Color(0xFFE11D48), // Rose dusk
        accentGlow: Color(0xFFF59E0B),
        iconColor: Colors.orangeAccent,
        temperatureStatus: 'Warm',
      );
    } else {
      // Hot / Scorching (>= 32°C)
      return const WeatherThemeColors(
        backgroundGradient: [
          Color(0xFF330B0B),
          Color(0xFF541212),
          Color(0xFF380707),
        ],
        primaryOrb: Color(0xFFEF4444), // Solar crimson
        secondaryOrb: Color(0xFFF97316), // Heatwave orange
        tertiaryOrb: Color(0xFFDC2626), // Lava red
        accentGlow: Color(0xFFEF4444),
        iconColor: Colors.deepOrangeAccent,
        temperatureStatus: 'Very Hot',
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final themeColors = _getThemeColors();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Weather Forecast',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Celsius / Fahrenheit Glossy Toggle Switch
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
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
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: Colors.white),
            tooltip: 'Use Current Location',
            onPressed: _getWeatherByCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Dynamic Atmospheric Gradient Background based on Temperature
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeColors.backgroundGradient,
              ),
            ),
          ),

          // Glowing Ambient Orbs for Glass Refraction Depth
          Positioned(
            top: 70,
            left: -40,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    themeColors.primaryOrb.withOpacity(0.4),
                    themeColors.primaryOrb.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 270,
            right: -50,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    themeColors.secondaryOrb.withOpacity(0.35),
                    themeColors.secondaryOrb.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    themeColors.tertiaryOrb.withOpacity(0.3),
                    themeColors.tertiaryOrb.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Glossy Glass Search Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.28),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _cityController,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          cursorColor: Colors.white,
                          onChanged: _onSearchChanged,
                          onSubmitted: (_) {
                            setState(() {
                              _suggestions = [];
                            });
                            _getWeather();
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter city name...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 15,
                            ),
                            prefixIcon: IconButton(
                              icon: const Icon(
                                Icons.my_location_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Use Current Location',
                              onPressed: _getWeatherByCurrentLocation,
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Material(
                                  color: Colors.white.withOpacity(0.2),
                                  child: InkWell(
                                    onTap: _getWeather,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.search_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // City Autocomplete Suggestions
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.28),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _suggestions.map((city) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        _cityController.text = city;
                                        setState(() {
                                          _suggestions = [];
                                        });
                                        _getWeather();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 12.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_city_rounded,
                                              color: Colors.cyanAccent
                                                  .withOpacity(0.9),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                city,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.north_west_rounded,
                                              color:
                                                  Colors.white.withOpacity(0.4),
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (city != _suggestions.last)
                                    Divider(
                                      height: 1,
                                      thickness: 0.8,
                                      color: Colors.white.withOpacity(0.12),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 36),

                  // Loading State
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 60.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: themeColors.primaryOrb,
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Fetching weather...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )

                  // Error State
                  else if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )

                  // Weather Result Display
                  else if (_weather != null) ...[
                    // Glossy Weather Icon Container with Dynamic Ambient Glow
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: 135,
                          height: 135,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.26),
                                Colors.white.withOpacity(0.08),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: themeColors.accentGlow.withOpacity(0.45),
                                blurRadius: 38,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _getWeatherIcon(_weather!.description),
                              size: 70,
                              color: themeColors.iconColor,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // City Name
                    Text(
                      _weather!.cityName,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.6,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Temperature Display (Tappable to toggle °C / °F)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCelsius = !_isCelsius;
                        });
                      },
                      child: Text(
                        '${_toDisplayTemp(_weather!.temperature).round()}$_tempUnit',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 16,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Weather Condition & Temperature Status Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Description Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                            ),
                          ),
                          child: Text(
                            _weather!.description.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Climate/Comfort Tag Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: themeColors.primaryOrb.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeColors.primaryOrb.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: themeColors.primaryOrb,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                themeColors.temperatureStatus,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 38),

                    // Glossy Glass Metrics Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 22.0,
                            horizontal: 14.0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.20),
                                Colors.white.withOpacity(0.06),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.32),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMetricItem(
                                Icons.thermostat_rounded,
                                'Feels Like',
                                '${_toDisplayTemp(_weather!.feelsLike).round()}$_tempUnit',
                              ),
                              _buildVerticalDivider(),
                              _buildMetricItem(
                                Icons.water_drop_rounded,
                                'Humidity',
                                '${_weather!.humidity}%',
                              ),
                              _buildVerticalDivider(),
                              _buildMetricItem(
                                Icons.air_rounded,
                                'Wind',
                                '${_weather!.windSpeed.toStringAsFixed(1)} km/h',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Dedicated Hourly Forecast Screen Navigation Card
                    if (_forecast.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.18),
                                  Colors.white.withOpacity(0.06),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ForecastScreen(
                                        cityName: _weather!.cityName,
                                        forecast: _forecast,
                                        backgroundGradient:
                                            themeColors.backgroundGradient,
                                        primaryOrb: themeColors.primaryOrb,
                                        secondaryOrb: themeColors.secondaryOrb,
                                        isCelsius: _isCelsius,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18.0,
                                    vertical: 18.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.12),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.25),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.access_time_filled_rounded,
                                          color: Colors.cyanAccent,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Hourly Forecast',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'View 3-hour breakdown on a new screen',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.65),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Colors.white.withOpacity(0.8),
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 25),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 48,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
