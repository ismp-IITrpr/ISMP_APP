import 'package:flutter/material.dart';
import '../screens/Homepage/home_screen.dart';
import '../screens/reps/rep_events_screen.dart';
import '../screens/reps/rep_attendance_home_screen.dart';
import '../screens/reps/rep_profile_screen.dart';
import '../theme/app_theme.dart';
import 'chatbot_widget.dart';

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
        gradient: AppTheme.backgroundGradient,
      ),
      child: ChatbotWidget(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Attendance'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}