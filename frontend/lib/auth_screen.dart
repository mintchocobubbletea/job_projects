// auth_screen.dart
// 로그인 및 회원가입 화면 파일
// JWT 토큰 기반 인증 처리
// 로그인 성공 시 토큰을 SharedPreferences에 저장하여 자동 로그인 구현

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // 현재 탭 (0: 로그인, 1: 회원가입)
  int _tabIndex = 0;

  // 로그인 입력 컨트롤러
  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _loginPwController = TextEditingController();

  // 회원가입 입력 컨트롤러
  final TextEditingController _regIdController = TextEditingController();
  final TextEditingController _regNicknameController = TextEditingController();
  final TextEditingController _regPwController = TextEditingController();
  final TextEditingController _regPwConfirmController = TextEditingController();

  // 비밀번호 숨김 여부 (true: 숨김, false: 표시)
  bool _loginPwHidden = true;
  bool _regPwHidden = true;
  bool _regPwConfirmHidden = true;

  // 자동 로그인 여부 (기본값: true)
  bool _autoLogin = true;

  // API 요청 중 여부 (중복 요청 방지)
  bool _isLoading = false;

  // 에러 메시지 (입력값 오류 또는 서버 오류)
  String _errorMsg = '';

  // 백엔드 서버 주소
  // 실제 폰 연결 시 PC의 로컬 IP 주소 사용
  static const String _baseUrl = 'http://192.168.0.20:8000';

  // 로그인 처리 함수
  Future<void> _login() async {
    // 입력값 유효성 검사
    if (_loginIdController.text.isEmpty || _loginPwController.text.isEmpty) {
      setState(() => _errorMsg = '아이디와 비밀번호를 입력해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      // 백엔드 로그인 API 호출
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _loginIdController.text.trim(),
          'password': _loginPwController.text,
        }),
      );

      // 응답 데이터 파싱 (UTF-8 디코딩으로 한글 처리)
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // 자동 로그인 체크 시 토큰과 닉네임을 로컬 저장소에 저장
        if (_autoLogin) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('nickname', data['nickname']);
        }

        if (mounted) {
          // 로그인 성공 시 메인 화면으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(username: data['nickname']),
            ),
          );
        }
      } else {
        // 로그인 실패 시 서버에서 받은 에러 메시지 표시
        setState(() => _errorMsg = data['detail'] ?? '로그인에 실패했습니다');
      }
    } catch (e) {
      // 네트워크 오류 등 예외 처리
      setState(() => _errorMsg = '서버에 연결할 수 없습니다');
    } finally {
      // 로딩 상태 해제
      setState(() => _isLoading = false);
    }
  }

  // 회원가입 처리 함수
  Future<void> _register() async {
    // 입력값 유효성 검사
    if (_regIdController.text.isEmpty ||
        _regNicknameController.text.isEmpty ||
        _regPwController.text.isEmpty) {
      setState(() => _errorMsg = '모든 항목을 입력해주세요');
      return;
    }
    if (_regIdController.text.length < 4) {
      setState(() => _errorMsg = '아이디는 4글자 이상이어야 해요');
      return;
    }
    if (_regNicknameController.text.length < 2) {
      setState(() => _errorMsg = '닉네임은 2글자 이상이어야 해요');
      return;
    }
    if (_regPwController.text.length < 6) {
      setState(() => _errorMsg = '비밀번호는 6글자 이상이어야 해요');
      return;
    }
    // 비밀번호 확인 일치 여부 검사
    if (_regPwController.text != _regPwConfirmController.text) {
      setState(() => _errorMsg = '비밀번호가 일치하지 않습니다');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      // 백엔드 회원가입 API 호출
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _regIdController.text.trim(),
          'nickname': _regNicknameController.text.trim(),
          'password': _regPwController.text,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // 회원가입 성공 시 토큰과 닉네임 저장 후 메인 화면으로 이동
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('nickname', data['nickname']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(username: data['nickname']),
            ),
          );
        }
      } else {
        setState(() => _errorMsg = data['detail'] ?? '회원가입에 실패했습니다');
      }
    } catch (e) {
      setState(() => _errorMsg = '서버에 연결할 수 없습니다');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // 화면 종료 시 모든 컨트롤러 해제 (메모리 누수 방지)
    _loginIdController.dispose();
    _loginPwController.dispose();
    _regIdController.dispose();
    _regNicknameController.dispose();
    _regPwController.dispose();
    _regPwConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        // 인디고 그라데이션 배경
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            // 키보드 올라올 때 스크롤 가능하게
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 앱 로고 아이콘
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.work_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 앱 이름
                    const Text(
                      '취직하잡',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 앱 설명
                    const Text(
                      '취업 정보를 함께 나눠요',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    // 로그인/회원가입 카드
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 로그인/회원가입 탭 버튼
                          Row(
                            children: [
                              _buildTabButton('로그인', 0),
                              _buildTabButton('회원가입', 1),
                            ],
                          ),
                          // 탭에 따른 폼 표시
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: _tabIndex == 0
                                ? _buildLoginForm()
                                : _buildRegisterForm(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 개인정보처리방침 링크
                    GestureDetector(
                      onTap: () async {
                        final url = Uri.parse(
                          'https://mintchocobubbletea.github.io/job_projects/privacy_policy.html',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: const Text(
                        '개인정보처리방침',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 탭 버튼 위젯 (로그인/회원가입 전환)
  Widget _buildTabButton(String title, int index) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _tabIndex = index;
          _errorMsg = ''; // 탭 전환 시 에러 메시지 초기화
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            // 선택된 탭은 인디고, 미선택 탭은 회색
            color: isSelected ? const Color(0xFF3949AB) : Colors.grey.shade100,
            borderRadius: BorderRadius.only(
              topLeft: index == 0 ? const Radius.circular(20) : Radius.zero,
              topRight: index == 1 ? const Radius.circular(20) : Radius.zero,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // 로그인 폼 위젯
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이디 입력창
        _buildTextField(
          controller: _loginIdController,
          label: '아이디',
          hint: '아이디 입력',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 12),
        // 비밀번호 입력창
        _buildTextField(
          controller: _loginPwController,
          label: '비밀번호',
          hint: '비밀번호 입력',
          icon: Icons.lock_outline,
          isPassword: true,
          isHidden: _loginPwHidden,
          onToggleHidden: () =>
              setState(() => _loginPwHidden = !_loginPwHidden),
        ),
        const SizedBox(height: 8),
        // 자동 로그인 체크박스
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _autoLogin,
                onChanged: (value) =>
                    setState(() => _autoLogin = value ?? true),
                activeColor: const Color(0xFF3949AB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '자동 로그인',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        // 에러 메시지 표시
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _errorMsg,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
        const SizedBox(height: 20),
        // 로그인 버튼
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3949AB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '로그인',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  // 회원가입 폼 위젯
  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이디 입력창 (4글자 이상)
        _buildTextField(
          controller: _regIdController,
          label: '아이디',
          hint: '4글자 이상 입력',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 12),
        // 닉네임 입력창 (커뮤니티에서 표시될 이름)
        _buildTextField(
          controller: _regNicknameController,
          label: '닉네임',
          hint: '커뮤니티에서 사용할 이름',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 12),
        // 비밀번호 입력창 (6글자 이상)
        _buildTextField(
          controller: _regPwController,
          label: '비밀번호',
          hint: '6글자 이상 입력',
          icon: Icons.lock_outline,
          isPassword: true,
          isHidden: _regPwHidden,
          onToggleHidden: () => setState(() => _regPwHidden = !_regPwHidden),
        ),
        const SizedBox(height: 12),
        // 비밀번호 확인 입력창
        _buildTextField(
          controller: _regPwConfirmController,
          label: '비밀번호 확인',
          hint: '비밀번호 재입력',
          icon: Icons.lock_outline,
          isPassword: true,
          isHidden: _regPwConfirmHidden,
          onToggleHidden: () =>
              setState(() => _regPwConfirmHidden = !_regPwConfirmHidden),
        ),
        // 에러 메시지 표시
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _errorMsg,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
        const SizedBox(height: 20),
        // 회원가입 버튼
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3949AB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '회원가입',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  // 공통 텍스트 입력창 위젯
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false, // 비밀번호 필드 여부
    bool isHidden = false, // 비밀번호 숨김 여부
    VoidCallback? onToggleHidden, // 숨김/표시 토글 콜백
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 필드 라벨
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3949AB),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          // 비밀번호 필드이고 숨김 상태일 때 텍스트 가리기
          obscureText: isPassword && isHidden,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            // 좌측 아이콘
            prefixIcon: Icon(icon, color: const Color(0xFF3949AB), size: 20),
            // 비밀번호 필드일 때 우측 토글 버튼 표시
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: onToggleHidden,
                    icon: Icon(
                      isHidden ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                      size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            // 포커스 시 인디고 테두리
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3949AB), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          // 키보드 완료 버튼으로 제출
          onSubmitted: (_) => _tabIndex == 0 ? _login() : _register(),
        ),
      ],
    );
  }
}
