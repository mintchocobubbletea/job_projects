import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  final Color color;
  final String username;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.color,
    required this.username,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // 게시글 데이터
  Map<String, dynamic>? post;
  // 댓글 목록
  List<dynamic> comments = [];
  bool isLoading = true;

  // 댓글 입력 컨트롤러
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // WebSocket 채널 (실시간 댓글)
  late WebSocketChannel _channel;

  static const String _baseUrl = 'http://192.168.0.20:8000';
  static const String _wsBase = 'ws://192.168.0.20:8000';

  @override
  void initState() {
    super.initState();
    fetchPost();
    // WebSocket 연결 (실시간 댓글)
    _channel = WebSocketChannel.connect(
      Uri.parse('$_wsBase/posts/ws/${widget.postId}/${widget.username}'),
    );
    // 실시간 댓글 수신
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      setState(() {
        comments.add({
          'author': data['author'],
          'content': data['content'],
          'created_at': data['created_at'],
        });
      });
      // 새 댓글 오면 자동 스크롤
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  // 게시글 상세 데이터 가져오기
  Future<void> fetchPost() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/detail/${widget.postId}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          post = data;
          // 기존 댓글 목록 설정
          comments = data['comments'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // 댓글 전송 (WebSocket으로 실시간 전송)
  void _sendComment() {
    if (_commentController.text.trim().isEmpty) return;
    // WebSocket으로 댓글 내용 전송
    _channel.sink.add(_commentController.text.trim());
    _commentController.clear();
  }

  @override
  void dispose() {
    // 화면 나갈 때 WebSocket 연결 해제
    _channel.sink.close();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
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
          post?['category'] ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3949AB)),
            )
          : Column(
              children: [
                // 게시글 + 댓글 목록
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 게시글 본문 카드
                      Container(
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 제목
                            Text(
                              post?['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 작성자 + 날짜 + 조회수
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 13,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  post?['author'] ?? '',
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
                                  post?['created_at'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 13,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${post?['views'] ?? 0}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // 본문
                            Text(
                              post?['content'] ?? '',
                              style: const TextStyle(fontSize: 15, height: 1.7),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 댓글 수
                      Text(
                        '댓글 ${comments.length}개',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 댓글 목록
                      ...comments.map((comment) {
                        final isMe = comment['author'] == widget.username;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 댓글 작성자 + 날짜
                              Row(
                                children: [
                                  Text(
                                    comment['author'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isMe
                                          ? widget.color
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    comment['created_at'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // 댓글 내용
                              Text(
                                comment['content'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // 댓글 입력창
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: '댓글을 입력해주세요',
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) => _sendComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 댓글 전송 버튼
                        CircleAvatar(
                          backgroundColor: widget.color,
                          child: IconButton(
                            onPressed: _sendComment,
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
