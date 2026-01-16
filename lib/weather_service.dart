import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // 🔑 OpenWeatherMap API Key
  static const String apiKey = '25c64bf2170364d50849221d6438096f'; 
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>?> getWeather() async {
    try {
      // 1. Konum izni kontrolü ve alma
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Konum servisleri kapalı.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Konum izni reddedildi.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Konum izni kalıcı olarak reddedildi.');
      }

      // 2. Güncel konumu al (Timeout ekledik)
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 5));

      String lat = position.latitude.toString();
      String lon = position.longitude.toString();

      // 3. API isteği at
      final url = '$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=tr';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Hava durumu alınamadı (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint("WeatherService Error: $e");
      // Don't return default Istanbul data. Return null so the UI can handle the missing location state.
      return null;
    }
  }
}
