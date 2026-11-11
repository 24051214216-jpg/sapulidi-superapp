import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'detail_event_screen.dart';
import 'keuangan_screen.dart';
import 'login_screen.dart';
import 'news_screen.dart';

// Warna persis dari tailwind.config di HTML desain
class _C {
  static const surface = Color(0xFFFAF8FF);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFEAEDFF);
  static const surfaceContainerHigh = Color(0xFFE2E7FF);
  static const surfaceVariant = Color(0xFFDAE2FD);
  static const primary = Color(0xFF006130);
  static const primaryContainer = Color(0xFF107C41);
  static const primaryDark = Color(0xFF084C27);
  static const primaryFixed = Color(0xFF96F7AF);
  static const onPrimaryContainer = Color(0xFFB6FFC5);
  static const onPrimaryFixedVariant = Color(0xFF005228);
  static const tertiary = Color(0xFF005988);
  static const tertiaryContainer = Color(0xFF0072AD);
  static const onSurface = Color(0xFF131B2E);
  static const onSurfaceVariant = Color(0xFF3F4940);
  static const outline = Color(0xFF6F7A6F);
  static const outlineVariant = Color(0xFFBECABD);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
}

TextStyle _jk(
  double size,
  FontWeight weight,
  Color color, {
  double? ls,
  double? h,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: ls,
  height: h,
);

const _cardShadow = [
  BoxShadow(color: Color(0x0D0F172A), blurRadius: 12, offset: Offset(0, 4)),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const int _maxNews = 3;
  // TODO: ganti dengan jumlah notifikasi asli bila sudah ada API-nya
  static const int _notifCount = 3;

  int _tab = 0;
  String _namaUser = 'Warga';

  List<dynamic> _events = [];
  List<dynamic> _news = [];
  bool _loadingEvents = true;
  bool _loadingNews = true;
  String? _eventError;
  String? _newsError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _namaUser = prefs.getString('nama') ?? 'Warga');
    }

    setState(() {
      _loadingEvents = true;
      _loadingNews = true;
      _eventError = null;
      _newsError = null;
    });

    await Future.wait([
      ApiService.getEvents()
          .then((v) {
            if (!mounted) return;
            setState(() {
              _events = v;
              _loadingEvents = false;
            });
          })
          .catchError((e) {
            if (!mounted) return;
            setState(() {
              _eventError = e.toString().replaceFirst('Exception: ', '');
              _loadingEvents = false;
            });
          }),
      ApiService.getNews()
          .then((v) {
            if (!mounted) return;
            setState(() {
              _news = v;
              _loadingNews = false;
            });
          })
          .catchError((e) {
            if (!mounted) return;
            setState(() {
              _newsError = e.toString().replaceFirst('Exception: ', '');
              _loadingNews = false;
            });
          }),
    ]);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goTab(int i) => setState(() => _tab = i);

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Helpers data ──────────────────────────────────────────────────────
  String _pick(dynamic m, List<String> keys, [String fallback = '']) {
    if (m is! Map) return fallback;
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return fallback;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  /// Agenda terdekat: event pertama yang belum lewat, kalau tidak ada ambil
  /// event terbaru.
  dynamic get _nearestEvent {
    if (_events.isEmpty) return null;
    final now = DateTime.now();
    final sorted = [..._events]
      ..sort((a, b) {
        final da = _parseDate(a['mulaiAt']) ?? DateTime(2100);
        final db = _parseDate(b['mulaiAt']) ?? DateTime(2100);
        return da.compareTo(db);
      });
    for (final e in sorted) {
      final d = _parseDate(e['mulaiAt']);
      if (d != null && d.isAfter(now.subtract(const Duration(hours: 3)))) {
        return e;
      }
    }
    return sorted.last;
  }

  String _formatEventDate(DateTime? d) {
    if (d == null) return '-';
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final jam = d.hour.toString().padLeft(2, '0');
    final menit = d.minute.toString().padLeft(2, '0');
    return '${hari[d.weekday - 1]}, ${d.day} ${bulan[d.month - 1]} • $jam:$menit WIB';
  }

  String _relativeTime(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff <= 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    if (diff < 7) return '$diff Hari lalu';
    return '${d.day}/${d.month}/${d.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      body: _buildPage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPage() {
    switch (_tab) {
      case 0:
        return _buildBeranda();
      case 1:
        return const KeuanganScreen(key: ValueKey('tab-keuangan'));
      case 2:
        return const NewsScreen(key: ValueKey('tab-berita'));
      case 3:
        return _buildPlaceholder('Inventaris', Icons.inventory_2_rounded);
      default:
        return _buildProfil();
    }
  }

  // ═════════════════════ TAB 0: BERANDA ═════════════════════
  Widget _buildBeranda() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: RefreshIndicator(
              color: _C.primaryContainer,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    _buildKasCard(),
                    _buildLayananWarga(),
                    _buildAgendaTerdekat(),
                    _buildWartaWarga(),
                    _buildEmergency(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header: logo + "SapuLidi | Beranda" + notif + avatar kecil
  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _C.surface.withAlpha(204),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Ganti dengan Image.asset('assets/images/logo.png', height: 32)
              // bila logo SapuLidi sudah ada di assets.
              const Icon(
                Icons.cleaning_services_rounded,
                color: _C.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'SapuLidi',
                style: _jk(18, FontWeight.w700, _C.primary, ls: -0.18),
              ),
              Container(
                width: 1.5,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: _C.outlineVariant.withAlpha(128),
              ),
              Text(
                'Beranda',
                style: _jk(14, FontWeight.w500, _C.onSurfaceVariant),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: _C.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _C.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Sapaan + foto profil + lokasi + tombol notifikasi berbadge
  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: _C.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/karakter_sapulidi.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          color: _C.primary,
                          size: 30,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _C.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.surfaceLowest, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Halo, $_namaUser!',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _jk(
                                20,
                                FontWeight.w700,
                                _C.onSurface,
                                ls: -0.2,
                                h: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('👋', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: _C.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              // TODO: ganti dengan data RT/RW asli bila ada di profil
                              'RT 05 / RW 08 • Menteng Asri',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _jk(
                                12,
                                FontWeight.w600,
                                _C.onSurfaceVariant,
                                ls: 0.24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _C.surfaceLowest,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: _C.onSurface,
                    size: 24,
                  ),
                ),
              ),
              if (_notifCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    height: 20,
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _C.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$_notifCount',
                      style: _jk(10, FontWeight.w700, Colors.white, ls: 0.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color, double sigma) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  // Kartu kas hijau gradien
  Widget _buildKasCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_C.primary, _C.primaryContainer, _C.primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withAlpha(26),
              blurRadius: 25,
              spreadRadius: -5,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: _blurCircle(144, Colors.white.withAlpha(26), 12),
            ),
            Positioned(
              right: 16,
              bottom: 8,
              child: _blurCircle(112, _C.onPrimaryContainer.withAlpha(26), 20),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_rounded,
                                  size: 15,
                                  color: Colors.white.withAlpha(204),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'TOTAL KAS RT 05',
                                  style: _jk(
                                    10,
                                    FontWeight.w700,
                                    Colors.white.withAlpha(204),
                                    ls: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // TODO: ganti dengan saldo CashLedger asli bila ada endpoint-nya
                            Text(
                              'Rp 24.850.000',
                              style: _jk(
                                26,
                                FontWeight.w800,
                                Colors.white,
                                ls: -0.52,
                                h: 1.31,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _C.onPrimaryContainer.withAlpha(51),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              size: 14,
                              color: _C.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+8.5%',
                              style: _jk(
                                10,
                                FontWeight.w600,
                                _C.onPrimaryContainer,
                                ls: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _kasSubBox(
                          'Iuran Warga (Nov)',
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: _C.primaryFixed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Lunas',
                                style: _jk(
                                  14,
                                  FontWeight.w700,
                                  Colors.white,
                                  ls: 0.14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: _C.onPrimaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _kasSubBox(
                          'Agenda Lingkungan',
                          Row(
                            children: [
                              const Icon(
                                Icons.event_note_rounded,
                                size: 18,
                                color: _C.primaryFixed,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _loadingEvents
                                    ? '...'
                                    : '${_events.length} Kegiatan',
                                style: _jk(
                                  14,
                                  FontWeight.w700,
                                  Colors.white,
                                  ls: 0.14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _C.primaryFixed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Audit terbuka per 15 Nov',
                            style: _jk(
                              10,
                              FontWeight.w700,
                              Colors.white.withAlpha(230),
                              ls: 0.5,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _goTab(1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _C.surfaceLowest,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lihat Laporan',
                                style: _jk(
                                  12,
                                  FontWeight.w700,
                                  _C.primary,
                                  ls: 0.24,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: _C.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kasSubBox(String label, Widget child) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _jk(
              10,
              FontWeight.w700,
              Colors.white.withAlpha(204),
              ls: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  // Layanan Warga (4 ikon bulat)
  Widget _buildLayananWarga() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Layanan Warga',
                style: _jk(18, FontWeight.w700, _C.onSurface, h: 1.33),
              ),
              Text(
                'Semua Menu',
                style: _jk(12, FontWeight.w600, _C.primary, ls: 0.24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _quickAction(
                'Keuangan',
                Icons.account_balance_wallet_rounded,
                _C.primaryContainer.withAlpha(38),
                _C.primaryContainer,
                () => _goTab(1),
              ),
              _quickAction(
                'Berita RT',
                Icons.campaign_rounded,
                _C.tertiaryContainer.withAlpha(38),
                _C.tertiaryContainer,
                () => _goTab(2),
              ),
              _quickAction(
                'Inventaris',
                Icons.construction_rounded,
                _C.primaryContainer.withAlpha(38),
                _C.primaryContainer,
                () => _goTab(3),
              ),
              _quickAction(
                'E-Surat',
                Icons.mark_email_read_rounded,
                _C.surfaceVariant,
                _C.onSurface,
                () => _snack('Fitur E-Surat segera hadir'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    String label,
    IconData icon,
    Color bg,
    Color fg,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _C.surfaceLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _cardShadow,
                ),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 24, color: fg),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: _jk(12, FontWeight.w500, _C.onSurface, ls: 0.24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Agenda Terdekat (data dari ApiService.getEvents)
  Widget _buildAgendaTerdekat() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: _C.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Agenda Terdekat',
                    style: _jk(18, FontWeight.w700, _C.onSurface, h: 1.33),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.primaryFixed.withAlpha(153),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'WAJIB HADIR',
                  style: _jk(
                    10,
                    FontWeight.w700,
                    _C.onPrimaryFixedVariant,
                    ls: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _C.surfaceLowest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _cardShadow,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -32,
                  bottom: -32,
                  child: _blurCircle(176, _C.primaryFixed.withAlpha(77), 20),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildAgendaContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaContent() {
    if (_loadingEvents) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: _C.primaryContainer),
        ),
      );
    }
    if (_eventError != null) {
      return _inlineMessage(_eventError!, onRetry: _loadData);
    }
    final event = _nearestEvent;
    if (event == null) {
      return _inlineMessage('Belum ada agenda kegiatan.');
    }

    final judul = _pick(event, ['judul', 'title'], 'Kegiatan RT');
    final lokasi = _pick(event, [
      'lokasi',
      'tempat',
      'lokasiNama',
      'alamat',
    ], '-');
    final tanggal = _formatEventDate(_parseDate(event['mulaiAt']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _C.primaryFixed.withAlpha(153),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_rounded,
                      size: 16,
                      color: _C.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tanggal,
                        overflow: TextOverflow.ellipsis,
                        style: _jk(
                          12,
                          FontWeight.w600,
                          _C.onPrimaryFixedVariant,
                          ls: 0.24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Peralatan dibawa',
              style: _jk(10, FontWeight.w600, _C.outline, ls: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          judul,
          style: _jk(20, FontWeight.w700, _C.onSurface, ls: -0.2, h: 1.25),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.pin_drop_rounded, size: 18, color: _C.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lokasi,
                style: _jk(14, FontWeight.w500, _C.onSurface, h: 1.43),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 32 * 3 - 16.0,
                  height: 32,
                  child: Stack(
                    children: [
                      _avatarDot(0, _C.primaryFixed),
                      _avatarDot(24, _C.surfaceVariant),
                      _avatarDot(48, _C.surfaceContainerHigh),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Bersama Warga',
                  style: _jk(
                    12,
                    FontWeight.w500,
                    _C.onSurfaceVariant,
                    ls: 0.24,
                  ),
                ),
              ],
            ),
            // Membuka detail event (tempat absen kamera + GPS dilakukan)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailEventScreen(eventData: event),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _C.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: _C.primary.withAlpha(26),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Saya Hadir',
                      style: _jk(14, FontWeight.w700, Colors.white, ls: 0.14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _avatarDot(double left, Color color) {
    return Positioned(
      left: left,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: _C.surfaceLowest, width: 2),
        ),
        child: const Icon(Icons.person_rounded, size: 16, color: _C.primary),
      ),
    );
  }

  Widget _inlineMessage(String msg, {VoidCallback? onRetry}) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: _jk(13, FontWeight.w500, _C.onSurfaceVariant),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Coba Lagi',
                style: _jk(13, FontWeight.w700, _C.primary),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Warta Warga (data dari ApiService.getNews)
  Widget _buildWartaWarga() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.newspaper_rounded,
                    size: 20,
                    color: _C.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Warta Warga',
                    style: _jk(18, FontWeight.w700, _C.onSurface, h: 1.33),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _goTab(2),
                child: Row(
                  children: [
                    Text(
                      'Lihat Semua',
                      style: _jk(12, FontWeight.w600, _C.primary, ls: 0.24),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: _C.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingNews)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: _C.primaryContainer),
              ),
            )
          else if (_newsError != null)
            _inlineMessage(_newsError!, onRetry: _loadData)
          else if (_news.isEmpty)
            _inlineMessage('Belum ada berita.')
          else
            ..._news.take(_maxNews).map(_buildNewsCard),
        ],
      ),
    );
  }

  Widget _buildNewsCard(dynamic item) {
    final judul = _pick(item, ['judul', 'title'], 'Tanpa judul');
    final kategori = _pick(item, ['kategori', 'category'], 'Info');
    final penulis = _pick(item, [
      'penulis',
      'author',
      'pembuat',
    ], 'Pengurus RT');
    final waktu = _relativeTime(
      _parseDate(item['createdAt'] ?? item['tanggal']),
    );

    final isKeamanan = kategori.toLowerCase().contains('aman');
    final chipBg = isKeamanan
        ? _C.surfaceContainerHigh
        : _C.primaryFixed.withAlpha(153);
    final chipFg = isKeamanan ? _C.tertiary : _C.onPrimaryFixedVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _C.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: _C.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            // Belum ada URL gambar berita dari API, jadi pakai ikon.
            child: const Icon(
              Icons.article_rounded,
              size: 36,
              color: _C.primaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 96,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              kategori,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _jk(10, FontWeight.w600, chipFg, ls: 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          waktu,
                          style: _jk(12, FontWeight.w400, _C.outline, h: 1.33),
                        ),
                      ],
                    ),
                    Text(
                      judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _jk(15, FontWeight.w700, _C.onSurface, h: 1.3),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: _C.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            penulis,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _jk(
                              10,
                              FontWeight.w700,
                              _C.onSurfaceVariant,
                              ls: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kartu Siaga Darurat
  Widget _buildEmergency() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.errorContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: _C.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emergency_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tombol Siaga Darurat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _jk(
                            18,
                            FontWeight.w700,
                            _C.onErrorContainer,
                            h: 1.33,
                          ),
                        ),
                        Text(
                          'Pos Satpam & Ambulans RW 08',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _jk(
                            12,
                            FontWeight.w400,
                            _C.onErrorContainer.withAlpha(204),
                            h: 1.33,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              // TODO: hubungkan ke nomor pos satpam (url_launcher: tel:)
              onTap: () => _snack('Nomor darurat belum diatur'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _C.error,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Hubungi',
                  style: _jk(10, FontWeight.w700, Colors.white, ls: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════ TAB 3 & 4: Placeholder / Profil ═════════════════
  Widget _buildPlaceholder(String title, IconData icon) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: _C.primaryContainer),
            const SizedBox(height: 12),
            Text(title, style: _jk(20, FontWeight.w700, _C.onSurface)),
            const SizedBox(height: 4),
            Text(
              'Halaman ini segera hadir',
              style: _jk(13, FontWeight.w500, _C.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfil() {
    return SafeArea(
      bottom: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: _C.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/karakter_sapulidi.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: _C.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(_namaUser, style: _jk(20, FontWeight.w700, _C.onSurface)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'Keluar',
                style: _jk(14, FontWeight.w700, Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════ Bottom Navigation ═════════════════════
  Widget _buildBottomNav() {
    const items = [
      (Icons.home_rounded, 'Beranda'),
      (Icons.account_balance_wallet_rounded, 'Keuangan'),
      (Icons.newspaper_rounded, 'Berita'),
      (Icons.inventory_2_rounded, 'Inventaris'),
      (Icons.person_rounded, 'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _C.surfaceLowest.withAlpha(230),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == _tab;
              final color = active ? _C.primaryContainer : _C.onSurfaceVariant;
              return GestureDetector(
                onTap: () => _goTab(i),
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 56,
                    minHeight: 44,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(items[i].$1, size: 24, color: color),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$2,
                          style: _jk(
                            10,
                            active ? FontWeight.w700 : FontWeight.w600,
                            color,
                            ls: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
