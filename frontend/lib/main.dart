import 'package:flutter/material.dart';
import 'job_list_screen.dart'; // 공고 목록 화면

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
      // 앱 시작 화면을 공고 목록으로 설정
      home: const JobListScreen(),
    );
  }
}
