import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/events_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/rep_dashboard.dart';
import '../services/firebase_service.dart';

class MainLayout extends StatefulWidget {
  final bool isRep;

  const MainLayout({super.key, this.isRep = false});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();

    final repClub = widget.isRep
        ? FirebaseService.instance.getClubForEmail(
            FirebaseService.instance.currentUser?.email ?? 'robotics@iitrpr.ac.in')
        : '';

    _screens = [
      const HomeScreen(),
      EventsScreen(isRep: widget.isRep, repClub: repClub),
      AttendanceScreen(isRep: widget.isRep, repClub: repClub),

    ProfileScreen(isRep: widget.isRep),
    if (widget.isRep) const RepDashboard(),
    ];

    _navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
      const BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Attendance'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      if (widget.isRep)
        const BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create Event'),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2B124C), // Shiny Purple
            Color(0xFF0F0F13), // Midnight Dark
            Color(0xFF1E103C), // Deep Indigo
            Color(0xFF0F0F13), // Midnight Dark
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
          items: _navItems,
        ),
      ),
    );
  }
}