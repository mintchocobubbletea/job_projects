// board_screen.dart
// 커뮤니티 게시판 목록 화면
// 취업 관련 주제별 게시판 목록을 표시
// 게시판 탭 시 해당 게시판의 게시글 목록 화면으로 이동

import 'package:flutter/material.dart';
import 'post_list_screen.dart';

class BoardScreen extends StatelessWidget {
  // 로그인한 사용자의 닉네임
  final String username;
  const BoardScreen({super.key, required this.username});

  // 게시판 목록 데이터
  // category: 게시판 카테고리명 (백엔드 API 파라미터로 사용)
  // description: 게시판 설명
  // icon: 게시판 아이콘
  // color: 게시판 테마 색상 (카드 왼쪽 보더, 아이콘 배경에 사용)
  static const List<Map<String, dynamic>> boards = [
    {
      'category': '면접 꿀팁',
      'description': '면접 준비 노하우를 나눠요',
      'icon': Icons.emoji_objects_rounded,
      'color': Color(0xFF3949AB),
    },
    {
      'category': '자기소개서',
      'description': '자소서 작성 팁과 피드백',
      'icon': Icons.edit_note_rounded,
      'color': Color(0xFF00897B),
    },
    {
      'category': '취업 후기',
      'description': '취업 성공/실패 경험 공유',
      'icon': Icons.workspace_premium_rounded,
      'color': Color(0xFF8E24AA),
    },
    {
      'category': '프로그램 후기',
      'description': '취업역량 강화프로그램 후기',
      'icon': Icons.rate_review_rounded,
      'color': Color(0xFFE53935),
    },
    {
      'category': '취업 고민',
      'description': '취업 준비 중 고민 나눠요',
      'icon': Icons.forum_rounded,
      'color': Color(0xFFF57C00),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // 상단 안내 배너
          Container(
            color: const Color(0xFF3949AB),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '관심 있는 게시판에서 취업 정보를 나눠요',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 게시판 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: boards.length,
              itemBuilder: (context, index) {
                final board = boards[index];
                final color = board['color'] as Color;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    // 게시판 테마 색상으로 왼쪽 보더 표시
                    border: Border(left: BorderSide(color: color, width: 3)),
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
                    // 게시판 아이콘
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        board['icon'] as IconData,
                        color: color,
                        size: 24,
                      ),
                    ),
                    // 게시판 이름
                    title: Text(
                      board['category'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // 게시판 설명
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        board['description'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // 입장 버튼
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '입장',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // 게시판 탭 시 게시글 목록 화면으로 이동
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostListScreen(
                            category: board['category'],
                            color: color,
                            username: username,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
