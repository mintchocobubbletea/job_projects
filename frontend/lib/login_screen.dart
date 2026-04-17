import 'package:flutter/material.dart';
import 'job_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  // 닉네임이 비어있을 때 에러 메시지 표시용
  String? _errorText;

  void _enter() {
    final nickname = _nicknameController.text.trim();

    // 닉네임 유효성 검사
    if (nickname.isEmpty) {
      setState(() {
        _errorText = '닉네임을 입력해주세요';
      });
      return;
    }
    if (nickname.length < 2) {
      setState(() {
        _errorText = '닉네임은 2글자 이상이어야 해요';
      });
      return;
    }

    // 유효하면 공고 목록 화면으로 이동하면서 닉네임 전달
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => JobListScreen(username: nickname),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 앱 타이틀
              const Text(
                '구직 커뮤니티',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '닉네임을 입력하고 시작하세요',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 48),
              // 닉네임 입력창
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  hintText: '사용할 닉네임 입력',
                  errorText: _errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                // 에러 메시지 입력 시작하면 지우기
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() {
                      _errorText = null;
                    });
                  }
                },
                onSubmitted: (_) => _enter(),
              ),
              const SizedBox(height: 16),
              // 입장 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _enter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('입장하기', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
