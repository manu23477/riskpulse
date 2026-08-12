import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
class RiskPulseApp extends StatelessWidget {
  const RiskPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RiskPulse',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B5D5E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
        fontFamily: 'Roboto',
      ),
      home: const RiskPulseHome(),
    );
  }
}