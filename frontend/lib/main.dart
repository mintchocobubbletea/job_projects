import 'package:flutter/material.dart';
import 'login_screen.dart'; // 변경

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
      // 시작 화면을 로그인으로 변경
      home: const LoginScreen(),
    );
  }
}
