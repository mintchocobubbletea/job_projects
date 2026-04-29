import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class JobInfoScreen extends StatefulWidget {
  const JobInfoScreen({super.key});

  @override
  State<JobInfoScreen> createState() => _JobInfoScreenState();
}

class _JobInfoScreenState extends State<JobInfoScreen> {
  List<Map<String, dynamic>> jobs = [];
  bool isLoading = true;
  String errorMsg = '';
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchJobs() async {
    setState(() {
      isLoading = true;
      errorMsg = '';
    });

    try {
      final queryParams = {
        'authKey': '40ead606-39be-4a5e-af2f-56f4eb8a2da8',
        'returnType': 'XML',
        'target': 'JOBCD',
        if (_keyword.isNotEmpty) 'jobNm': _keyword,
      };

      final uri = Uri.parse(
        'https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo212L01.do',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(body);

        final items = document.findAllElements('jobList');

        String safeText(XmlElement item, String tag) {
          final els = item.findElements(tag);
          return els.isNotEmpty ? els.first.innerText : '';
        }

        setState(() {
          jobs = items.map((item) {
            return {
              'jobCd': safeText(item, 'jobCd'),
              'jobNm': safeText(item, 'jobNm'),
              'jobClcdNM': safeText(item, 'jobClcdNM'), // 직업 대분류명
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMsg = '서버 오류: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = '데이터를 불러오지 못했습니다: $e';
        isLoading = false;
      });
    }
  }

  void _onSearch() {
    _keyword = _searchController.text.trim();
    fetchJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        title: const Text(
          '직업정보',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 검색바
          Container(
            color: const Color(0xFF3949AB),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '직업명 검색',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : _onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3949AB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('검색'),
                ),
              ],
            ),
          ),

          // 본문
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3949AB)),
                  )
                : errorMsg.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(errorMsg, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: fetchJobs,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  )
                : jobs.isEmpty
                ? const Center(child: Text('검색 결과가 없습니다.'))
                : RefreshIndicator(
                    onRefresh: fetchJobs,
                    color: const Color(0xFF3949AB),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        return _JobCard(
                          job: job,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobInfoDetailScreen(
                                jobCd: job['jobCd'] ?? '',
                                jobNm: job['jobNm'] ?? '',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── 직업 카드 ────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          job['jobNm'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: (job['jobClcdNM'] ?? '').isNotEmpty
            ? Text(
                job['jobClcdNM'],
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 직업정보 상세 화면
// ═══════════════════════════════════════════════════════

class JobInfoDetailScreen extends StatefulWidget {
  final String jobCd;
  final String jobNm;

  const JobInfoDetailScreen({
    super.key,
    required this.jobCd,
    required this.jobNm,
  });

  @override
  State<JobInfoDetailScreen> createState() => _JobInfoDetailScreenState();
}

class _JobInfoDetailScreenState extends State<JobInfoDetailScreen> {
  Map<String, dynamic>? detail;
  bool isLoading = true;
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  // dtlGb별 API 1회 호출 후 XmlDocument 반환 (루트 태그명이 섹션마다 달라서 문서 전체로 반환)
  Future<XmlDocument?> _fetchSection(String dtlGb) async {
    final uri =
        Uri.parse(
          'https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo212D01.do',
        ).replace(
          queryParameters: {
            'authKey': '40ead606-39be-4a5e-af2f-56f4eb8a2da8',
            'returnType': 'XML',
            'target': 'JOBDTL',
            'jobGb': '1',
            'jobCd': widget.jobCd,
            'dtlGb': dtlGb,
          },
        );
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    return XmlDocument.parse(utf8.decode(response.bodyBytes));
  }

  Future<void> fetchDetail() async {
    setState(() {
      isLoading = true;
      errorMsg = '';
    });

    try {
      // dtlGb 1~7 전체 병렬 호출
      final results = await Future.wait([
        _fetchSection('1'), // 요약
        _fetchSection('2'), // 하는 일
        _fetchSection('3'), // 교육/자격/훈련
        _fetchSection('4'), // 임금/직업만족도/전망
        _fetchSection('5'), // 능력/지식/환경
        _fetchSection('6'), // 성격/흥미/가치관
        _fetchSection('7'), // 업무활동
      ]);

      // ── 헬퍼 함수 ──────────────────────────────────────────────────────
      // 문서 전체를 재귀 탐색해서 특정 태그의 첫 번째 innerText를 반환.
      // 루트 태그명이 dtlGb마다 다르기 때문에(jobSum, salProspect 등)
      // 루트에 의존하지 않고 findAllElements로 전체 문서를 검색한다.
      String safeText(XmlDocument? doc, String tag) {
        if (doc == null) return '';
        final els = doc.findAllElements(tag);
        return els.isNotEmpty ? els.first.innerText.trim() : '';
      }

      // 반복되는 리스트 태그(itemTag) 안의 특정 필드(nameTag)를 모두 모아
      // 쉼표로 연결한 문자열로 반환.
      // 예) relMajorList > majorNm → "경영학, 행정학, 법학"
      String joinList(XmlDocument? doc, String itemTag, String nameTag) {
        if (doc == null) return '';
        return doc
            .findAllElements(itemTag)
            .map((e) {
              final els = e.findElements(nameTag);
              return els.isNotEmpty ? els.first.innerText.trim() : '';
            })
            .where((s) => s.isNotEmpty)
            .join(', ');
      }

      // dtlGb=4 응답의 <jobSumProspect> 블록들을 파싱해서
      // "증가 7% · 다소 증가 12% · 유지 44% ..." 형태 문자열로 변환.
      // <jobStatus>는 jobCd/jobNm만 들어있는 참조 태그라 표시 불필요 → 미사용.
      String formatProspectRatios(XmlDocument? doc) {
        if (doc == null) return '';
        final items = doc.findAllElements('jobSumProspect');
        return items
            .map((e) {
              final nm = e.findElements('jobProspectNm');
              final ratio = e.findElements('jobProspectRatio');
              if (nm.isEmpty || ratio.isEmpty) return '';
              return '${nm.first.innerText.trim()} ${ratio.first.innerText.trim()}%';
            })
            .where((s) => s.isNotEmpty)
            .join(' · ');
      }

      // 각 섹션별 응답 문서 분리
      final sec1 = results[0]; // dtlGb=1 : 요약
      final sec2 = results[1]; // dtlGb=2 : 하는 일(상세)
      final sec3 = results[2]; // dtlGb=3 : 교육/자격/훈련
      final sec4 = results[3]; // dtlGb=4 : 임금/직업만족도/전망
      final sec5 = results[4]; // dtlGb=5 : 능력/지식/환경
      final sec6 = results[5]; // dtlGb=6 : 성격/흥미/가치관
      final sec7 = results[6]; // dtlGb=7 : 업무활동

      setState(() {
        detail = {
          // ── 1. 요약 ──────────────────────────────────────────────
          'jobLrclNm': safeText(sec1, 'jobLrclNm'), // 직업 대분류명
          'jobMdclNm': safeText(sec1, 'jobMdclNm'), // 직업 중분류명
          'jobSmclNm': safeText(sec1, 'jobSmclNm'), // 직업 소분류명
          'jobSum': safeText(sec1, 'jobSum'), // 하는 일 요약
          'way': safeText(sec1, 'way'), // 되는 길
          // relJobList 안의 jobNm을 쉼표로 합쳐 관련직업 문자열 생성
          'relJobs': joinList(sec1, 'relJobList', 'jobNm'),

          // ── 2. 하는 일 (상세) ─────────────────────────────────────
          // dtlGb=2도 응답 태그명이 jobSum이라 safeText로 추출
          'work': safeText(sec2, 'jobSum'),

          // ── 3. 교육/자격/훈련 ─────────────────────────────────────
          // relMajorList > majorNm : 관련 전공명 목록
          'majors': joinList(sec3, 'relMajorList', 'majorNm'),
          // relCertList > certNm : 관련 자격증명 목록
          'certs': joinList(sec3, 'relCertList', 'certNm'),

          // ── 4. 임금/직업만족도/전망 ───────────────────────────────
          'sal': safeText(sec4, 'sal'), // 임금 정보
          'jobSatis': safeText(sec4, 'jobSatis'), // 직업만족도(%)
          'jobProspect': safeText(sec4, 'jobProspect'), // 일자리 전망 본문
          // jobSumProspect 블록들을 파싱해 "증가 7% · 유지 44%..." 형태로 변환
          // ※ jobStatus 태그는 jobCd/jobNm 참조값만 있어 표시 불필요
          'prospectRatios': formatProspectRatios(sec4),

          // ── 5. 능력/지식/환경 ─────────────────────────────────────
          'jobAbil': safeText(sec5, 'jobAbil'), // 업무수행능력
          'knowldg': safeText(sec5, 'knowldg'), // 지식
          'jobEnv': safeText(sec5, 'jobEnv'), // 업무환경
          // ── 6. 성격/흥미/가치관 ───────────────────────────────────
          'jobChr': safeText(sec6, 'jobChr'), // 성격
          'jobIntrst': safeText(sec6, 'jobIntrst'), // 흥미
          'jobVals': safeText(sec6, 'jobVals'), // 직업가치관
          // ── 7. 업무활동 ───────────────────────────────────────────
          'jobActvImprtncs': safeText(sec7, 'jobActvImprtncs'), // 업무활동 중요도
          'jobActvLvls': safeText(sec7, 'jobActvLvls'), // 업무활동 수준
        };
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = '데이터를 불러오지 못했습니다: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        title: Text(widget.jobNm),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3949AB)),
            )
          : errorMsg.isNotEmpty
          ? Center(child: Text(errorMsg))
          : detail == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 분류 칩
                  if ((detail!['jobLrclNm'] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          _Chip(detail!['jobLrclNm']),
                          if ((detail!['jobMdclNm'] ?? '').isNotEmpty)
                            _Chip(detail!['jobMdclNm']),
                          if ((detail!['jobSmclNm'] ?? '').isNotEmpty)
                            _Chip(detail!['jobSmclNm']),
                        ],
                      ),
                    ),
                  _SectionCard(
                    title: '하는 일',
                    content: detail!['work'] ?? detail!['jobSum'] ?? '',
                  ),
                  _SectionCard(title: '되는 길', content: detail!['way'] ?? ''),
                  _SectionCard(title: '관련전공', content: detail!['majors'] ?? ''),
                  _SectionCard(title: '관련자격증', content: detail!['certs'] ?? ''),
                  _SectionCard(title: '임금', content: detail!['sal'] ?? ''),
                  // 직업만족도 뒤에 % 단위 표시
                  _SectionCard(
                    title: '직업만족도',
                    content: (detail!['jobSatis'] ?? '').isNotEmpty
                        ? '${detail!['jobSatis']}%'
                        : '',
                  ),
                  _SectionCard(
                    title: '일자리 전망',
                    content: detail!['jobProspect'] ?? '',
                  ),
                  // jobSumProspect 블록에서 파싱한 전망 비율 (예: 증가 7% · 유지 44%)
                  _SectionCard(
                    title: '전망 비율',
                    content: detail!['prospectRatios'] ?? '',
                  ),
                  _SectionCard(
                    title: '업무수행능력',
                    content: detail!['jobAbil'] ?? '',
                  ),
                  _SectionCard(title: '지식', content: detail!['knowldg'] ?? ''),
                  _SectionCard(title: '업무환경', content: detail!['jobEnv'] ?? ''),
                  _SectionCard(title: '성격', content: detail!['jobChr'] ?? ''),
                  _SectionCard(
                    title: '흥미',
                    content: detail!['jobIntrst'] ?? '',
                  ),
                  _SectionCard(
                    title: '직업가치관',
                    content: detail!['jobVals'] ?? '',
                  ),
                  _SectionCard(
                    title: '업무활동 중요도',
                    content: detail!['jobActvImprtncs'] ?? '',
                  ),
                  _SectionCard(
                    title: '업무활동 수준',
                    content: detail!['jobActvLvls'] ?? '',
                  ),
                  _SectionCard(
                    title: '관련직업',
                    content: detail!['relJobs'] ?? '',
                  ),
                ],
              ),
            ),
    );
  }
}

// ─── 분류 칩 ─────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3949AB).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF3949AB),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── 섹션 카드 ────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String content;

  const _SectionCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF3949AB),
              ),
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(height: 1.5, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
