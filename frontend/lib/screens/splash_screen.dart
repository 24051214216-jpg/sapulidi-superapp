import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF054A23), // very dark green
              Color(0xFF107C41), // primaryGreen
              Color(0xFF2EA05A), // lighter green
              Color(0xFF4CAF73), // even lighter
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Illustration area ─────────────────────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: CustomPaint(
                    painter: LandscapePainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

              // ── Text & CTA ────────────────────────────────────────
              Expanded(
                flex: 4,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo badge
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(80),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Title
                          Text(
                            'SELAMAT DATANG DI\nSAPU LIDI',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: size.width < 360 ? 22 : 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Subtitle
                          Text(
                            'Gotong royong membangun lingkungan\nyang bersih dan sehat bersama.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withAlpha(210),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // CTA Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _goToLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentOrange,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 6,
                                shadowColor:
                                    AppTheme.accentOrange.withAlpha(100),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Mulai Sekarang',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Footer label
                          Text(
                            'RT/RW Digital · Gotong Royong',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withAlpha(150),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LandscapePainter — simple geometric village landscape
// ─────────────────────────────────────────────────────────────────────────────
class LandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Sky gradient ──────────────────────────────────────────────
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFB3E5FC), Color(0xFF81C784)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.65));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.65), skyPaint);

    // ── Clouds ────────────────────────────────────────────────────
    _drawCloud(canvas, w * 0.15, h * 0.08, 28);
    _drawCloud(canvas, w * 0.65, h * 0.05, 22);

    // ── Far mountains (dark green) ────────────────────────────────
    final mtPaint = Paint()..color = const Color(0xFF1B5E20);
    _drawTriangle(canvas, mtPaint, w * 0.0, h * 0.55, w * 0.28, h * 0.22,
        w * 0.55, h * 0.55);
    _drawTriangle(canvas, mtPaint, w * 0.35, h * 0.55, w * 0.6, h * 0.18,
        w * 0.88, h * 0.55);

    // ── Mid mountains (medium green) ──────────────────────────────
    final midMt = Paint()..color = const Color(0xFF2E7D32);
    _drawTriangle(
        canvas, midMt, -w * 0.05, h * 0.6, w * 0.18, h * 0.32, w * 0.4, h * 0.6);
    _drawTriangle(
        canvas, midMt, w * 0.6, h * 0.6, w * 0.82, h * 0.3, w * 1.05, h * 0.6);

    // ── Rolling hills ─────────────────────────────────────────────
    final hillPaint = Paint()..color = const Color(0xFF388E3C);
    final hillPath = Path()
      ..moveTo(0, h * 0.65)
      ..quadraticBezierTo(w * 0.25, h * 0.48, w * 0.5, h * 0.62)
      ..quadraticBezierTo(w * 0.75, h * 0.74, w, h * 0.6)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillPath, hillPaint);

    // ── Ground / fields ───────────────────────────────────────────
    final groundPaint = Paint()..color = const Color(0xFF43A047);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.72, w, h * 0.28), groundPaint);

    // Field stripes (yellow-green)
    final fieldPaint = Paint()..color = const Color(0xFF8BC34A).withAlpha(120);
    for (int i = 0; i < 5; i++) {
      final top = h * 0.73 + i * h * 0.05;
      final path = Path()
        ..moveTo(0, top)
        ..quadraticBezierTo(w * 0.5, top - h * 0.015, w, top)
        ..lineTo(w, top + h * 0.025)
        ..quadraticBezierTo(w * 0.5, top + h * 0.01, 0, top + h * 0.025)
        ..close();
      canvas.drawPath(path, fieldPaint);
    }

    // ── Farmhouse ─────────────────────────────────────────────────
    _drawHouse(canvas, w * 0.55, h * 0.6, 52, 38);

    // ── Trees ─────────────────────────────────────────────────────
    _drawTree(canvas, w * 0.18, h * 0.63, 18, 36);
    _drawTree(canvas, w * 0.3, h * 0.65, 14, 28);
    _drawTree(canvas, w * 0.72, h * 0.64, 16, 32);
    _drawTree(canvas, w * 0.82, h * 0.62, 20, 40);
  }

  void _drawTriangle(Canvas canvas, Paint paint, double x1, double y1,
      double x2, double y2, double x3, double y3) {
    final path = Path()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2)
      ..lineTo(x3, y3)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double r) {
    final p = Paint()..color = Colors.white.withAlpha(200);
    canvas.drawCircle(Offset(cx, cy), r, p);
    canvas.drawCircle(Offset(cx + r * 0.8, cy + r * 0.1), r * 0.75, p);
    canvas.drawCircle(Offset(cx - r * 0.7, cy + r * 0.15), r * 0.65, p);
    canvas.drawRect(
        Rect.fromLTWH(cx - r * 0.65, cy, r * 1.5, r * 0.6), p);
  }

  void _drawTree(
      Canvas canvas, double cx, double bottom, double trunkW, double height) {
    // Trunk
    final trunkPaint = Paint()..color = const Color(0xFF795548);
    canvas.drawRect(
      Rect.fromLTWH(cx - trunkW / 4, bottom - height * 0.3,
          trunkW / 2, height * 0.3),
      trunkPaint,
    );
    // Canopy (triangle)
    final leafPaint = Paint()..color = const Color(0xFF1B5E20);
    _drawTriangle(
      canvas,
      leafPaint,
      cx - trunkW,
      bottom - height * 0.3,
      cx,
      bottom - height,
      cx + trunkW,
      bottom - height * 0.3,
    );
  }

  void _drawHouse(
      Canvas canvas, double left, double bottom, double w, double h) {
    // Wall
    final wallPaint = Paint()..color = const Color(0xFFD7CCC8);
    canvas.drawRect(
        Rect.fromLTWH(left, bottom - h, w, h), wallPaint);

    // Roof
    final roofPaint = Paint()..color = const Color(0xFF8D6E63);
    _drawTriangle(
      canvas,
      roofPaint,
      left - 4,
      bottom - h,
      left + w / 2,
      bottom - h - w * 0.45,
      left + w + 4,
      bottom - h,
    );

    // Door
    final doorPaint = Paint()..color = const Color(0xFF795548);
    canvas.drawRect(
        Rect.fromLTWH(left + w / 2 - 7, bottom - 18, 14, 18), doorPaint);

    // Window
    final winPaint = Paint()..color = const Color(0xFF90CAF9);
    canvas.drawRect(
        Rect.fromLTWH(left + 8, bottom - h + 10, 14, 12), winPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
