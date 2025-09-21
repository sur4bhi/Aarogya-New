import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'asha_dashboard_screen.dart';
import '../health_feed_screen.dart';
import '../chat_list_screen.dart';
import 'asha_patients_screen.dart';
import 'asha_profile_screen.dart';

class ASHAMainScreen extends StatefulWidget {
  const ASHAMainScreen({super.key});

  @override
  State<ASHAMainScreen> createState() => _ASHAMainScreenState();
}

class _ASHAMainScreenState extends State<ASHAMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ASHADashboardScreen(),
    const HealthFeedScreen(),
    const ChatListScreen(),
    const ASHAPatientsScreen(),
    const ASHAProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Health Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}