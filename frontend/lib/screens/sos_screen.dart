import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // <-- TAMBAHAN UNTUK MEMPERBAIKI ERROR
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'sos_status_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  static const Duration _holdDuration = Duration(seconds: 3);
  static const double _cancelSlop = 40; // geser > 40px = batal

  late AnimationController _pulseController;
  late AnimationController _holdController;

  bool _holding = false;
  bool _triggered = false;
  Offset? _downPosition;

  String _namaUser = 'Warga';

  // GPS: null = sedang mencari, true = aktif, false = mati/ditolak
  bool? _gpsAktif;
  String? _koordinat;

  final Color primaryGreen = const Color(0xFF006130);
  final Color bgColor = const Color(0xFFE8FFF0);
  final Color errorRed = const Color(0xFFBA1A1A);
  final Color textDark = const Color(0xFF131B2E);

  @override
  void initState() {
    super.initState();

    // Animasi Pulse (Lingkaran Berdenyut)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Animasi Hold (Tahan 3 Detik). SOS dipicu dari status controller ini
    // sendiri, tanpa Timer terpisah, supaya tidak ada selisih waktu.
    _holdController = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _triggerSOS();
        }
      });

    _loadUser();
    _loadLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  // ── Data user & lokasi ────────────────────────────────────────────────
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _namaUser = prefs.getString('nama') ?? 'Warga');
  }

  Future<void> _loadLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) setState(() => _gpsAktif = false);
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _gpsAktif = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 10),
      );
      if (!mounted) return;
      setState(() {
        _gpsAktif = true;
        _koordinat =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      });
    } catch (_) {
      if (mounted) setState(() => _gpsAktif = false);
    }
  }

  // ── Logika tombol tahan 3 detik ───────────────────────────────────────
  void _startHold(PointerDownEvent e) {
    if (_triggered || _holding) return;
    // Mouse: hanya klik kiri
    if (e.kind == PointerDeviceKind.mouse && e.buttons != kPrimaryMouseButton) {
      return;
    }
    _holding = true;
    _downPosition = e.position;
    HapticFeedback.lightImpact();
    _holdController.forward(from: _holdController.value);
  }

  void _moveHold(PointerMoveEvent e) {
    if (!_holding || _downPosition == null) return;
    if ((e.position - _downPosition!).distance > _cancelSlop) {
      _cancelHold();
    }
  }

  void _cancelHold() {
    if (!_holding) return;
    _holding = false;
    _downPosition = null;
    if (!_triggered) {
      _holdController.animateBack(
        0,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Future<void> _triggerSOS() async {
    if (_triggered || !mounted) return;
    _triggered = true;
    _holding = false;
    _downPosition = null;
    HapticFeedback.heavyImpact();
    _holdController.reset();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SosStatusScreen()),
    );

    // Kembali dari layar status: siap dipakai lagi
    if (!mounted) return;
    _triggered = false;
    _holdController.reset();
  }

  // ── Panggilan telepon ─────────────────────────────────────────────────
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _panggil(String nomor) async {
    // Di Chrome desktop tidak ada aplikasi telepon: salin nomor ke clipboard
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: nomor));
      _snack('Nomor $nomor disalin (panggilan langsung hanya di HP)');
    }
    try {
      final ok = await launchUrl(Uri(scheme: 'tel', path: nomor));
      if (!ok && !kIsWeb) _snack('Tidak dapat melakukan panggilan');
    } catch (_) {
      if (!kIsWeb) _snack('Tidak dapat melakukan panggilan');
    }
  }

  Future<void> _konfirmasiPanggil(String petugas, String? nomor) async {
    if (nomor == null) {
      _snack('Nomor $petugas belum diatur');
      return;
    }
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Hubungi $petugas?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(nomor, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hubungi', style: TextStyle(color: errorRed)),
          ),
        ],
      ),
    );
    if (ya == true) _panggil(nomor);
  }

  // ── UI ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final gpsColor = _gpsAktif == false ? errorRed : primaryGreen;
    final gpsLabel = _gpsAktif == null
        ? 'Mencari...'
        : (_gpsAktif! ? 'GPS Aktif' : 'GPS Mati');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tombol Siaga Darurat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'RT 05 / RW 08 • SAPULIDI',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.person), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Peringatan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorRed.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: errorRed),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: errorRed,
                    child: const Icon(Icons.warning, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SIAGA LINGKUNGAN 24 JAM',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: errorRed,
                          ),
                        ),
                        Text(
                          'Pusat Bantuan & Tanggap Darurat Warga',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        Text(
                          'RT 05 / RW 08 Menteng Asri siap merespon cepat kondisi darurat Anda.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // GPS Terverifikasi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.gps_fixed, color: gpsColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KOORDINAT TERVERIFIKASI',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              Text(
                                _koordinat ?? 'Blok B3 No. 12, Menteng Asri',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ID Warga: #RT05-8821 • $_namaUser',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: gpsColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gpsLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: gpsColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // TOMBOL SOS DENGAN ANIMASI
            Center(
              child: Column(
                children: [
                  Text(
                    '⚠️ Pemicu Siaga Langsung',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: errorRed,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Ukuran tetap 240x240 agar layout tidak bergetar saat pulse
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animasi Pulse (tidak menerima sentuhan)
                        IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final v = _pulseController.value;
                              return Container(
                                width: 180 + (v * 60),
                                height: 180 + (v * 60),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: errorRed.withAlpha(
                                    ((1 - v) * 100).toInt(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Tombol Utama: Listener = event pointer mentah,
                        // stabil di Web & Mobile (tidak ikut gesture arena)
                        Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: _startHold,
                          onPointerMove: _moveHold,
                          onPointerUp: (_) => _cancelHold(),
                          onPointerCancel: (_) => _cancelHold(),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: errorRed,
                                  boxShadow: [
                                    BoxShadow(
                                      color: errorRed.withAlpha(100),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.wifi_tethering,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                      Text(
                                        'SOS',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'TEKAN 3 DETIK',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Cincin progres tahanan (muncul saat ditahan)
                              IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _holdController,
                                  builder: (context, child) {
                                    if (_holdController.value == 0) {
                                      return const SizedBox(
                                        width: 180,
                                        height: 180,
                                      );
                                    }
                                    return SizedBox(
                                      width: 180,
                                      height: 180,
                                      child: CircularProgressIndicator(
                                        value: _holdController.value,
                                        strokeWidth: 6,
                                        color: Colors.white,
                                        backgroundColor: Colors.white24,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tahan tombol selama 3 detik',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Sirine Pos Kamling RT 05 otomatis berbunyi & notifikasi prioritas dikirim.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Kategori Bantuan
            Text(
              'Pilih Kategori Bantuan Spesifik',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: [
                _buildKategoriCard(
                  'Pos Ronda',
                  'Pencerian & Kamtib',
                  Icons.security,
                  primaryGreen,
                  petugas: 'Pos Kamling RT 05',
                  nomor: '081234567890',
                ),
                _buildKategoriCard(
                  'Damkar & Warga',
                  'Kebakaran / Gas',
                  Icons.local_fire_department,
                  errorRed,
                  petugas: 'Damkar Pos Menteng Asri',
                  nomor: '113',
                ),
                _buildKategoriCard(
                  'Ambulans RW',
                  'Darurat Medis',
                  Icons.local_hospital,
                  Colors.blue,
                  petugas: 'Ambulans RW 08',
                  nomor: '081298765432',
                ),
                _buildKategoriCard(
                  'Tim Reaksi',
                  'Pohon & Bencana',
                  Icons.forest,
                  Colors.orange,
                  petugas: 'Tim Reaksi',
                  nomor: null, // TODO: isi nomor Tim Reaksi
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Panggilan Langsung
            Text(
              'Panggilan Langsung Petugas',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCallTile(
              'Pos Kamling RT 05 (Pak Joko)',
              'Siaga Ronda Malam • Radio Ch. 05',
              '081234567890',
              primaryGreen,
            ),
            _buildCallTile(
              'Ambulans Gratis RW 08',
              'Driver: Mas Dimas • Standby Kantor RW',
              '081298765432',
              Colors.blue,
            ),
            _buildCallTile(
              'Babinkamtibmas Kelurahan',
              'Aiptu Hendro Gunawan',
              '081311223344',
              Colors.grey,
            ),
            _buildCallTile(
              'Damkar Pos Menteng Asri',
              'Pos Sektor 2 • Jarak 1.2 Km',
              '113',
              errorRed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriCard(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    required String petugas,
    required String? nomor,
  }) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _konfirmasiPanggil(petugas, nomor),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallTile(
    String title,
    String subtitle,
    String phone,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(30),
            child: Icon(Icons.phone, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.call, color: color),
            onPressed: () => _panggil(phone),
          ),
        ],
      ),
    );
  }
}
