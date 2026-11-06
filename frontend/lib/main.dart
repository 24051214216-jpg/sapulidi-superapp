import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'utils/theme.dart';

void main() {
  // Pastikan binding sudah terinisialisasi (praktik terbaik Flutter)
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SapuLidiApp());
}

class SapuLidiApp extends StatelessWidget {
  const SapuLidiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SapuLidi',
      debugShowCheckedModeBanner:
          false, // Menghilangkan banner "DEBUG" di pojok
      theme: AppTheme.lightTheme, // Memanggil tema dari utils/theme.dart
      home: const LoginScreen(),
    );
  }
}
