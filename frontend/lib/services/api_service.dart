import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL Dinamis (Web, Emulator, HP Fisik)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (Platform.isAndroid) {
      // Jika pakai Emulator Android, gunakan 10.0.2.2
      // Jika pakai HP Fisik, GANTI dengan IP LAN Laptop (misal: 192.168.1.10:3000/api)
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api'; // iOS
    }
  }

  // --- 1. LOGIN ---
  static Future<Map<String, dynamic>> login(
    String noHp,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'noHp': noHp, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('nama', data['user']['nama']);
        await prefs.setString('role', data['user']['role']);
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal: $e'};
    }
  }

  // --- 2. GET EVENTS ---
  static Future<List<dynamic>> getEvents() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Gagal memuat data event');
      }
    } catch (e) {
      throw Exception('Koneksi gagal: $e');
    }
  }

  // --- 3. UPLOAD FOTO ---
  static Future<String?> uploadFoto(dynamic file) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.headers['Authorization'] =
          'Bearer $token'; // Tambahkan token ke header upload

      if (kIsWeb) {
        var bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('foto', bytes, filename: 'selfie.png'),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            file.path,
            filename: 'selfie.png',
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url']; // Path relatif: /uploads/...
      }
      return null;
    } catch (e) {
      debugPrint("Error upload: $e");
      return null;
    }
  }

  // --- 4. ABSEN (DENGAN ISMOCK) ---
  static Future<Map<String, dynamic>> absenKerjaBakti(
    String eventId,
    double lat,
    double lng,
    String fotoUrl,
    bool isMock, // Parameter baru
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/attendance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'eventId': eventId,
          'lat': lat,
          'lng': lng,
          'fotoPath': fotoUrl,
          'isMock': isMock, // Kirim status asli
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // --- 5. GET NEWS ---
  static Future<List<dynamic>> getNews() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/news'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Gagal memuat berita');
      }
    } catch (e) {
      throw Exception('Koneksi gagal: $e');
    }
  }
}
