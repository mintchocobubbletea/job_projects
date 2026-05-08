import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'env.dart';

class JobSearchScreen extends StatefulWidget {
  final String username;
  const JobSearchScreen({super.key, required this.username});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  // 현재 선택된 서브탭 (0: 직업탐색, 1: AI 매칭)
  int _tabIndex = 0;

  // 직업정보 전체 목록
  List<Map<String, dynamic>> jobs = [];
  // 검색 필터링된 목록
  List<Map<String, dynamic>> filteredJobs = [];
  bool isLoading = true;

  // 검색창 컨트롤러
  final TextEditingController _searchController = TextEditingController();
  // AI 매칭 입력창 컨트롤러
  final TextEditingController _aiInputController = TextEditingController();
  // AI 매칭 결과
  String aiResult = '';
  bool isAiLoading = false;

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  // 직업정보 API 호출
  Future<void> fetchJobs() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo212L01.do'
          '?authKey=${Env.jobApiKey}'
          '&returnType=XML'
          '&target=JOBCD'
          '&startPage=1'
          '&display=100',
        ),
      );

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
        final items = document.findAllElements('jobList');
        setState(() {
          jobs = items.map((item) {
            return {
              'jobClcdNM': item.findElements('jobClcdNM').isNotEmpty
                  ? item.findElements('jobClcdNM').first.innerText
                  : '',
              'jobCd': item.findElements('jobCd').isNotEmpty
                  ? item.findElements('jobCd').first.innerText
                  : '',
              'jobNm': item.findElements('jobNm').isNotEmpty
                  ? item.findElements('jobNm').first.innerText
                  : '',
            };
          }).toList();
          filteredJobs = jobs;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // 직업명 또는 분류명으로 검색
  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredJobs = jobs;
      } else {
        filteredJobs = jobs.where((job) {
          return job['jobNm'].contains(query) ||
              job['jobClcdNM'].contains(query);
        }).toList();
      }
    });
  }

  // AI 매칭 함수 (API 키 발급 후 구현)
  Future<void> _matchWithAI() async {
    if (_aiInputController.text.isEmpty) return;
    setState(() {
      isAiLoading = true;
      aiResult = '';
    });

    // TODO: Claude API 연동 후 여기에 구현
    // 임시로 로딩 후 안내 메시지 표시
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isAiLoading = false;
      aiResult = 'AI API 연동 준비 중이에요. 곧 서비스될 예정이에요!';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _aiInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        title: const Text(
          '직업탐색',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // 서브탭 (직업탐색 / AI 매칭)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              // 직업탐색 탭
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _tabIndex == 0
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      '직업 검색',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _tabIndex == 0 ? Colors.white : Colors.white60,
                        fontWeight: _tabIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              // AI 매칭 탭
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _tabIndex == 1
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'AI 직업 추천',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _tabIndex == 1 ? Colors.white : Colors.white60,
                        fontWeight: _tabIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _tabIndex == 0 ? _buildJobSearch() : _buildAiMatching(),
    );
  }

  // 직업 검색 화면
  Widget _buildJobSearch() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3949AB)),
      );
    }
    return Column(
      children: [
        // 검색창
        Container(
          color: const Color(0xFF3949AB),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TextField(
            controller: _searchController,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: '직업명 검색 (예: 개발자, 간호사)',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        // 검색 결과 수
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                '총 ${filteredJobs.length}개 직업',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
        // 직업 목록
        Expanded(
          child: RefreshIndicator(
            onRefresh: fetchJobs,
            color: const Color(0xFF3949AB),
            child: filteredJobs.isEmpty
                ? const Center(
                    child: Text(
                      '검색 결과가 없습니다',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = filteredJobs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF3949AB,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.work_outline_rounded,
                              color: Color(0xFF3949AB),
                              size: 20,
                            ),
                          ),
                          // 직업명
                          title: Text(
                            job['jobNm'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          // 직업 분류명
                          subtitle: Text(
                            job['jobClcdNM'],
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // AI 매칭 화면
  Widget _buildAiMatching() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 안내 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
                SizedBox(height: 12),
                Text(
                  'AI 직업 추천',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '관심사와 강점을 입력하면\nAI가 맞는 직업을 추천해드려요',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 입력창
          const Text(
            '관심사 / 강점 입력',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _aiInputController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '예) 컴퓨터와 프로그래밍에 관심이 많고,\n문제 해결하는 것을 좋아합니다.',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF3949AB),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          // AI 매칭 버튼
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isAiLoading ? null : _matchWithAI,
              icon: isAiLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                isAiLoading ? 'AI 분석 중...' : 'AI 직업 추천받기',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3949AB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          // AI 결과 표시
          if (aiResult.isNotEmpty) ...[
            const SizedBox(height: 20),
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
                  const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF3949AB),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'AI 추천 결과',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF3949AB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // AI 결과 텍스트
                  Text(
                    aiResult,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
