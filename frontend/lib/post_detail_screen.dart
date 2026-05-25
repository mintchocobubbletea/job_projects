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

  // 신고 다이얼로그 표시
  void _showReportDialog({
    required String reportType,
    required int targetId,
    required String targetAuthor,
  }) {
    String selectedReason = '욕설/비방';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(reportType == 'post' ? '게시글 신고' : '댓글 신고'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '작성자: $targetAuthor',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                '신고 사유',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // 신고 사유 선택 드롭다운
              DropdownButton<String>(
                value: selectedReason,
                isExpanded: true,
                items: ['욕설/비방', '스팸/광고', '개인정보 유출', '불쾌한 언행', '허위 정보', '기타']
                    .map(
                      (reason) =>
                          DropdownMenuItem(value: reason, child: Text(reason)),
                    )
                    .toList(),
                onChanged: (value) {
                  setDialogState(() => selectedReason = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _submitReport(
                  reportType: reportType,
                  targetId: targetId,
                  reason: selectedReason,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('신고'),
            ),
          ],
        ),
      ),
    );
  }

  // 신고 API 호출
  Future<void> _submitReport({
    required String reportType,
    required int targetId,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'report_type': reportType,
          'target_id': targetId,
          'reason': reason,
          'reporter': widget.username,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 200
                  ? '신고가 접수됐습니다'
                  : data['detail'] ?? '신고에 실패했습니다',
            ),
            backgroundColor: response.statusCode == 200
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('서버에 연결할 수 없습니다')));
      }
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
                            // 제목 + 신고 버튼
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 제목
                                Expanded(
                                  child: Text(
                                    post?['title'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                // 신고 버튼 (내 게시글이 아닐 때만 표시)
                                if (post?['author'] != widget.username)
                                  GestureDetector(
                                    onTap: () => _showReportDialog(
                                      reportType: 'post',
                                      targetId: widget.postId,
                                      targetAuthor: post?['author'] ?? '',
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.flag_outlined,
                                        size: 18,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                              ],
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
                                  // 내 댓글이 아닐 때만 신고 버튼 표시
                                  if (!isMe) ...[
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _showReportDialog(
                                        reportType: 'comment',
                                        targetId: comment['id'] ?? 0,
                                        targetAuthor: comment['author'],
                                      ),
                                      child: Icon(
                                        Icons.flag_outlined,
                                        size: 14,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
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
