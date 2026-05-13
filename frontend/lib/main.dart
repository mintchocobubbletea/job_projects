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
      title: '구직 커뮤니티',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // 자동 로그인 체크 화면으로 시작
      home: const SplashScreen(),
    );
  }
}

// 자동 로그인 체크 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 저장된 토큰 확인
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    // 저장된 토큰과 닉네임 확인
    final token = prefs.getString('token');
    final nickname = prefs.getString('nickname');

    if (mounted) {
      if (token != null && nickname != null) {
        // 토큰 있으면 메인 화면으로 바로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(username: nickname),
          ),
        );
      } else {
        // 토큰 없으면 로그인 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중 스플래시 화면
    return Scaffold(
      backgroundColor: const Color(0xFF3949AB),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_rounded, color: Colors.white, size: 64),
            SizedBox(height: 16),
            Text(
              '구직 커뮤니티',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
