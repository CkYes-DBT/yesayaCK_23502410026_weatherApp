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


