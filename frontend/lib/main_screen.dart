import 'package:flutter/material.dart';
import 'community_screen.dart';
import 'program_screen.dart';
import 'recruitment_screen.dart';
import 'job_training_screen.dart';

class MainScreen extends StatefulWidget {
  final String username;
  const MainScreen({super.key, required this.username});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 현재 선택된 탭 인덱스
  // 0: 커뮤니티, 1: 취업 프로그램, 2: 채용 정보, 3: 직업/훈련
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      CommunityScreen(username: widget.username),
      ProgramScreen(username: widget.username),
      RecruitmentScreen(username: widget.username),
      JobTrainingScreen(username: widget.username),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF3949AB),
        unselectedItemColor: Colors.grey,
        // 탭 4개일 때 라벨 항상 표시
        type: BottomNavigationBarType.fixed,
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
            label: '채용 정보',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_rounded),
            label: '직업/훈련',
          ),
        ],
      ),
    );
  }
}
