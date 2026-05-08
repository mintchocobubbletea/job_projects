import 'package:flutter/material.dart';

class JobTrainingScreen extends StatelessWidget {
  final String username;
  const JobTrainingScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        title: const Text(
          '직업/훈련',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      // AI 매칭 기능 준비 중 표시
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_rounded, size: 64, color: Color(0xFF3949AB)),
            SizedBox(height: 16),
            Text(
              'AI 매칭 기능 준비 중',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3949AB),
              ),
            ),
            SizedBox(height: 8),
            Text('AI API 연동 후 오픈 예정이에요', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
