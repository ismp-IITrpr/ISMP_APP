import 'package:flutter/material.dart';
import '../screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISMP App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
        primaryColor: const Color(0xFF4A3AFF),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1C1C23),
          selectedItemColor: Color(0xFF4A3AFF),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}