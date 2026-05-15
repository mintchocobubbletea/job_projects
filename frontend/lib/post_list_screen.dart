import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'post_detail_screen.dart';
import 'post_write_screen.dart';

class PostListScreen extends StatefulWidget {
  final String category;
  final Color color;
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

  static const String _baseUrl = 'http://192.168.0.20:8000';

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  // 게시글 목록 가져오기
  Future<void> fetchPosts() async {
    try {
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // 글쓰기 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 글쓰기 화면으로 이동 후 돌아오면 목록 새로고침
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
          fetchPosts();
        },
        backgroundColor: widget.color,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3949AB)),
            )
          : posts.isEmpty
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
          : RefreshIndicator(
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
                      // 게시글 제목
                      title: Text(
                        post['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 작성자, 날짜, 조회수
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
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
                      onTap: () async {
                        // 게시글 상세 화면으로 이동
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
                        // 돌아오면 목록 새로고침 (조회수 반영)
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
