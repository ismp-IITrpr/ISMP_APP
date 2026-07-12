import 'package:flutter/material.dart';
import '../screens/Homepage/home_screen.dart';
import '../screens/events_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reps/rep_dashboard.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'chatbot_widget.dart';

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
            FirebaseService.instance.currentUserEmail ?? 'robotics@iitrpr.ac.in')
        : '';

    _screens = [
      HomeScreen(onNavigateToTab: _onItemTapped),
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
            items: _navItems,
          ),
        ),
      ),
    );
  }
}