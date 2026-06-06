// post_write_screen.dart
// 게시글 작성 화면
// 제목과 내용을 입력하고 백엔드 API로 게시글 등록
// 등록 성공 시 이전 화면(게시글 목록)으로 자동 이동

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PostWriteScreen extends StatefulWidget {
  // 게시판 카테고리명 (게시글 저장 시 카테고리 분류에 사용)
  final String category;
  // 작성자 닉네임
  final String username;
  // 게시판 테마 색상
  final Color color;

  const PostWriteScreen({
    super.key,
    required this.category,
    required this.username,
    required this.color,
  });

  @override
  State<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends State<PostWriteScreen> {
  // 제목 입력 컨트롤러
  final TextEditingController _titleController = TextEditingController();
  // 내용 입력 컨트롤러
  final TextEditingController _contentController = TextEditingController();
  // API 요청 중 여부 (중복 제출 방지)
  bool _isLoading = false;

  // 백엔드 서버 주소
  static const String _baseUrl = 'http://192.168.0.20:8000';

  // 게시글 등록 함수
  Future<void> _submit() async {
    // 제목/내용 빈 값 체크
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 게시글 작성 API 호출
      final response = await http.post(
        Uri.parse('$_baseUrl/posts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'category': widget.category, // 게시판 카테고리
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'author': widget.username, // 작성자 닉네임
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          // 등록 성공 시 이전 화면으로 이동
          // 이전 화면(게시글 목록)에서 새로고침하여 새 게시글 표시
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('게시글 등록에 실패했습니다')));
        }
      }
    } catch (e) {
      // 네트워크 오류 등 예외 처리
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('서버에 연결할 수 없습니다')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // 화면 종료 시 컨트롤러 해제 (메모리 누수 방지)
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: widget.color,
        elevation: 0,
        // 뒤로가기 버튼 색상
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${widget.category} 글쓰기',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 우측 상단 등록 버튼
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  // 로딩 중 스피너 표시
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '등록',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 제목 입력창
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '제목을 입력해주세요',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 내용 입력창 (화면 나머지 공간 모두 사용)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _contentController,
                  // 여러 줄 입력 가능
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: '내용을 입력해주세요',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  // 텍스트를 위쪽부터 입력
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
