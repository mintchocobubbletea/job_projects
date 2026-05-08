import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:url_launcher/url_launcher.dart';
import 'env.dart';

class RecruitmentScreen extends StatefulWidget {
  final String username;
  const RecruitmentScreen({super.key, required this.username});

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  // 공채 전체 목록
  List<Map<String, dynamic>> recruitments = [];
  // 검색 필터링된 목록
  List<Map<String, dynamic>> filteredRecruitments = [];
  bool isLoading = true;
  String errorMsg = '';
  // 검색창 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRecruitments();
  }

  Future<void> fetchRecruitments() async {
    try {
      // 고용24 공채속보 API 호출
      final response = await http.get(
        Uri.parse(
          'https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo210L21.do'
          '?authKey=${Env.recruitApiKey}'
          '&callTp=L'
          '&returnType=XML'
          '&startPage=1'
          '&display=50'
          '&sortField=regDt'
          '&sortOrderBy=desc',
        ),
      );

      if (response.statusCode == 200) {
        // XML 파싱
        final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
        final items = document.findAllElements('dhsOpenEmpInfo');
        setState(() {
          recruitments = items.map((item) {
            return {
              'empWantedTitle': item.findElements('empWantedTitle').isNotEmpty
                  ? item.findElements('empWantedTitle').first.innerText
                  : '',
              'empBusiNm': item.findElements('empBusiNm').isNotEmpty
                  ? item.findElements('empBusiNm').first.innerText
                  : '',
              'coClcdNm': item.findElements('coClcdNm').isNotEmpty
                  ? item.findElements('coClcdNm').first.innerText
                  : '',
              'empWantedStdt': item.findElements('empWantedStdt').isNotEmpty
                  ? item.findElements('empWantedStdt').first.innerText
                  : '',
              'empWantedEndt': item.findElements('empWantedEndt').isNotEmpty
                  ? item.findElements('empWantedEndt').first.innerText
                  : '',
              'empWantedTypeNm': item.findElements('empWantedTypeNm').isNotEmpty
                  ? item.findElements('empWantedTypeNm').first.innerText
                  : '',
              'regLogImgNm': item.findElements('regLogImgNm').isNotEmpty
                  ? item.findElements('regLogImgNm').first.innerText
                  : '',
              'empWantedHomepgDetail':
                  item.findElements('empWantedHomepgDetail').isNotEmpty
                  ? item.findElements('empWantedHomepgDetail').first.innerText
                  : '',
            };
          }).toList();
          filteredRecruitments = recruitments;
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

  // 회사명 또는 채용 제목으로 검색
  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRecruitments = recruitments;
      } else {
        filteredRecruitments = recruitments.where((r) {
          return r['empWantedTitle'].contains(query) ||
              r['empBusiNm'].contains(query);
        }).toList();
      }
    });
  }

  // 날짜 포맷 변환 (20260506 → 2026.05.06)
  String formatDate(String date) {
    if (date.length != 8) return date;
    return '${date.substring(0, 4)}.${date.substring(4, 6)}.${date.substring(6, 8)}';
  }

  // 채용 사이트 URL 열기
  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // 기업 구분에 따른 색상
  Color _getCompanyColor(String coClcdNm) {
    switch (coClcdNm) {
      case '대기업':
        return const Color(0xFF3949AB);
      case '공기업':
        return const Color(0xFF00897B);
      case '공공기관':
        return const Color(0xFF00897B);
      case '중견기업':
        return const Color(0xFF8E24AA);
      case '외국계기업':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFF57C00);
    }
  }

  // 태그 위젯 (기업구분, 고용형태 등 작은 뱃지)
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          '채용 정보',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3949AB)),
            )
          : errorMsg.isNotEmpty
          ? Center(child: Text(errorMsg))
          : Column(
              children: [
                // 검색창
                Container(
                  color: const Color(0xFF3949AB),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _search,
                    decoration: InputDecoration(
                      hintText: '회사명 또는 채용 제목 검색',
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
                // 공채 목록
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchRecruitments,
                    color: const Color(0xFF3949AB),
                    child: filteredRecruitments.isEmpty
                        ? const Center(
                            child: Text(
                              '검색 결과가 없습니다',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredRecruitments.length,
                            itemBuilder: (context, index) {
                              final r = filteredRecruitments[index];
                              final companyColor = _getCompanyColor(
                                r['coClcdNm'],
                              );
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  // 카드 탭하면 채용 사이트로 이동
                                  onTap: () =>
                                      _launchUrl(r['empWantedHomepgDetail']),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // 회사 로고
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: companyColor.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: r['regLogImgNm'].isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: Image.network(
                                                        r['regLogImgNm'],
                                                        fit: BoxFit.cover,
                                                        // 로고 로드 실패 시 기본 아이콘
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => Icon(
                                                              Icons
                                                                  .business_rounded,
                                                              color:
                                                                  companyColor,
                                                            ),
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.business_rounded,
                                                      color: companyColor,
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // 회사명
                                                  Text(
                                                    r['empBusiNm'],
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  // 채용 제목
                                                  Text(
                                                    r['empWantedTitle'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // 태그 행 (기업구분, 고용형태, 마감일)
                                        Row(
                                          children: [
                                            if (r['coClcdNm'].isNotEmpty)
                                              _buildTag(
                                                r['coClcdNm'],
                                                companyColor,
                                              ),
                                            if (r['coClcdNm'].isNotEmpty)
                                              const SizedBox(width: 6),
                                            if (r['empWantedTypeNm'].isNotEmpty)
                                              _buildTag(
                                                // 고용형태 여러 개면 첫 번째만 표시
                                                r['empWantedTypeNm']
                                                    .split('|')
                                                    .first,
                                                Colors.grey,
                                              ),
                                            const Spacer(),
                                            // 마감일
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_outlined,
                                                  size: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '~${formatDate(r['empWantedEndt'])}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
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
                  ),
                ),
              ],
            ),
    );
  }
}
