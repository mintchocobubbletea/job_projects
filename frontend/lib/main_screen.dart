import 'package:flutter/material.dart';
import 'community_screen.dart';
import 'program_screen.dart';
import 'job_info_screen.dart';

class MainScreen extends StatefulWidget {
  final String username;
  const MainScreen({super.key, required this.username});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      CommunityScreen(username: widget.username),
      ProgramScreen(username: widget.username),
      const JobInfoScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF3949AB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: '커뮤니티',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_rounded),
            label: '취업 프로그램',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_rounded),
            label: '직업정보',
          ),
        ],
      ),
    );
  }
}
