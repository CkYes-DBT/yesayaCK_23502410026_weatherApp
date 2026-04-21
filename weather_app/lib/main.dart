import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const WeatherApp());

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Weather',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'SF Pro Display'),
        home: const WeatherPage(),
      );
}

// Data Model
class WeatherData {
  final String city, country, description, icon, main;
  final double temp, feelsLike, windSpeed;
  final int humidity;

  const WeatherData({
    required this.city, required this.country, required this.description,
    required this.icon, required this.main, required this.temp,
    required this.feelsLike, required this.windSpeed, required this.humidity,
  });

  factory WeatherData.fromJson(Map<String, dynamic> j) => WeatherData(
        city: j['name'], country: j['sys']['country'],
        description: j['weather'][0]['description'],
        icon: j['weather'][0]['icon'],
        main: j['weather'][0]['main'],
        temp: (j['main']['temp'] as num).toDouble(),
        feelsLike: (j['main']['feels_like'] as num).toDouble(),
        windSpeed: (j['wind']['speed'] as num).toDouble(),
        humidity: j['main']['humidity'],
      );
}

// Tema BAckground

class WeatherTheme {
  final List<Color> gradient;
  final Alignment gradientBegin, gradientEnd;
  final Color accent, text, card;
  final String emoji, mood;

  const WeatherTheme({
    required this.gradient,
    this.gradientBegin = Alignment.topCenter,
    this.gradientEnd   = Alignment.bottomCenter,
    required this.accent, required this.text, required this.card,
    required this.emoji, required this.mood,
  });

  static WeatherTheme of(String main, String icon) {
    final night = icon.endsWith('n');
    switch (main) {
      case 'Clear':
        return night
            // Malam: biru pekat → ungu gelap → hitam
            ? const WeatherTheme(
                gradient: [Color(0xFF020416), Color(0xFF0B0B2E), Color(0xFF1C0F3F)],
                gradientBegin: Alignment.topLeft,
                gradientEnd: Alignment.bottomRight,
                accent: Color(0xFFCDB8FF), text: Colors.white,
                card: Color(0x30FFFFFF), emoji: '🌙', mood: 'night')
            // Siang: biru langit → kuning oranye matahari
            : const WeatherTheme(
                gradient: [Color(0xFF1488CC), Color(0xFF2B78E4), Color(0xFFF5A623)],
                gradientBegin: Alignment.topCenter,
                gradientEnd: Alignment.bottomCenter,
                accent: Color(0xFFFFE566), text: Colors.white,
                card: Color(0x30FFFFFF), emoji: '☀️', mood: 'sunny');

      case 'Clouds':
        // Berawan: abu-biru pucat, flat seperti langit tertutup awan
        return const WeatherTheme(
          gradient: [Color(0xFF8EA8B8), Color(0xFF9EB3C2), Color(0xFFBECDD6)],
          accent: Color(0xFFECEFF1), text: Colors.white,
          card: Color(0x30FFFFFF), emoji: '☁️', mood: 'cloudy');

      case 'Rain': case 'Drizzle':
        // Hujan: biru tua, dingin, basah
        return const WeatherTheme(
          gradient: [Color(0xFF1C3144), Color(0xFF2B5876), Color(0xFF4E7E9A)],
          gradientBegin: Alignment.topLeft,
          gradientEnd: Alignment.bottomRight,
          accent: Color(0xFF80D8FF), text: Colors.white,
          card: Color(0x30FFFFFF), emoji: '🌧️', mood: 'rainy');

      case 'Thunderstorm':
        // Badai: hitam gelap ke abu keunguan, dramatis
        return const WeatherTheme(
          gradient: [Color(0xFF0A0A0F), Color(0xFF16162A), Color(0xFF2A1F3D)],
          gradientBegin: Alignment.topCenter,
          gradientEnd: Alignment.bottomCenter,
          accent: Color(0xFFFFEA00), text: Colors.white,
          card: Color(0x40FFFFFF), emoji: '⛈️', mood: 'storm');

      case 'Snow':
        // Salju: putih bersih ke biru es sangat muda
        return const WeatherTheme(
          gradient: [Color(0xFFE8F4FD), Color(0xFFD0E8F5), Color(0xFFB8D8EE)],
          accent: Color(0xFF1E88E5), text: Color(0xFF1A3A5C),
          card: Color(0x40FFFFFF), emoji: '❄️', mood: 'snowy');

      default: // Mist, Fog, Haze
        // Kabut: abu putih kabut, visibilitas rendah
        return const WeatherTheme(
          gradient: [Color(0xFFC9D4DB), Color(0xFFB8C6CE), Color(0xFFA8B8C2)],
          accent: Color(0xFF546E7A), text: Color(0xFF2C3E50),
          card: Color(0x40FFFFFF), emoji: '🌫️', mood: 'misty');
    }
  }
}

// Weather Page
class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with TickerProviderStateMixin {
  static const _apiKey = 'f45c1936387aaad7ac946284d4ee9332';

  WeatherData? _weather;
  bool _loading = false;
  String? _error;
  String _city = 'Jakarta';

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _pulseCtrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat(reverse: true);
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  late final Animation<double> _pulseAnim =
      Tween(begin: 0.93, end: 1.07)
          .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  @override
  void initState() { super.initState(); _fetchWeather(); }

  @override
  void dispose() { _fadeCtrl.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _fetchWeather([String? city]) async {
    final target = city ?? _city;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather'
          '?q=$target&appid=$_apiKey&units=metric'));
      if (res.statusCode == 200) {
        setState(() {
          _weather = WeatherData.fromJson(jsonDecode(res.body));
          _city = target;
          _loading = false;
        });
        _fadeCtrl..reset()..forward();
      } else {
        setState(() { _error = 'City not found'; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = 'No internet connection'; _loading = false; });
    }
  }
 WeatherTheme get _theme => _weather != null
      ? WeatherTheme.of(_weather!.main, _weather!.icon)
      : const WeatherTheme(
          gradient: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF4A90E2)],
          accent: Color(0xFF80D8FF), text: Colors.white,
          card: Color(0x33FFFFFF), emoji: '🌡️', mood: 'default');

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: t.gradientBegin,
            end: t.gradientEnd,
            colors: t.gradient,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? _loader(t)
              : _error != null
                  ? _errorView(t)
                  : _content(t),
        ),
      ),
    );
  }

  Widget _loader(WeatherTheme t) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: t.accent, strokeWidth: 2),
          const SizedBox(height: 16),
          Text('Fetching weather...',
              style: TextStyle(color: t.text.withOpacity(0.7), fontSize: 15)),
        ]),
      );

  Widget _errorView(WeatherTheme t) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('😕', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: t.text, fontSize: 18)),
              const SizedBox(height: 24),
              _SearchBar(theme: t, onSearch: _fetchWeather),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _fetchWeather,
                child: Text('Try Again', style: TextStyle(color: t.accent)),
              ),
            ]),
          ),
        ),
      );

  Widget _content(WeatherTheme t) {
    final w = _weather!;
    return FadeTransition(
      opacity: _fadeAnim,
      child: LayoutBuilder(builder: (ctx, cx) {
        final pad = cx.maxWidth < 420 ? 20.0 : 28.0;
        final cw  = min(cx.maxWidth - pad * 2, 680.0);
        final ch  = max(0.0, cx.maxHeight - 32.0);
        final sc  = min((cw / 390).clamp(0.72, 1.25), (ch / 700).clamp(0.72, 1.20));

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16),
          child: Center(
            child: SizedBox(
              width: cw,
              height: ch,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Search
                  _SearchBar(theme: t, onSearch: _fetchWeather),

                  // Location
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.location_on_rounded, color: t.accent, size: 18 * sc),
                    SizedBox(width: 4 * sc),
                    Flexible(
                      child: Text(
                        '${w.city}, ${w.country}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 20 * sc,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ]),

                  // Emoji
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Text(t.emoji, style: TextStyle(fontSize: 90 * sc)),
                  ),

                  // Description
                  Text(
                    w.description.toUpperCase(),
                    style: TextStyle(
                      color: t.text.withOpacity(0.65),
                      fontSize: 12 * sc,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Temperature
                  Column(children: [
                    Text(
                      '${w.temp.round()}°',
                      style: TextStyle(
                        color: t.text,
                        fontSize: 88 * sc,
                        fontWeight: FontWeight.w200,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 4 * sc),
                    Text(
                      'Feels like ${w.feelsLike.round()}°C',
                      style: TextStyle(
                        color: t.text.withOpacity(0.55),
                        fontSize: 14 * sc,
                      ),
                    ),
                  ]),

                  // Condition tip
                  _ConditionBanner(theme: t, weather: w),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// Search Bar 
class _SearchBar extends StatefulWidget {
  final WeatherTheme theme;
  final void Function(String) onSearch;
  const _SearchBar({required this.theme, required this.onSearch});
  @override State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: t.accent.withOpacity(0.28)),
      ),
      child: TextField(
        controller: _ctrl,
        style: TextStyle(color: t.text),
        textInputAction: TextInputAction.search,
        onSubmitted: (v) { if (v.trim().isNotEmpty) widget.onSearch(v.trim()); },
        decoration: InputDecoration(
          hintText: 'Search city...',
          hintStyle: TextStyle(color: t.text.withOpacity(0.38)),
          prefixIcon: Icon(Icons.search, color: t.accent, size: 20),
          suffixIcon: IconButton(
            icon: Icon(Icons.send_rounded, color: t.accent, size: 18),
            onPressed: () {
              if (_ctrl.text.trim().isNotEmpty) widget.onSearch(_ctrl.text.trim());
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// Condition Banner
class _ConditionBanner extends StatelessWidget {
  final WeatherTheme theme;
  final WeatherData weather;
  const _ConditionBanner({required this.theme, required this.weather});

  String get _msg => switch (weather.main) {
        'Clear'        => '✨ Perfect day to be outside!',
        'Clouds'       => '🌤 Mild and comfortable today.',
        'Rain'         => '☔ Don\'t forget your umbrella!',
        'Drizzle'      => '🌦 Light rain — stay dry!',
        'Thunderstorm' => '⚡ Stay safe and stay inside!',
        'Snow'         => '☃️ Bundle up — it\'s snowing!',
        _              => '🌫 Low visibility — drive carefully.',
      };

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 22),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.accent.withOpacity(0.18)),
        ),
        child: Text(
          _msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.text.withOpacity(0.88),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      );
}