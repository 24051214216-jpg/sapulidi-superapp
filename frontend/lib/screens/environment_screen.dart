import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/theme.dart';

class EnvironmentScreen extends StatelessWidget {
  const EnvironmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildVillageBanner(),
              _buildGaugeSection(),
              _buildStatsRow(),
              _buildObservationCards(),
              _buildWeeklyForecast(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppTheme.textDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Cibadak, RT 03 / RW 07',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.primaryGreen, size: 20),
                  ],
                ),
                Text(
                  'Senin, 7 November 2026',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.primaryGreen.withAlpha(60), width: 2),
            ),
            child: const Icon(Icons.person_rounded,
                color: AppTheme.primaryGreen, size: 22),
          ),
        ],
      ),
    );
  }

  // ─── Village banner (CustomPainter) ───────────────────────────────────────
  Widget _buildVillageBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 140,
          width: double.infinity,
          child: CustomPaint(
            painter: VillageBannerPainter(),
          ),
        ),
      ),
    );
  }

  // ─── Gauge section ────────────────────────────────────────────────────────
  Widget _buildGaugeSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Indeks Kebersihan Lingkungan',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: SemicircleGaugePainter(value: 85, maxValue: 100),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '85',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryGreen,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '✓  Baik',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.textGrey)),
              Text('50',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.textGrey)),
              Text('100',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.textGrey)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Stats row ────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      {
        'label': 'Sampah',
        'value': '92',
        'unit': '%',
        'icon': Icons.delete_outline_rounded,
        'color': const Color(0xFF43A047),
      },
      {
        'label': 'Selokan',
        'value': '78',
        'unit': '%',
        'icon': Icons.water_drop_outlined,
        'color': const Color(0xFF1976D2),
      },
      {
        'label': 'Jalan',
        'value': '88',
        'unit': '%',
        'icon': Icons.add_road_rounded,
        'color': const Color(0xFF795548),
      },
      {
        'label': 'Taman',
        'value': '82',
        'unit': '%',
        'icon': Icons.park_outlined,
        'color': const Color(0xFF00897B),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: stats.map((s) {
          final color = s['color'] as Color;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(s['icon'] as IconData,
                        color: color, size: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${s['value']}${s['unit']}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['label'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.textGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Observation cards ───────────────────────────────────────────────────
  Widget _buildObservationCards() {
    final obs = [
      {
        'title': 'Laporan Aktif',
        'value': '5',
        'sub': 'dalam proses',
        'icon': Icons.flag_rounded,
        'color': const Color(0xFFFF7A00),
      },
      {
        'title': 'Jadwal Kerja Bakti',
        'value': '3',
        'sub': 'bulan ini',
        'icon': Icons.event_rounded,
        'color': const Color(0xFF107C41),
      },
      {
        'title': 'Warga Aktif',
        'value': '147',
        'sub': 'dari 160',
        'icon': Icons.people_rounded,
        'color': const Color(0xFF1565C0),
      },
      {
        'title': 'Petugas Kebersihan',
        'value': '8',
        'sub': 'orang',
        'icon': Icons.engineering_rounded,
        'color': const Color(0xFF6A1B9A),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Observasi Saat Ini',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: obs.map((o) {
              final color = o['color'] as Color;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(o['icon'] as IconData,
                          color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            o['value'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: color,
                              height: 1,
                            ),
                          ),
                          Text(
                            o['sub'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Weekly forecast-style row ────────────────────────────────────────────
  Widget _buildWeeklyForecast() {
    final days = [
      {'day': 'Sen', 'score': 85, 'icon': Icons.wb_sunny_rounded},
      {'day': 'Sel', 'score': 78, 'icon': Icons.cloud_rounded},
      {'day': 'Rab', 'score': 90, 'icon': Icons.wb_sunny_rounded},
      {'day': 'Kam', 'score': 72, 'icon': Icons.grain_rounded},
      {'day': 'Jum', 'score': 88, 'icon': Icons.wb_sunny_rounded},
      {'day': 'Sab', 'score': 95, 'icon': Icons.wb_sunny_rounded},
      {'day': 'Min', 'score': 80, 'icon': Icons.cloud_queue_rounded},
    ];

    Color scoreColor(int s) {
      if (s >= 85) return AppTheme.primaryGreen;
      if (s >= 70) return const Color(0xFFFFC107);
      return Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indeks Mingguan',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((d) {
                final score = d['score'] as int;
                final color = scoreColor(score);
                final isToday = d['day'] == 'Sen';
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        isToday ? AppTheme.primaryGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        d['day'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? Colors.white
                              : AppTheme.textGrey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        d['icon'] as IconData,
                        size: 20,
                        color: isToday ? Colors.white : color,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$score',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isToday ? Colors.white : color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Navigation ────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.notifications_rounded, 'label': 'Notifikasi'},
      {'icon': Icons.flag_rounded, 'label': 'Laporan'},
      {'icon': Icons.person_rounded, 'label': 'Profil'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == 0;
              return GestureDetector(
                onTap: () {
                  if (i == 0) Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.primaryGreen.withAlpha(20)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: active
                            ? AppTheme.primaryGreen
                            : AppTheme.textGrey,
                        size: 24,
                      ),
                      if (active) ...[
                        const SizedBox(width: 6),
                        Text(
                          items[i]['label'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// VillageBannerPainter — simple green village scene
// ─────────────────────────────────────────────────────────────────────────────
class VillageBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky
    final sky = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFB3E5FC), Color(0xFF81C784)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // Sun
    canvas.drawCircle(Offset(w * 0.85, h * 0.2), 20,
        Paint()..color = const Color(0xFFFFF176));

    // Hills
    final hill = Paint()..color = const Color(0xFF388E3C);
    final hillPath = Path()
      ..moveTo(0, h * 0.65)
      ..quadraticBezierTo(w * 0.3, h * 0.3, w * 0.55, h * 0.6)
      ..quadraticBezierTo(w * 0.75, h * 0.8, w, h * 0.55)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillPath, hill);

    // Ground
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
        Paint()..color = const Color(0xFF43A047));

    // House 1
    _drawHouse(canvas, w * 0.1, h * 0.78, 44, 30);
    // House 2
    _drawHouse(canvas, w * 0.4, h * 0.76, 38, 26);
    // Trees
    _drawTree(canvas, w * 0.3, h * 0.78, 10, 24);
    _drawTree(canvas, w * 0.65, h * 0.76, 12, 28);
    _drawTree(canvas, w * 0.8, h * 0.75, 10, 22);

    // Label overlay
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Lingkungan Bersih, Sehat & Nyaman 🌿',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: w - 24);
    textPainter.paint(canvas, Offset(16, h - textPainter.height - 10));
  }

  void _drawHouse(Canvas canvas, double left, double bottom, double w, double h) {
    canvas.drawRect(
        Rect.fromLTWH(left, bottom - h, w, h),
        Paint()..color = const Color(0xFFFFECB3));
    final roof = Path()
      ..moveTo(left - 3, bottom - h)
      ..lineTo(left + w / 2, bottom - h - w * 0.5)
      ..lineTo(left + w + 3, bottom - h)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF8D6E63));
    canvas.drawRect(
        Rect.fromLTWH(left + w / 2 - 5, bottom - 15, 10, 15),
        Paint()..color = const Color(0xFF795548));
  }

  void _drawTree(Canvas canvas, double cx, double bottom, double tw, double th) {
    canvas.drawRect(
        Rect.fromLTWH(cx - tw / 4, bottom - th * 0.3, tw / 2, th * 0.3),
        Paint()..color = const Color(0xFF795548));
    final canopy = Path()
      ..moveTo(cx - tw, bottom - th * 0.3)
      ..lineTo(cx, bottom - th)
      ..lineTo(cx + tw, bottom - th * 0.3)
      ..close();
    canvas.drawPath(canopy, Paint()..color = const Color(0xFF1B5E20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// SemicircleGaugePainter — colored arc: red → yellow → green
// ─────────────────────────────────────────────────────────────────────────────
class SemicircleGaugePainter extends CustomPainter {
  final double value;
  final double maxValue;

  const SemicircleGaugePainter({required this.value, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.75);
    final radius = size.width * 0.42;

    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Track (grey background)
    final trackPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Gradient arc (red → yellow → green)
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradientPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: math.pi,
        endAngle: 2 * math.pi,
        colors: [
          Colors.red,
          Color(0xFFFF7A00),
          Color(0xFFFFC107),
          Color(0xFF8BC34A),
          Color(0xFF107C41),
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final filledSweep = sweepAngle * (value / maxValue);
    canvas.drawArc(rect, startAngle, filledSweep, false, gradientPaint);

    // Needle tip dot
    final angle = startAngle + filledSweep;
    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);
    canvas.drawCircle(
      Offset(dotX, dotY),
      10,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(dotX, dotY),
      7,
      Paint()..color = AppTheme.primaryGreen,
    );
  }

  @override
  bool shouldRepaint(covariant SemicircleGaugePainter old) =>
      old.value != value || old.maxValue != maxValue;
}
