import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'job_detail_screen.dart';
import 'chat_screen.dart';

class JobListScreen extends StatefulWidget {
  final String username;
  const JobListScreen({super.key, required this.username});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  List<dynamic> jobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.20:8000/jobs'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          jobs = data['jobs'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 직종별 아이콘 반환
  IconData _getJobIcon(String title) {
    if (title.contains('백엔드')) return Icons.storage_rounded;
    if (title.contains('프론트')) return Icons.web_rounded;
    if (title.contains('AI') || title.contains('머신'))
      return Icons.psychology_rounded;
    if (title.contains('디자인')) return Icons.brush_rounded;
    return Icons.work_rounded;
  }

  // 직종별 색상 반환
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        title: const Text(
          '구직 공고',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // 현재 닉네임 표시
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white70, size: 18),
                const SizedBox(width: 4),
                Text(
                  widget.username,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3949AB)),
            )
          : jobs.isEmpty
          ? const Center(
              child: Text('등록된 공고가 없습니다', style: TextStyle(color: Colors.grey)),
            )
          : RefreshIndicator(
              // 아래로 당기면 새로고침
              onRefresh: fetchJobs,
              color: const Color(0xFF3949AB),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  final color = _getJobColor(job['title']);
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
                      // 직종별 아이콘
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getJobIcon(job['title']),
                          color: color,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        job['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            job['company'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 지역 태그
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              job['location'],
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
                            builder: (context) => JobDetailScreen(
                              job: job,
                              username: widget.username,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
