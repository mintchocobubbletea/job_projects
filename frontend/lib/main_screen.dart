// main_screen.dart
// 메인 화면 파일
// 하단 탭 네비게이션으로 4개의 주요 화면을 전환
// 모든 탭에서 공통 앱바를 통해 계정 설정 화면으로 이동 가능

import 'package:flutter/material.dart';
import 'board_screen.dart'; // 커뮤니티 게시판 화면
import 'program_screen.dart'; // 직업훈련 프로그램 화면
import 'recruitment_screen.dart'; // 채용 정보 화면
import 'job_search_screen.dart'; // 직업탐색 + AI 매칭 화면
import 'account_screen.dart'; // 계정 설정 화면

class MainScreen extends StatefulWidget {
  // 로그인한 사용자의 닉네임 (모든 탭에서 사용)
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
    // 탭별 화면 목록
    // 각 화면에 로그인한 사용자의 닉네임 전달
    final screens = [
      BoardScreen(username: widget.username), // 커뮤니티 게시판
      ProgramScreen(username: widget.username), // 직업훈련 프로그램
      RecruitmentScreen(username: widget.username), // 채용 정보
      JobSearchScreen(username: widget.username), // 직업탐색 + AI 매칭
    ];

    return Scaffold(
      // 공통 앱바 (모든 탭에서 동일하게 표시)
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        // 현재 탭 이름 표시
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 우측 상단 닉네임 + 설정 아이콘
          // 탭하면 계정 설정 화면으로 이동
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
                  // 사람 아이콘
                  const Icon(Icons.person, color: Colors.white70, size: 18),
                  const SizedBox(width: 4),
                  // 닉네임 표시
                  Text(
                    widget.username,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  // 설정 아이콘
                  const Icon(Icons.settings, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      // 현재 선택된 탭의 화면 표시
      body: screens[_currentIndex],
      // 하단 탭 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        // 탭 선택 시 인덱스 업데이트
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF3949AB),
        unselectedItemColor: Colors.grey,
        // 탭 4개일 때 라벨 항상 표시 (fixed 타입)
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
