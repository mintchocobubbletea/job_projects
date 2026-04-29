import 'package:flutter/material.dart';
import 'chat_screen.dart';

class CommunityScreen extends StatelessWidget {
  final String username;
  const CommunityScreen({super.key, required this.username});

  // 채팅방 목록
  static const List<Map<String, dynamic>> rooms = [
    {
      'title': '면접 꿀팁',
      'description': '면접 준비 노하우를 나눠요',
      'icon': Icons.emoji_objects_rounded,
      'color': Color(0xFF3949AB),
    },
    {
      'title': '자기소개서',
      'description': '자소서 작성 팁과 피드백',
      'icon': Icons.edit_note_rounded,
      'color': Color(0xFF00897B),
    },
    {
      'title': '취업 후기',
      'description': '취업 성공/실패 경험 공유',
      'icon': Icons.workspace_premium_rounded,
      'color': Color(0xFF8E24AA),
    },
    {
      'title': '프로그램 후기',
      'description': '취업역량 강화프로그램 후기',
      'icon': Icons.rate_review_rounded,
      'color': Color(0xFFE53935),
    },
    {
      'title': '취업 고민',
      'description': '취업 준비 중 고민 나눠요',
      'icon': Icons.forum_rounded,
      'color': Color(0xFFF57C00),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        title: const Text(
          '커뮤니티',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white70, size: 18),
                const SizedBox(width: 4),
                Text(
                  username,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          final color = room['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(room['icon'] as IconData, color: color, size: 24),
              ),
              title: Text(
                room['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  room['description'],
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatScreen(room: room['title'], username: username),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
