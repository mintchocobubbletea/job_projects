// job_detail_screen.dart
// 직업 상세 정보 화면
// 고용24 직업정보 상세 API를 통해 직업의 상세 정보 표시
// 하는 일, 되는 길, 임금, 직업만족도, 전망, 자격증, 관련 직업 등 제공

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'env.dart';

class JobDetailScreen extends StatefulWidget {
  // 직업 코드 (고용24 직업정보 API 파라미터)
  final String jobCd;
  // 직업명 (화면 상단에 표시)
  final String jobNm;
  // 직업 분류명 (태그로 표시)
  final String jobClcdNM;
  // 직업 분류에 따른 테마 색상
  final Color color;

  const JobDetailScreen({
    super.key,
    required this.jobCd,
    required this.jobNm,
    required this.jobClcdNM,
    required this.color,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  // 직업 상세 데이터
  Map<String, dynamic> jobDetail = {};
  bool isLoading = true;
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 직업 상세 데이터 불러오기
    fetchJobDetail();
  }

  // 고용24 직업정보 상세 API 호출
  // dtlGb=1: 요약 정보 (하는일, 되는길, 자격증, 임금, 만족도, 전망 등 포함)
  Future<void> fetchJobDetail() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo212D01.do'
          '?authKey=${Env.jobApiKey}'
          '&returnType=XML'
          '&target=JOBDTL' // 직업 상세 정보 구분자
          '&jobGb=1' // 직업 구분 코드 (1: 일반 직업)
          '&jobCd=${widget.jobCd}' // 직업 코드
          '&dtlGb=1', // 상세 구분 (1: 요약)
        ),
      );

      if (response.statusCode == 200) {
        // XML 응답 파싱
        final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
        final jobSum = document.findAllElements('jobSum').first;

        // 관련 자격증 목록 추출
        final certList = document
            .findAllElements('relCertList')
            .map(
              (e) => e.findElements('certNm').isNotEmpty
                  ? e.findElements('certNm').first.innerText
                  : '',
            )
            .where((e) => e.isNotEmpty)
            .toList();

        // 관련 직업 목록 추출
        final relJobList = document
            .findAllElements('relJobList')
            .map(
              (e) => e.findElements('jobNm').isNotEmpty
                  ? e.findElements('jobNm').first.innerText
                  : '',
            )
            .where((e) => e.isNotEmpty)
            .toList();

        setState(() {
          jobDetail = {
            'jobSum': jobSum.findElements('jobSum').isNotEmpty
                ? jobSum.findElements('jobSum').first.innerText
                : '',
            'way': jobSum.findElements('way').isNotEmpty
                ? jobSum.findElements('way').first.innerText
                : '',
            'sal': jobSum.findElements('sal').isNotEmpty
                ? jobSum.findElements('sal').first.innerText
                : '',
            'jobSatis': jobSum.findElements('jobSatis').isNotEmpty
                ? jobSum.findElements('jobSatis').first.innerText
                : '',
            'jobProspect': jobSum.findElements('jobProspect').isNotEmpty
                ? jobSum.findElements('jobProspect').first.innerText
                : '',
            'jobAbil': jobSum.findElements('jobAbil').isNotEmpty
                ? jobSum.findElements('jobAbil').first.innerText
                : '',
            'knowldg': jobSum.findElements('knowldg').isNotEmpty
                ? jobSum.findElements('knowldg').first.innerText
                : '',
            'jobChr': jobSum.findElements('jobChr').isNotEmpty
                ? jobSum.findElements('jobChr').first.innerText
                : '',
            'jobIntrst': jobSum.findElements('jobIntrst').isNotEmpty
                ? jobSum.findElements('jobIntrst').first.innerText
                : '',
            'jobVals': jobSum.findElements('jobVals').isNotEmpty
                ? jobSum.findElements('jobVals').first.innerText
                : '',
            'certList': certList,
            'relJobList': relJobList,
          };
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = '데이터를 불러오지 못했습니다';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // 상단 헤더 (스크롤 시 접히는 SliverAppBar)
          SliverAppBar(
            expandedHeight: 160,
            pinned: true, // 스크롤 시 상단에 고정
            backgroundColor: widget.color,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: widget.color,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 직업 분류명 태그
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.jobClcdNM,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 직업명
                        Text(
                          widget.jobNm,
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

          // 직업 상세 내용
          SliverToBoxAdapter(
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : errorMsg.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(child: Text(errorMsg)),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 하는 일
                        _buildSection(
                          icon: Icons.work_outline_rounded,
                          title: '하는 일',
                          content: jobDetail['jobSum'] ?? '',
                        ),
                        // 되는 길 (자격/교육/훈련)
                        _buildSection(
                          icon: Icons.school_outlined,
                          title: '되는 길',
                          content: jobDetail['way'] ?? '',
                        ),
                        // 임금 정보
                        _buildSection(
                          icon: Icons.attach_money_rounded,
                          title: '임금',
                          content: jobDetail['sal'] ?? '',
                        ),
                        // 직업만족도 + 일자리전망 (나란히 표시)
                        _buildDoubleSection(
                          icon1: Icons.sentiment_satisfied_outlined,
                          title1: '직업 만족도',
                          content1: '${jobDetail['jobSatis'] ?? ''}%',
                          icon2: Icons.trending_up_rounded,
                          title2: '일자리 전망',
                          content2: jobDetail['jobProspect'] ?? '',
                        ),
                        // 관련 자격증 (없으면 표시 안 함)
                        if ((jobDetail['certList'] as List).isNotEmpty)
                          _buildTagSection(
                            icon: Icons.card_membership_outlined,
                            title: '관련 자격증',
                            tags: jobDetail['certList'] as List<String>,
                            color: widget.color,
                          ),
                        // 업무수행능력
                        _buildSection(
                          icon: Icons.psychology_outlined,
                          title: '업무수행능력',
                          content: jobDetail['jobAbil'] ?? '',
                        ),
                        // 지식
                        _buildSection(
                          icon: Icons.lightbulb_outline_rounded,
                          title: '지식',
                          content: jobDetail['knowldg'] ?? '',
                        ),
                        // 성격
                        _buildSection(
                          icon: Icons.person_outline_rounded,
                          title: '성격',
                          content: jobDetail['jobChr'] ?? '',
                        ),
                        // 흥미
                        _buildSection(
                          icon: Icons.favorite_outline_rounded,
                          title: '흥미',
                          content: jobDetail['jobIntrst'] ?? '',
                        ),
                        // 직업 가치관
                        _buildSection(
                          icon: Icons.star_outline_rounded,
                          title: '직업 가치관',
                          content: jobDetail['jobVals'] ?? '',
                        ),
                        // 관련 직업 (없으면 표시 안 함)
                        if ((jobDetail['relJobList'] as List).isNotEmpty)
                          _buildTagSection(
                            icon: Icons.compare_arrows_rounded,
                            title: '관련 직업',
                            tags: jobDetail['relJobList'] as List<String>,
                            color: widget.color,
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // 일반 정보 섹션 카드 위젯
  // 아이콘 + 제목 + 내용으로 구성
  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    // 내용이 없으면 표시하지 않음
    if (content.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // 직업 분류 테마 색상으로 왼쪽 보더
        border: Border(left: BorderSide(color: widget.color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 섹션 제목 (아이콘 + 텍스트)
            Row(
              children: [
                Icon(icon, size: 18, color: widget.color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: widget.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 섹션 내용
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 두 개 나란히 섹션 위젯
  // 직업만족도와 일자리전망을 가로로 나란히 표시
  Widget _buildDoubleSection({
    required IconData icon1,
    required String title1,
    required String content1,
    required IconData icon2,
    required String title2,
    required String content2,
  }) {
    return Row(
      children: [
        // 좌측 섹션 (직업만족도)
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, right: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: widget.color, width: 3)),
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
                Row(
                  children: [
                    Icon(icon1, size: 16, color: widget.color),
                    const SizedBox(width: 6),
                    Text(
                      title1,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: widget.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content1,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 우측 섹션 (일자리전망)
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, left: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: widget.color, width: 3)),
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
                Row(
                  children: [
                    Icon(icon2, size: 16, color: widget.color),
                    const SizedBox(width: 6),
                    Text(
                      title2,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: widget.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content2,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 태그 형식 섹션 위젯
  // 관련 자격증, 관련 직업 등 여러 항목을 태그로 표시
  Widget _buildTagSection({
    required IconData icon,
    required String title,
    required List<String> tags,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 섹션 제목
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 태그 목록 (Wrap으로 자동 줄바꿈)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
