import 'package:flutter/material.dart';
import 'board_screen.dart';
import 'program_screen.dart';
import 'recruitment_screen.dart';
import 'job_search_screen.dart';
import 'account_screen.dart';

class MainScreen extends StatefulWidget {
  final String username;
  const MainScreen({super.key, required this.username});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 현재 선택된 탭 인덱스
  // 0: 커뮤니티, 1: 직업훈련, 2: 채용정보, 3: 직업탐색
  int _currentIndex = 0;

  // 탭별 앱바 제목
  final List<String> _titles = ['커뮤니티', '직업훈련', '채용 정보', '직업탐색'];

  @override
  Widget build(BuildContext context) {
    final screens = [
      BoardScreen(username: widget.username),
      ProgramScreen(username: widget.username),
      RecruitmentScreen(username: widget.username),
      JobSearchScreen(username: widget.username),
    ];

    return Scaffold(
      // 공통 앱바 (모든 탭에서 닉네임 + 계정 설정 접근 가능)
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 닉네임 + 설정 아이콘 → 계정 설정 화면으로 이동
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AccountScreen(username: widget.username),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white70, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    widget.username,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.settings, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF3949AB),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: '커뮤니티',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_rounded),
            label: '직업훈련',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_rounded),
            label: '채용 정보',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_rounded),
            label: '직업탐색',
          ),
        ],
      ),
    );
  }
}
