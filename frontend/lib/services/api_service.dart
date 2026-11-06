import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // --- 1. FUNGSI LOGIN ---
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

  // --- 2. FUNGSI GET EVENTS ---
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
        throw Exception(
          'Gagal memuat data event (Error: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Koneksi gagal: $e');
    }
  }

  // --- 3. FUNGSI UPLOAD FOTO (SUPPORT WEB & MOBILE) ---
  static Future<String?> uploadFoto(dynamic file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      if (kIsWeb) {
        var bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('foto', bytes, filename: 'selfie.jpg'),
        );
      } else {
        request.files.add(await http.MultipartFile.fromPath('foto', file.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      debugPrint("Error upload: $e");
      return null;
    }
  }

  // --- 4. FUNGSI ABSEN (KIRIM DATA GEOTAGGING) ---
  static Future<Map<String, dynamic>> absenKerjaBakti(
    String eventId,
    double lat,
    double lng,
    String fotoUrl,
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
          'isMock': false,
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
}
