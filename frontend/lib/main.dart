// main.dart
// 앱 진입점 파일
// 앱 시작 시 자동 로그인 여부를 확인하고 적절한 화면으로 이동

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '취직하잡',
      // 우측 상단 DEBUG 배너 제거
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // 앱 시작 시 자동 로그인 확인 화면으로 시작
      home: const SplashScreen(),
    );
  }
}

// 스플래시 화면 (자동 로그인 확인)
// 앱 시작 시 저장된 토큰 확인 후 메인 또는 로그인 화면으로 이동
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 초기화 시 자동 로그인 확인
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    // SharedPreferences: 앱 로컬 저장소
    // 로그인 시 저장한 토큰과 닉네임 확인
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final nickname = prefs.getString('nickname');

    if (mounted) {
      if (token != null && nickname != null) {
        // 저장된 토큰이 있으면 메인 화면으로 이동 (자동 로그인)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(username: nickname),
          ),
        );
      } else {
        // 저장된 토큰이 없으면 로그인 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 자동 로그인 확인 중 표시할 스플래시 화면
    // 앱 로고와 이름 표시
    return Scaffold(
      backgroundColor: const Color(0xFF3949AB),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고 아이콘
            Icon(Icons.work_rounded, color: Colors.white, size: 64),
            SizedBox(height: 16),
            // 앱 이름
            Text(
              '취직하잡',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            // 로딩 인디케이터
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white70,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
