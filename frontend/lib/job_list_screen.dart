import 'dart:convert'; // JSON 파싱용
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP 요청용
import 'chat_screen.dart'; // 채팅 화면

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  // 공고 목록을 저장할 리스트 (처음엔 비어있음)
  List<dynamic> jobs = [];
  // 로딩 중인지 여부
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // 화면이 처음 열릴 때 공고 목록 가져오기
    fetchJobs();
  }

  // 백엔드에서 공고 목록 가져오는 함수
  Future<void> fetchJobs() async {
    try {
      // HTTP GET 요청 → 에뮬레이터에서 10.0.2.2가 PC의 localhost를 가리킴
      // 실제 폰 연결 시에는 PC의 실제 IP로 바꿔야 함 (예: 192.168.x.x)
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/jobs'));

      if (response.statusCode == 200) {
        // 응답 성공 시 JSON 파싱해서 jobs 리스트에 저장
        final data = jsonDecode(response.body);
        setState(() {
          jobs = data['jobs'];
          isLoading = false;
        });
      }
    } catch (e) {
      // 에러 발생 시 (서버 꺼져있거나 네트워크 문제)
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구직 공고'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading
          // 로딩 중일 때 스피너 표시
          ? const Center(child: CircularProgressIndicator())
          // 로딩 완료 시 공고 목록 표시
          : ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    // 공고 제목
                    title: Text(
                      job['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // 회사명 + 지역
                    subtitle: Text('${job['company']} · ${job['location']}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    // 공고 탭하면 채팅 화면으로 이동
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            // 직종을 룸 이름으로 사용
                            room: job['title'],
                          ),
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
