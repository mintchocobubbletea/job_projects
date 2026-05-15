import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:url_launcher/url_launcher.dart';
import 'env.dart';

class ProgramScreen extends StatefulWidget {
  final String username;
  const ProgramScreen({super.key, required this.username});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  // 현재 선택된 서브탭 (0: 취업역량 강화프로그램, 1: 국민내일배움카드)
  int _tabIndex = 0;

  // 취업역량 강화프로그램 데이터
  List<Map<String, dynamic>> empPrograms = [];
  bool isLoadingEmp = true;

  // 국민내일배움카드 훈련과정 데이터
  List<Map<String, dynamic>> hrdCourses = [];
  bool isLoadingHrd = true;

  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    // 두 API 동시 호출
    fetchEmpPrograms();
    fetchHrdCourses();
  }

  // 취업역량 강화프로그램 API 호출
  Future<void> fetchEmpPrograms() async {
    try {
      // 어제 날짜부터 조회
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr =
          '${yesterday.year}'
          '${yesterday.month.toString().padLeft(2, '0')}'
          '${yesterday.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse(
          'https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo217L01.do'
          '?authKey=${Env.empApiKey}'
          '&returnType=XML'
          '&startPage=1'
          '&display=20'
          '&pgmStdt=$dateStr',
        ),
      );

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
        final items = document.findAllElements('empPgmSchdInvite');
        setState(() {
          empPrograms = items.map((item) {
            return {
              'orgNm': item.findElements('orgNm').isNotEmpty
                  ? item.findElements('orgNm').first.innerText
                  : '',
              'pgmNm': item.findElements('pgmNm').isNotEmpty
                  ? item.findElements('pgmNm').first.innerText
                  : '',
              'pgmSubNm': item.findElements('pgmSubNm').isNotEmpty
                  ? item.findElements('pgmSubNm').first.innerText
                  : '',
              'pgmTarget': item.findElements('pgmTarget').isNotEmpty
                  ? item.findElements('pgmTarget').first.innerText
                  : '제한없음',
              'pgmStdt': item.findElements('pgmStdt').isNotEmpty
                  ? item.findElements('pgmStdt').first.innerText
                  : '',
              'pgmEndt': item.findElements('pgmEndt').isNotEmpty
                  ? item.findElements('pgmEndt').first.innerText
                  : '',
              'openTime': item.findElements('openTime').isNotEmpty
                  ? item.findElements('openTime').first.innerText
                  : '',
              'openTimeClcd': item.findElements('openTimeClcd').isNotEmpty
                  ? item.findElements('openTimeClcd').first.innerText
                  : '',
              'openPlcCont': item.findElements('openPlcCont').isNotEmpty
                  ? item.findElements('openPlcCont').first.innerText
                  : '',
            };
          }).toList();
          isLoadingEmp = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = '데이터를 불러오지 못했습니다';
        isLoadingEmp = false;
      });
    }
  }

  // 국민내일배움카드 훈련과정 API 호출
  Future<void> fetchHrdCourses() async {
    try {
      final now = DateTime.now();
      final start =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final end =
          '${now.year + 1}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse(
          'https://www.work24.go.kr/cm/openApi/call/hr/callOpenApiSvcInfo310L01.do'
          '?authKey=${Env.hrdApiKey}'
          '&returnType=XML'
          '&outType=1'
          '&pageNum=1'
          '&pageSize=20'
          '&srchTraStDt=$start'
          '&srchTraEndDt=$end'
          '&sort=DESC'
          '&sortCol=2',
        ),
      );

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
        final items = document.findAllElements('scn_list');
        setState(() {
          hrdCourses = items.map((item) {
            return {
              'title': item.findElements('title').isNotEmpty
                  ? item.findElements('title').first.innerText
                  : '',
              'subTitle': item.findElements('subTitle').isNotEmpty
                  ? item.findElements('subTitle').first.innerText
                  : '',
              'address': item.findElements('address').isNotEmpty
                  ? item.findElements('address').first.innerText
                  : '',
              'trainTarget': item.findElements('trainTarget').isNotEmpty
                  ? item.findElements('trainTarget').first.innerText
                  : '',
              'traStartDate': item.findElements('traStartDate').isNotEmpty
                  ? item.findElements('traStartDate').first.innerText
                  : '',
              'traEndDate': item.findElements('traEndDate').isNotEmpty
                  ? item.findElements('traEndDate').first.innerText
                  : '',
              'realMan': item.findElements('realMan').isNotEmpty
                  ? item.findElements('realMan').first.innerText
                  : '0',
              'certificate': item.findElements('certificate').isNotEmpty
                  ? item.findElements('certificate').first.innerText
                  : '',
              'titleLink': item.findElements('titleLink').isNotEmpty
                  ? item.findElements('titleLink').first.innerText
                  : '',
            };
          }).toList();
          isLoadingHrd = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = '데이터를 불러오지 못했습니다';
        isLoadingHrd = false;
      });
    }
  }

  // URL 열기
  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // 날짜 포맷 (20260430 → 2026.04.30)
  String formatDate(String date) {
    if (date.length != 8) return date;
    return '${date.substring(0, 4)}.${date.substring(4, 6)}.${date.substring(6, 8)}';
  }

  // 오전/오후 변환
  String formatTime(String clcd, String time) {
    final ampm = clcd == '1' ? '오전' : '오후';
    return '$ampm $time';
  }

  // 수강비 포맷 (800000 → 800,000원)
  String formatMoney(String money) {
    if (money.isEmpty || money == '0') return '무료';
    try {
      final amount = int.parse(money);
      if (amount == 0) return '무료';
      return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
    } catch (e) {
      return money;
    }
  }

  // 서브탭 위젯
  Widget _buildSubTab(String title, int index) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        toolbarHeight: 0, // 타이틀 영역 숨김
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [_buildSubTab('취업 프로그램', 0), _buildSubTab('내일배움카드', 1)],
          ),
        ),
      ),
      body: _tabIndex == 0 ? _buildEmpPrograms() : _buildHrdCourses(),
    );
  }

  // 취업역량 강화프로그램 목록
  Widget _buildEmpPrograms() {
    if (isLoadingEmp) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3949AB)),
      );
    }
    if (empPrograms.isEmpty) {
      return const Center(
        child: Text('오늘 등록된 프로그램이 없습니다', style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: fetchEmpPrograms,
      color: const Color(0xFF3949AB),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: empPrograms.length,
        itemBuilder: (context, index) {
          final p = empPrograms[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              // 왼쪽 컬러 보더
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로그램 유형 + 기관명
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3949AB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p['pgmNm'],
                          style: const TextStyle(
                            color: Color(0xFF3949AB),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p['orgNm'],
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 세부 프로그램명
                  Text(
                    p['pgmSubNm'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 대상자
                  if (p['pgmTarget'].isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p['pgmTarget'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  // 날짜 + 시간
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${formatDate(p['pgmStdt'])} '
                        '${formatTime(p['openTimeClcd'], p['openTime'])}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 장소
                  if (p['openPlcCont'].isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p['openPlcCont'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 국민내일배움카드 훈련과정 목록
  Widget _buildHrdCourses() {
    if (isLoadingHrd) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3949AB)),
      );
    }
    if (hrdCourses.isEmpty) {
      return const Center(
        child: Text('훈련과정이 없습니다', style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: fetchHrdCourses,
      color: const Color(0xFF3949AB),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: hrdCourses.length,
        itemBuilder: (context, index) {
          final c = hrdCourses[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              // 내일배움카드는 초록 왼쪽 보더
              border: const Border(
                left: BorderSide(color: Color(0xFF00897B), width: 3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _launchUrl(c['titleLink']),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 훈련과정명
                    Text(
                      c['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 훈련기관명
                    Text(
                      c['subTitle'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 자격증 연계
                    if (c['certificate'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.card_membership_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              c['certificate'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        // 훈련대상 태그
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF00897B,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c['trainTarget'],
                            style: const TextStyle(
                              color: Color(0xFF00897B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // 수강비
                        Text(
                          formatMoney(c['realMan']),
                          style: const TextStyle(
                            color: Color(0xFF3949AB),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 훈련기간
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${c['traStartDate']} ~ ${c['traEndDate']}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 주소
                    if (c['address'].isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c['address'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
