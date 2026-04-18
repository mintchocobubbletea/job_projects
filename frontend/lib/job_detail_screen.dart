import 'package:flutter/material.dart';
import 'chat_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;
  final String username;

  const JobDetailScreen({super.key, required this.job, required this.username});

  // 직종별 아이콘 (job_list_screen.dart랑 동일)
  IconData _getJobIcon(String title) {
    if (title.contains('백엔드')) return Icons.storage_rounded;
    if (title.contains('프론트')) return Icons.web_rounded;
    if (title.contains('AI') || title.contains('머신'))
      return Icons.psychology_rounded;
    if (title.contains('디자인')) return Icons.brush_rounded;
    return Icons.work_rounded;
  }

  // 직종별 색상 (job_list_screen.dart랑 동일)
  Color _getJobColor(String title) {
    if (title.contains('백엔드')) return const Color(0xFF3949AB);
    if (title.contains('프론트')) return const Color(0xFF00897B);
    if (title.contains('AI') || title.contains('머신'))
      return const Color(0xFF8E24AA);
    if (title.contains('디자인')) return const Color(0xFFE53935);
    return const Color(0xFF3949AB);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getJobColor(job['title']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // 상단 헤더 (스크롤하면 접힘)
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 직종 아이콘
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _getJobIcon(job['title']),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 공고 제목
                        Text(
                          job['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 공고 상세 내용
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 회사 정보 카드
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      children: [
                        // 회사명
                        _infoRow(
                          icon: Icons.business_rounded,
                          label: '회사',
                          value: job['company'],
                          color: color,
                        ),
                        const Divider(height: 24),
                        // 근무지
                        _infoRow(
                          icon: Icons.location_on_rounded,
                          label: '근무지',
                          value: job['location'],
                          color: color,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 공고 상세 내용 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '공고 내용',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          // description 없으면 기본 텍스트 표시
                          job['description']?.isNotEmpty == true
                              ? job['description']
                              : '상세 내용이 없습니다.',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), // 버튼 공간 확보
                ],
              ),
            ),
          ),
        ],
      ),

      // 하단 채팅방 입장 버튼
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatScreen(room: job['title'], username: username),
                  ),
                );
              },
              icon: const Icon(Icons.chat_rounded),
              label: const Text(
                '채팅방 입장',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 정보 행 위젯 (아이콘 + 라벨 + 값)
  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
