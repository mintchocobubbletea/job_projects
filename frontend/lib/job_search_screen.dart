// job_search_screen.dart
// 직업탐색 화면
// 두 가지 기능 제공:
// 1. 직업 검색: 고용24 직업정보 API로 직업 목록 조회 및 카테고리 필터링
// 2. AI 직업 추천: 사용자 조건(학력/직업강도/작업장소) + 관심사 입력 시
//    직업사전 API로 조건에 맞는 직업 목록 조회 후 Claude AI가 추천

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'env.dart';
import 'job_detail_screen.dart';

class JobSearchScreen extends StatefulWidget {
  // 로그인한 사용자의 닉네임
  final String username;
  const JobSearchScreen({super.key, required this.username});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  // 현재 선택된 서브탭 (0: 직업 검색, 1: AI 직업 추천)
  int _tabIndex = 0;

  // 직업 카테고리 필터 목록
  // name: 화면에 표시될 카테고리명
  // color: 해당 카테고리 카드 색상
  final List<Map<String, dynamic>> _categories = [
    {'name': '전체', 'color': const Color(0xFF3949AB)},
    {'name': 'IT·소프트웨어', 'color': const Color(0xFF3949AB)},
    {'name': '의료·보건', 'color': const Color(0xFF00897B)},
    {'name': '교육', 'color': const Color(0xFF8E24AA)},
    {'name': '경영·금융', 'color': const Color(0xFFE53935)},
    {'name': '서비스', 'color': const Color(0xFFF57C00)},
    {'name': '제조·생산', 'color': const Color(0xFF546E7A)},
    {'name': '건설', 'color': const Color(0xFF795548)},
    {'name': '농림·어업', 'color': const Color(0xFF43A047)},
  ];

  // 현재 선택된 카테고리 (기본값: 전체)
  String _selectedCategory = '전체';

  // 직업 전체 목록 (API에서 불러온 원본 데이터)
  List<Map<String, dynamic>> jobs = [];
  // 검색/필터링된 직업 목록 (화면에 표시)
  List<Map<String, dynamic>> filteredJobs = [];
  bool isLoading = true;

  // 직업 검색창 컨트롤러
  final TextEditingController _searchController = TextEditingController();
  // AI 매칭 관심사 입력 컨트롤러
  final TextEditingController _aiInputController = TextEditingController();

  // AI 추천 결과 텍스트
  String aiResult = '';
  // AI API 호출 중 여부
  bool isAiLoading = false;

  // AI 매칭 조건 선택값
  String _selectedEduLevel = ''; // 학력
  String _selectedWorkStrong = ''; // 직업강도
  String _selectedWorkPlace = ''; // 작업장소

  // 조건에 맞는 직업 목록 (직업사전 API 결과)
  List<String> _filteredJobNames = [];
  // 직업 목록 로딩 중 여부
  bool _isJobListLoading = false;

  // 학력 선택 옵션
  final List<Map<String, String>> _eduLevels = [
    {'label': '선택 안 함', 'value': ''},
    {'label': '초졸 이하', 'value': '1'},
    {'label': '중졸', 'value': '2'},
    {'label': '고졸', 'value': '3'},
    {'label': '전문대졸', 'value': '4'},
    {'label': '대졸', 'value': '5'},
    {'label': '대학원 이상', 'value': '6'},
  ];

  // 직업강도 선택 옵션
  final List<Map<String, String>> _workStrongs = [
    {'label': '선택 안 함', 'value': ''},
    {'label': '아주 가벼운 작업', 'value': 'SW'},
    {'label': '가벼운 작업', 'value': 'LW'},
    {'label': '보통 작업', 'value': 'MW'},
    {'label': '힘든 작업', 'value': 'HW'},
    {'label': '아주 힘든 작업', 'value': 'VH'},
  ];

  // 작업장소 선택 옵션
  final List<Map<String, String>> _workPlaces = [
    {'label': '선택 안 함', 'value': ''},
    {'label': '실내', 'value': 'I'},
    {'label': '실외', 'value': 'O'},
    {'label': '실내·외', 'value': 'B'},
  ];

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 직업 목록 불러오기
    fetchJobs();
  }

  // 고용24 직업정보 API 호출
  // 직업 목록 조회 (최대 492개)
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
        // XML 응답 파싱
        final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
        final items = document.findAllElements('jobList');
        setState(() {
          jobs = items.map((item) {
            return {
              // 직업 분류명 (카테고리 필터링에 사용)
              'jobClcdNM': item.findElements('jobClcdNM').isNotEmpty
                  ? item.findElements('jobClcdNM').first.innerText
                  : '',
              // 직업 코드 (상세 조회 API 파라미터로 사용)
              'jobCd': item.findElements('jobCd').isNotEmpty
                  ? item.findElements('jobCd').first.innerText
                  : '',
              // 직업명 (화면에 표시)
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

  // 직업명/분류명 검색 + 카테고리 필터 동시 적용
  void _search(String query) {
    setState(() {
      filteredJobs = jobs.where((job) {
        // 카테고리 필터 조건
        final categoryMatch =
            _selectedCategory == '전체' ||
            (_selectedCategory == 'IT·소프트웨어' &&
                (job['jobClcdNM'].contains('소프트웨어') ||
                    job['jobClcdNM'].contains('컴퓨터') ||
                    job['jobClcdNM'].contains('정보') ||
                    job['jobClcdNM'].contains('데이터') ||
                    job['jobClcdNM'].contains('통신공학'))) ||
            (_selectedCategory == '의료·보건' &&
                (job['jobClcdNM'].contains('의사') ||
                    job['jobClcdNM'].contains('간호') ||
                    job['jobClcdNM'].contains('보건') ||
                    job['jobClcdNM'].contains('의료') ||
                    job['jobClcdNM'].contains('약사') ||
                    job['jobClcdNM'].contains('수의사'))) ||
            (_selectedCategory == '교육' &&
                (job['jobClcdNM'].contains('교사') ||
                    job['jobClcdNM'].contains('교수') ||
                    job['jobClcdNM'].contains('강사') ||
                    job['jobClcdNM'].contains('교육'))) ||
            (_selectedCategory == '경영·금융' &&
                (job['jobClcdNM'].contains('경영') ||
                    job['jobClcdNM'].contains('금융') ||
                    job['jobClcdNM'].contains('보험') ||
                    job['jobClcdNM'].contains('회계') ||
                    job['jobClcdNM'].contains('세무'))) ||
            (_selectedCategory == '서비스' &&
                (job['jobClcdNM'].contains('서비스') ||
                    job['jobClcdNM'].contains('미용') ||
                    job['jobClcdNM'].contains('여행') ||
                    job['jobClcdNM'].contains('숙박') ||
                    job['jobClcdNM'].contains('식당') ||
                    job['jobClcdNM'].contains('조리'))) ||
            (_selectedCategory == '제조·생산' &&
                (job['jobClcdNM'].contains('제조') ||
                    job['jobClcdNM'].contains('생산') ||
                    job['jobClcdNM'].contains('조작원') ||
                    job['jobClcdNM'].contains('조립원') ||
                    job['jobClcdNM'].contains('기계'))) ||
            (_selectedCategory == '건설' &&
                (job['jobClcdNM'].contains('건설') ||
                    job['jobClcdNM'].contains('건축') ||
                    job['jobClcdNM'].contains('배관') ||
                    job['jobClcdNM'].contains('전기공'))) ||
            (_selectedCategory == '농림·어업' &&
                (job['jobClcdNM'].contains('작물') ||
                    job['jobClcdNM'].contains('농업') ||
                    job['jobClcdNM'].contains('임업') ||
                    job['jobClcdNM'].contains('어업') ||
                    job['jobClcdNM'].contains('낙농')));

        // 검색어 필터 조건
        final searchMatch =
            query.isEmpty ||
            job['jobNm'].contains(query) ||
            job['jobClcdNM'].contains(query);

        // 카테고리와 검색어 모두 충족하는 직업만 표시
        return categoryMatch && searchMatch;
      }).toList();
    });
  }

  // 카테고리 선택 처리
  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      // 카테고리 변경 시 현재 검색어로 재필터링
      _search(_searchController.text);
    });
  }

  // 직업 분류명에 따른 카드 색상 반환
  Color _getJobColor(String category) {
    if (category.contains('소프트웨어') ||
        category.contains('컴퓨터') ||
        category.contains('정보') ||
        category.contains('데이터') ||
        category.contains('통신공학')) {
      return const Color(0xFF3949AB);
    }
    if (category.contains('의사') ||
        category.contains('간호') ||
        category.contains('보건') ||
        category.contains('의료') ||
        category.contains('약사') ||
        category.contains('수의사')) {
      return const Color(0xFF00897B);
    }
    if (category.contains('교사') ||
        category.contains('교수') ||
        category.contains('강사') ||
        category.contains('교육')) {
      return const Color(0xFF8E24AA);
    }
    if (category.contains('경영') ||
        category.contains('금융') ||
        category.contains('보험') ||
        category.contains('회계') ||
        category.contains('세무')) {
      return const Color(0xFFE53935);
    }
    if (category.contains('서비스') ||
        category.contains('미용') ||
        category.contains('여행') ||
        category.contains('숙박') ||
        category.contains('식당') ||
        category.contains('조리')) {
      return const Color(0xFFF57C00);
    }
    if (category.contains('제조') ||
        category.contains('생산') ||
        category.contains('조작원') ||
        category.contains('조립원') ||
        category.contains('기계')) {
      return const Color(0xFF546E7A);
    }
    if (category.contains('건설') ||
        category.contains('건축') ||
        category.contains('배관') ||
        category.contains('전기공')) {
      return const Color(0xFF795548);
    }
    if (category.contains('작물') ||
        category.contains('농업') ||
        category.contains('임업') ||
        category.contains('어업') ||
        category.contains('낙농')) {
      return const Color(0xFF43A047);
    }
    return const Color(0xFF3949AB);
  }

  // 고용24 직업사전 API 호출
  // 선택한 조건(학력/직업강도/작업장소)에 맞는 직업 목록 조회
  Future<void> _fetchFilteredJobs() async {
    // 최소 하나 이상 조건 선택 확인
    if (_selectedEduLevel.isEmpty &&
        _selectedWorkStrong.isEmpty &&
        _selectedWorkPlace.isEmpty) {
      return;
    }

    setState(() => _isJobListLoading = true);

    try {
      // 선택된 조건으로 srchType과 파라미터 조합
      List<String> srchTypes = [];
      String params = '';

      if (_selectedEduLevel.isNotEmpty) {
        srchTypes.add('EL');
        params += '&eduLevel=$_selectedEduLevel';
      }
      if (_selectedWorkStrong.isNotEmpty) {
        srchTypes.add('WS');
        params += '&workStrong=$_selectedWorkStrong';
      }
      if (_selectedWorkPlace.isNotEmpty) {
        srchTypes.add('WP');
        params += '&workPlace=$_selectedWorkPlace';
      }

      // srchType을 여러 번 넘기는 방식으로 다중 조건 처리
      String srchTypeParams = srchTypes.map((t) => 'srchType=$t').join('&');

      final response = await http.get(
        Uri.parse(
          'https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo212L50.do'
          '?authKey=${Env.jobApiKey}'
          '&returnType=XML'
          '&startPage=1'
          '&display=50'
          '&target=dJobCD'
          '&$srchTypeParams'
          '$params',
        ),
      );

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
        final items = document.findAllElements('dJobList');
        setState(() {
          // 직업명만 추출하여 목록 생성 (최대 50개)
          _filteredJobNames = items
              .map(
                (e) => e.findElements('dJobNm').isNotEmpty
                    ? e.findElements('dJobNm').first.innerText
                    : '',
              )
              .where((e) => e.isNotEmpty)
              .toList();
          _isJobListLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isJobListLoading = false);
    }
  }

  // Claude AI API 호출
  // 조건에 맞는 직업 목록과 사용자 관심사를 AI에게 전달하여 직업 추천
  Future<void> _matchWithAI() async {
    if (_aiInputController.text.isEmpty) return;

    // 직업 목록을 먼저 불러와야 함
    if (_filteredJobNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('조건을 선택하고 직업 목록을 먼저 불러와주세요')),
      );
      return;
    }

    setState(() {
      isAiLoading = true;
      aiResult = '';
    });

    try {
      // 직업 목록을 텍스트로 변환 (최대 30개)
      final jobListText = _filteredJobNames.take(30).join(', ');

      // Claude AI API 호출
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': Env.claudeApiKey, // Claude API 키
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-5',
          'max_tokens': 1000,
          'messages': [
            {
              'role': 'user',
              'content':
                  '''
당신은 취업 전문 AI 상담사입니다.
아래 조건에 맞는 직업 목록 중에서 사용자의 관심사와 강점에 맞는 직업을 3가지 추천해주세요.

[선택된 조건]
${_selectedEduLevel.isNotEmpty ? '학력: ${_eduLevels.firstWhere((e) => e['value'] == _selectedEduLevel)['label']}' : ''}
${_selectedWorkStrong.isNotEmpty ? '직업강도: ${_workStrongs.firstWhere((e) => e['value'] == _selectedWorkStrong)['label']}' : ''}
${_selectedWorkPlace.isNotEmpty ? '작업장소: ${_workPlaces.firstWhere((e) => e['value'] == _selectedWorkPlace)['label']}' : ''}

[조건에 맞는 직업 목록]
$jobListText

[사용자 관심사/강점]
${_aiInputController.text}

위 직업 목록 중에서만 추천해주세요. 다음 형식으로 답변해주세요:

1. [직업명]
- 추천 이유: (2-3문장)
- 이 직업이 맞는 이유: (사용자 관심사와 연결)

2. [직업명]
- 추천 이유: (2-3문장)
- 이 직업이 맞는 이유: (사용자 관심사와 연결)

3. [직업명]
- 추천 이유: (2-3문장)
- 이 직업이 맞는 이유: (사용자 관심사와 연결)

한국어로 답변해주세요.
              ''',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // AI 응답에서 텍스트 추출
        final text = data['content'][0]['text'];
        setState(() {
          aiResult = text;
          isAiLoading = false;
        });
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          aiResult = '오류: ${errorData.toString()}';
          isAiLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        aiResult = '서버에 연결할 수 없습니다.';
        isAiLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // 화면 종료 시 컨트롤러 해제 (메모리 누수 방지)
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
        // 타이틀 영역 숨김 (main_screen.dart의 공통 앱바 사용)
        toolbarHeight: 0,
        // 서브탭 (직업 검색 / AI 직업 추천)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [_buildSubTab('직업 검색', 0), _buildSubTab('AI 직업 추천', 1)],
          ),
        ),
      ),
      body: _tabIndex == 0 ? _buildJobSearch() : _buildAiMatching(),
    );
  }

  // 서브탭 위젯 (직업 검색 / AI 직업 추천 전환)
  Widget _buildSubTab(String title, int index) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              // 선택된 탭은 흰색 하단 보더 표시
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
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
        // 검색창 + 카테고리 필터 영역
        Container(
          color: const Color(0xFF3949AB),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // 직업명 검색창
              TextField(
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
              const SizedBox(height: 10),
              // 카테고리 필터 가로 스크롤 목록
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['name'];
                    return GestureDetector(
                      onTap: () => _selectCategory(cat['name']),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          // 선택된 카테고리는 흰색, 미선택은 반투명
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          cat['name'],
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF3949AB)
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // 검색 결과 수 표시
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text(
                '총 ${filteredJobs.length}개 직업',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(width: 6),
              // 전체 목록일 때 데이터 출처 안내
              if (filteredJobs.length == jobs.length)
                Text(
                  '(고용24 직업정보 API 기준)',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
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
                      final color = _getJobColor(job['jobClcdNM']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          // 직업 분류에 따른 색상으로 왼쪽 보더
                          border: Border(
                            left: BorderSide(color: color, width: 3),
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
                            vertical: 6,
                          ),
                          // 직업 분류 아이콘
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.work_outline_rounded,
                              color: color,
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
                          // 직업 분류명 태그
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                job['jobClcdNM'],
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          isThreeLine: false,
                          // 직업 카드 탭 시 상세 화면으로 이동
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobDetailScreen(
                                  jobCd: job['jobCd'],
                                  jobNm: job['jobNm'],
                                  jobClcdNM: job['jobClcdNM'],
                                  color: color,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // AI 직업 추천 화면
  Widget _buildAiMatching() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 안내 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3949AB),
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
                  '조건을 선택하고 관심사를 입력하면\nAI가 맞는 직업을 추천해드려요',
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

          // 조건 선택 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: Color(0xFF3949AB), width: 3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '조건 선택',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF3949AB),
                  ),
                ),
                const SizedBox(height: 16),
                // 학력 선택 드롭다운
                _buildDropdown(
                  label: '학력',
                  icon: Icons.school_outlined,
                  value: _selectedEduLevel,
                  items: _eduLevels,
                  onChanged: (value) =>
                      setState(() => _selectedEduLevel = value ?? ''),
                ),
                const SizedBox(height: 12),
                // 직업강도 선택 드롭다운
                _buildDropdown(
                  label: '직업강도',
                  icon: Icons.fitness_center_outlined,
                  value: _selectedWorkStrong,
                  items: _workStrongs,
                  onChanged: (value) =>
                      setState(() => _selectedWorkStrong = value ?? ''),
                ),
                const SizedBox(height: 12),
                // 작업장소 선택 드롭다운
                _buildDropdown(
                  label: '작업장소',
                  icon: Icons.location_on_outlined,
                  value: _selectedWorkPlace,
                  items: _workPlaces,
                  onChanged: (value) =>
                      setState(() => _selectedWorkPlace = value ?? ''),
                ),
                const SizedBox(height: 16),
                // 조건에 맞는 직업 목록 불러오기 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isJobListLoading
                        ? null
                        : () async {
                            await _fetchFilteredJobs();
                            if (_filteredJobNames.isNotEmpty && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${_filteredJobNames.length}개 직업을 불러왔어요',
                                  ),
                                  backgroundColor: const Color(0xFF3949AB),
                                ),
                              );
                            }
                          },
                    icon: _isJobListLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF3949AB),
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(
                      _isJobListLoading
                          ? '직업 목록 불러오는 중...'
                          : _filteredJobNames.isEmpty
                          ? '조건에 맞는 직업 목록 불러오기'
                          : '${_filteredJobNames.length}개 직업 불러옴 (재검색)',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3949AB),
                      side: const BorderSide(color: Color(0xFF3949AB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 관심사/강점 입력
          const Text(
            '관심사 / 강점 입력',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _aiInputController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '예) 사람들과 소통하는 것을 좋아하고\n꼼꼼한 성격입니다.',
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

          // AI 직업 추천 버튼
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

          // AI 추천 결과 표시
          if (aiResult.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: const Border(
                  left: BorderSide(color: Color(0xFF3949AB), width: 3),
                ),
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
                  // AI 추천 결과 텍스트
                  Text(
                    aiResult,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            ),
          ],

          // 조건에 맞는 직업 목록 표시
          if (_filteredJobNames.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: const Border(
                  left: BorderSide(color: Color(0xFF00897B), width: 3),
                ),
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
                  // 직업 목록 제목
                  Row(
                    children: [
                      const Icon(
                        Icons.list_rounded,
                        color: Color(0xFF00897B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '조건에 맞는 직업 (${_filteredJobNames.length}개)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF00897B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 직업명 태그 목록
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filteredJobNames
                        .map(
                          (jobName) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF00897B,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              jobName,
                              style: const TextStyle(
                                color: Color(0xFF00897B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  // 검색 결과 제한 안내
                  Text(
                    '※ 검색 결과는 최대 50개까지 확인 가능합니다',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 드롭다운 선택 위젯
  Widget _buildDropdown({
    required String label, // 드롭다운 라벨
    required IconData icon, // 좌측 아이콘
    required String value, // 현재 선택값
    required List<Map<String, String>> items, // 선택 옵션 목록
    required Function(String?) onChanged, // 선택 변경 콜백
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨 + 아이콘
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF3949AB)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3949AB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 드롭다운 버튼
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3949AB), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item['value'],
                  child: Text(item['label']!),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
