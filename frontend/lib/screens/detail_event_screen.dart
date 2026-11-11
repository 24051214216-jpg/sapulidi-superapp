import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../utils/theme.dart';

class DetailEventScreen extends StatefulWidget {
  final Map<String, dynamic> eventData;
  const DetailEventScreen({super.key, required this.eventData});

  @override
  State<DetailEventScreen> createState() => _DetailEventScreenState();
}

class _DetailEventScreenState extends State<DetailEventScreen> {
  XFile? _imageFile;
  Position? _currentPosition;
  bool _isLoading = false;

  Future<void> _prosesAbsen() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'GPS tidak aktif. Nyalakan lokasi HP/PC Anda.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw 'Izin lokasi ditolak.';
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      setState(() => _currentPosition = position);

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null)
        setState(() => _imageFile = photo);
      else
        throw 'Foto tidak diambil.';
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAbsen() async {
    setState(() => _isLoading = true);
    String? fotoUrl = await ApiService.uploadFoto(_imageFile!);

    if (fotoUrl == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal upload foto ke server.')),
        );
      }
      return;
    }

    // MENGIRIM PARAMETER isMocked ASLI DARI GEOLOCATOR
    final result = await ApiService.absenKerjaBakti(
      widget.eventData['id'],
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      fotoUrl,
      _currentPosition!.isMocked, // <--- REVISI: Kirim status Fake GPS
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'])));
      if (result['success']) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Absensi Kegiatan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.bgColor,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.eventData['judul'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 24),

            if (_imageFile == null || _currentPosition == null)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      size: 80,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Silakan ambil selfie beserta titik koordinat Anda sebagai bukti kehadiran.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textGrey, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _prosesAbsen,
                    icon: const Icon(Icons.camera),
                    label: Text(
                      _isLoading ? 'Memproses...' : 'BUKA KAMERA & LOKASI',
                    ),
                  ),
                ],
              ),

            if (_imageFile != null && _currentPosition != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: kIsWeb
                        ? Image.network(
                            _imageFile!.path,
                            height: 350,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_imageFile!.path),
                            height: 350,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.textDark,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.textDark.withAlpha(51),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LOKASI TERVERIFIKASI',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.verified_user,
                          color: AppTheme.primaryGreen,
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitAbsen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                    ),
                    child: Text(_isLoading ? 'MENGIRIM...' : 'KIRIM ABSENSI'),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _imageFile = null;
                      _currentPosition = null;
                    }),
                    child: const Text(
                      'Ulangi Ambil Foto',
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
