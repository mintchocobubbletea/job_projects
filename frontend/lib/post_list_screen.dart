// post_list_screen.dart
// 게시글 목록 화면
// 선택한 게시판의 게시글 목록을 표시
// 게시글 탭 시 상세 화면으로 이동, 우측 하단 버튼으로 글쓰기 가능

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'post_detail_screen.dart';
import 'post_write_screen.dart';

class PostListScreen extends StatefulWidget {
  // 게시판 카테고리명 (백엔드 API 파라미터로 사용)
  final String category;
  // 게시판 테마 색상
  final Color color;
  // 로그인한 사용자의 닉네임
  final String username;

  const PostListScreen({
    super.key,
    required this.category,
    required this.color,
    required this.username,
  });

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  // 게시글 목록
  List<dynamic> posts = [];
  bool isLoading = true;

  // 백엔드 서버 주소
  static const String _baseUrl = 'http://192.168.0.20:8000';

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 게시글 목록 불러오기
    fetchPosts();
  }

  // 게시글 목록 API 호출
  Future<void> fetchPosts() async {
    try {
      // 카테고리별 게시글 목록 조회
      // URI 인코딩으로 한글 카테고리명 처리
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/${Uri.encodeComponent(widget.category)}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          posts = data['posts'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
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
          widget.category,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // 우측 하단 글쓰기 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 글쓰기 화면으로 이동
          // 글쓰기 완료 후 돌아오면 목록 새로고침
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostWriteScreen(
                category: widget.category,
                username: widget.username,
                color: widget.color,
              ),
            ),
          );
          // 새 게시글 반영을 위해 목록 새로고침
          fetchPosts();
        },
        backgroundColor: widget.color,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      body: isLoading
          // 로딩 중 스피너 표시
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3949AB)),
            )
          : posts.isEmpty
          // 게시글 없을 때 안내 메시지
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 게시글이 없어요\n첫 글을 작성해보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            )
          // 게시글 목록 표시
          : RefreshIndicator(
              // 아래로 당기면 새로고침
              onRefresh: fetchPosts,
              color: widget.color,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      // 게시판 테마 색상으로 왼쪽 보더
                      border: Border(
                        left: BorderSide(color: widget.color, width: 3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      // 게시글 제목 (길면 말줄임표)
                      title: Text(
                        post['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 작성자, 작성일, 조회수
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            // 작성자
                            Icon(
                              Icons.person_outline,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              post['author'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // 작성일
                            Icon(
                              Icons.access_time,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              post['created_at'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            // 조회수
                            Icon(
                              Icons.visibility_outlined,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${post['views']}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 게시글 탭 시 상세 화면으로 이동
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(
                              postId: post['id'],
                              color: widget.color,
                              username: widget.username,
                            ),
                          ),
                        );
                        // 돌아올 때 조회수 반영을 위해 목록 새로고침
                        fetchPosts();
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
