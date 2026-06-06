// account_screen.dart
// 계정 설정 화면
// 닉네임 변경, 비밀번호 변경, 로그아웃, 회원탈퇴 기능 제공
// JWT 토큰을 Authorization 헤더에 포함하여 인증된 요청 전송

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';

class AccountScreen extends StatefulWidget {
  // 현재 로그인한 사용자의 닉네임
  final String username;
  const AccountScreen({super.key, required this.username});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // 백엔드 서버 주소
  static const String _baseUrl = 'http://192.168.0.20:8000';

  // 닉네임 변경 입력 컨트롤러
  final TextEditingController _nicknameController = TextEditingController();
  // 비밀번호 변경 입력 컨트롤러
  final TextEditingController _currentPwController = TextEditingController();
  final TextEditingController _newPwController = TextEditingController();
  final TextEditingController _newPwConfirmController = TextEditingController();

  // 비밀번호 숨김 여부
  bool _currentPwHidden = true;
  bool _newPwHidden = true;
  bool _newPwConfirmHidden = true;

  // API 요청 중 여부 (중복 요청 방지)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 현재 닉네임을 입력창 초기값으로 설정
    _nicknameController.text = widget.username;
  }

  // 로그아웃 처리
  // SharedPreferences에서 토큰과 닉네임 삭제 후 로그인 화면으로 이동
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    // 저장된 토큰과 닉네임 삭제
    await prefs.remove('token');
    await prefs.remove('nickname');

    if (mounted) {
      // 모든 이전 화면을 스택에서 제거하고 로그인 화면으로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  // 로그아웃 확인 다이얼로그
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3949AB),
              foregroundColor: Colors.white,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  // 회원탈퇴 확인 다이얼로그
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '정말 탈퇴하시겠습니까?\n탈퇴 후 모든 데이터는 삭제됩니다.',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }

  // 닉네임 변경 API 호출
  Future<void> _changeNickname() async {
    // 입력값 유효성 검사
    if (_nicknameController.text.trim().isEmpty) {
      _showSnackBar('닉네임을 입력해주세요');
      return;
    }
    if (_nicknameController.text.trim().length < 2) {
      _showSnackBar('닉네임은 2글자 이상이어야 해요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 저장된 JWT 토큰 조회
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // 닉네임 변경 API 호출
      // Authorization 헤더에 JWT 토큰 포함 (Bearer 방식)
      final response = await http.patch(
        Uri.parse('$_baseUrl/auth/nickname'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nickname': _nicknameController.text.trim()}),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // 변경 성공 시 로컬 저장소의 닉네임도 업데이트
        await prefs.setString('nickname', _nicknameController.text.trim());
        _showSnackBar('닉네임이 변경됐습니다');
      } else {
        _showSnackBar(data['detail'] ?? '닉네임 변경에 실패했습니다');
      }
    } catch (e) {
      _showSnackBar('서버에 연결할 수 없습니다');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 비밀번호 변경 API 호출
  Future<void> _changePassword() async {
    // 입력값 유효성 검사
    if (_currentPwController.text.isEmpty ||
        _newPwController.text.isEmpty ||
        _newPwConfirmController.text.isEmpty) {
      _showSnackBar('모든 항목을 입력해주세요');
      return;
    }
    if (_newPwController.text.length < 6) {
      _showSnackBar('새 비밀번호는 6글자 이상이어야 해요');
      return;
    }
    // 새 비밀번호 확인 일치 여부 검사
    if (_newPwController.text != _newPwConfirmController.text) {
      _showSnackBar('새 비밀번호가 일치하지 않습니다');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // 비밀번호 변경 API 호출
      final response = await http.patch(
        Uri.parse('$_baseUrl/auth/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': _currentPwController.text,
          'new_password': _newPwController.text,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // 변경 성공 시 입력창 초기화
        _currentPwController.clear();
        _newPwController.clear();
        _newPwConfirmController.clear();
        _showSnackBar('비밀번호가 변경됐습니다');
      } else {
        _showSnackBar(data['detail'] ?? '비밀번호 변경에 실패했습니다');
      }
    } catch (e) {
      _showSnackBar('서버에 연결할 수 없습니다');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 회원탈퇴 API 호출
  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // 회원탈퇴 API 호출
      final response = await http.delete(
        Uri.parse('$_baseUrl/auth/delete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // 탈퇴 성공 시 로컬 저장소 토큰 삭제 후 로그인 화면으로 이동
        await prefs.remove('token');
        await prefs.remove('nickname');

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
          );
        }
      } else {
        _showSnackBar('회원 탈퇴에 실패했습니다');
      }
    } catch (e) {
      _showSnackBar('서버에 연결할 수 없습니다');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 스낵바 표시 헬퍼 함수
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    // 화면 종료 시 모든 컨트롤러 해제 (메모리 누수 방지)
    _nicknameController.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    _newPwConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '계정 설정',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 카드 (현재 닉네임 표시)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3949AB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // 닉네임 첫 글자로 아바타 생성
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      widget.username.characters.first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 현재 닉네임
                      Text(
                        widget.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '취직하잡 회원',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 닉네임 변경 섹션
            _buildSectionTitle('닉네임 변경'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: Color(0xFF3949AB), width: 3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 새 닉네임 입력창
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      labelText: '새 닉네임',
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFF3949AB),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF3949AB),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 닉네임 변경 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changeNickname,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3949AB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('닉네임 변경'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 비밀번호 변경 섹션
            _buildSectionTitle('비밀번호 변경'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: Color(0xFF00897B), width: 3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 현재 비밀번호 입력창 (본인 확인용)
                  _buildPwField(
                    controller: _currentPwController,
                    label: '현재 비밀번호',
                    isHidden: _currentPwHidden,
                    onToggle: () =>
                        setState(() => _currentPwHidden = !_currentPwHidden),
                  ),
                  const SizedBox(height: 12),
                  // 새 비밀번호 입력창
                  _buildPwField(
                    controller: _newPwController,
                    label: '새 비밀번호',
                    isHidden: _newPwHidden,
                    onToggle: () =>
                        setState(() => _newPwHidden = !_newPwHidden),
                  ),
                  const SizedBox(height: 12),
                  // 새 비밀번호 확인 입력창
                  _buildPwField(
                    controller: _newPwConfirmController,
                    label: '새 비밀번호 확인',
                    isHidden: _newPwConfirmHidden,
                    onToggle: () => setState(
                      () => _newPwConfirmHidden = !_newPwConfirmHidden,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 비밀번호 변경 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('비밀번호 변경'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 로그아웃 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout, color: Color(0xFF3949AB)),
                label: const Text(
                  '로그아웃',
                  style: TextStyle(
                    color: Color(0xFF3949AB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3949AB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 회원탈퇴 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _showDeleteAccountDialog,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  '회원 탈퇴',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // 홈 버튼과의 간격
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // 섹션 제목 위젯
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Color(0xFF3949AB),
      ),
    );
  }

  // 비밀번호 입력창 위젯
  // 숨김/표시 토글 버튼 포함
  Widget _buildPwField({
    required TextEditingController controller,
    required String label,
    required bool isHidden,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      // isHidden이 true일 때 비밀번호 가리기
      obscureText: isHidden,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00897B)),
        // 숨김/표시 토글 버튼
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            isHidden ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
        ),
      ),
    );
  }
}
