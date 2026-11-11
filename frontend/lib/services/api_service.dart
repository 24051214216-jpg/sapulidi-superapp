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

  // ==========================================
  // 1. AUTENTIKASI (LOGIN & REGISTER)
  // ==========================================

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

  static Future<Map<String, dynamic>> register(
    String nama,
    String noHp,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nama': nama, 'noHp': noHp, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal: $e'};
    }
  }

  // ==========================================
  // 2. EVENT & KEGIATAN
  // ==========================================

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

  // ==========================================
  // 3. ABSENSI (KAMERA & GPS)
  // ==========================================

  static Future<String?> uploadFoto(dynamic file) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.headers['Authorization'] = 'Bearer $token';

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

  static Future<Map<String, dynamic>> absenKerjaBakti(
    String eventId,
    double lat,
    double lng,
    String fotoUrl,
    bool isMock,
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
          'isMock': isMock,
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

  // ==========================================
  // 4. BERITA & PENGUMUMAN
  // ==========================================

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

  // ==========================================
  // 5. KEUANGAN (TAGIHAN, PEMBAYARAN, KAS)
  // ==========================================

  static Future<List<dynamic>> getInvoices() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/finance/invoices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Gagal memuat tagihan');
      }
    } catch (e) {
      throw Exception('Koneksi gagal: $e');
    }
  }

  static Future<Map<String, dynamic>> createPayment(
    String invoiceId,
    String buktiPath,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/finance/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'invoiceId': invoiceId, 'buktiPath': buktiPath}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Berhasil'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCashLedger() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/finance/cash'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memuat kas RT');
      }
    } catch (e) {
      throw Exception('Koneksi gagal: $e');
    }
  }

  // ==========================================
  // 6. ADMINISTRASI & INVENTARIS
  // ==========================================

  // --- 10. E-SURAT (AJUKAN SURAT) ---
  static Future<Map<String, dynamic>> ajukanSurat(
    String jenisSurat,
    String keperluan,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/admin-warga/letter'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'jenisSurat': jenisSurat, 'keperluan': keperluan}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Surat berhasil diajukan',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengajukan surat',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // --- 11. GET ASSETS (Daftar Alat) ---
  static Future<List<dynamic>> getAssets() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/assets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Gagal memuat data alat');
      }
    } catch (e) {
      throw Exception('Koneksi gagal: $e');
    }
  }

  // --- 12. AJUKAN PEMINJAMAN ALAT ---
  static Future<Map<String, dynamic>> ajukanPeminjamanAlat(
    String assetId,
    String eventId,
    String tglKembali,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/assets/loans'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'assetId': assetId,
          'eventId': eventId,
          'tglKembali': tglKembali,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Peminjaman berhasil',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengajukan peminjaman',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}
