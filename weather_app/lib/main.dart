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


