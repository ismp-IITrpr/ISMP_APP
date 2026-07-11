import 'package:flutter/material.dart';
import '../screens/Homepage/home_screen.dart';
import '../screens/reps/rep_events_screen.dart';
import '../screens/reps/rep_attendance_home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reps/rep_profile_screen.dart';
import '../widgets/rep_main_layout.dart';

class RepMainLayout extends StatefulWidget {
  const RepMainLayout({super.key});

  @override
  State<RepMainLayout> createState() => _RepMainLayoutState();
}

class _RepMainLayoutState extends State<RepMainLayout> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(onNavigateToTab: _onItemTapped),
    const RepEventsScreen(),
    const RepAttendanceHomeScreen(), // ← Yeh change kiya
    const RepProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F1635),
            Color(0xFF0F0920),
            Color(0xFF1F1635),
            Color(0xFF0F0920),
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: const Color(0xFF1F1635),
          selectedItemColor: const Color(0xFFD9278D),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Attendance'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}