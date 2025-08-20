import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/walkthrough_screen.dart';
//import 'screens/login_screen.dart';
//import 'screens/signup_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prerna - Quick Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Lufga',
      ),
      home: const WalkthroughScreen(),
    );
  }
}
