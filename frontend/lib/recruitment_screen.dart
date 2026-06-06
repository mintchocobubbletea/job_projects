// recruitment_screen.dart
// 채용 정보 화면
// 고용24 공채속보 API를 통해 대기업, 공기업 등의 공개채용 정보 표시
// 검색 기능 제공, 채용 공고 탭 시 해당 기업 채용 사이트로 이동

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:url_launcher/url_launcher.dart';
import 'env.dart';

class RecruitmentScreen extends StatefulWidget {
  // 로그인한 사용자의 닉네임
  final String username;
  const RecruitmentScreen({super.key, required this.username});

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  // 공채 전체 목록 (API에서 불러온 원본 데이터)
  List<Map<String, dynamic>> recruitments = [];
  // 검색 필터링된 공채 목록 (화면에 표시)
  List<Map<String, dynamic>> filteredRecruitments = [];
  bool isLoading = true;
  String errorMsg = '';
  // 검색창 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 공채 목록 불러오기
    fetchRecruitments();
  }

  // 고용24 공채속보 API 호출
  // callTp=L: 목록 조회
  // sortField=regDt, sortOrderBy=desc: 최신 등록순 정렬
  Future<void> fetchRecruitments() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo210L21.do'
          '?authKey=${Env.recruitApiKey}'
          '&callTp=L' // 목록 조회 타입
          '&returnType=XML'
          '&startPage=1'
          '&display=50' // 최대 50개 조회
          '&sortField=regDt' // 등록일 기준 정렬
          '&sortOrderBy=desc', // 최신순 (내림차순)
        ),
      );

      if (response.statusCode == 200) {
        // XML 응답 파싱
        final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
        final items = document.findAllElements('dhsOpenEmpInfo');
        setState(() {
          recruitments = items.map((item) {
            return {
              // 채용 공고 제목
              'empWantedTitle': item.findElements('empWantedTitle').isNotEmpty
                  ? item.findElements('empWantedTitle').first.innerText
                  : '',
              // 채용 기업명
              'empBusiNm': item.findElements('empBusiNm').isNotEmpty
                  ? item.findElements('empBusiNm').first.innerText
                  : '',
              // 기업 구분 (대기업, 공기업, 중견기업 등)
              'coClcdNm': item.findElements('coClcdNm').isNotEmpty
                  ? item.findElements('coClcdNm').first.innerText
                  : '',
              // 채용 시작일
              'empWantedStdt': item.findElements('empWantedStdt').isNotEmpty
                  ? item.findElements('empWantedStdt').first.innerText
                  : '',
              // 채용 마감일
              'empWantedEndt': item.findElements('empWantedEndt').isNotEmpty
                  ? item.findElements('empWantedEndt').first.innerText
                  : '',
              // 고용형태 (정규직, 계약직 등, |로 구분된 복수값 가능)
              'empWantedTypeNm': item.findElements('empWantedTypeNm').isNotEmpty
                  ? item.findElements('empWantedTypeNm').first.innerText
                  : '',
              // 기업 로고 이미지 URL
              'regLogImgNm': item.findElements('regLogImgNm').isNotEmpty
                  ? item.findElements('regLogImgNm').first.innerText
                  : '',
              // 채용 사이트 URL (카드 탭 시 이동)
              'empWantedHomepgDetail':
                  item.findElements('empWantedHomepgDetail').isNotEmpty
                  ? item.findElements('empWantedHomepgDetail').first.innerText
                  : '',
            };
          }).toList();
          // 검색 필터 초기화 (전체 목록 표시)
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

  // 회사명 또는 채용 제목으로 검색 필터링
  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        // 검색어 없으면 전체 목록 표시
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

  // 채용 사이트 URL 열기 (외부 브라우저)
  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // 기업 구분에 따른 테마 색상 반환
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
        // 기업 구분이 없거나 기타인 경우 주황색
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
    // 화면 종료 시 컨트롤러 해제 (메모리 누수 방지)
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
        // 타이틀 영역 숨김 (main_screen.dart의 공통 앱바 사용)
        toolbarHeight: 0,
      ),
      body: isLoading
          // 로딩 중 스피너 표시
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3949AB)),
            )
          : errorMsg.isNotEmpty
          // 에러 발생 시 에러 메시지 표시
          ? Center(child: Text(errorMsg))
          : Column(
              children: [
                // 검색창
                Container(
                  color: const Color(0xFF3949AB),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                    // 아래로 당기면 새로고침
                    onRefresh: fetchRecruitments,
                    color: const Color(0xFF3949AB),
                    child: filteredRecruitments.isEmpty
                        // 검색 결과 없을 때 안내 메시지
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
                                  borderRadius: BorderRadius.circular(12),
                                  // 기업 구분에 따른 색상으로 왼쪽 보더
                                  border: Border(
                                    left: BorderSide(
                                      color: companyColor,
                                      width: 3,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  // 카드 탭 시 채용 사이트로 이동
                                  onTap: () =>
                                      _launchUrl(r['empWantedHomepgDetail']),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // 기업 로고 (없으면 기본 아이콘)
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: companyColor.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: r['regLogImgNm'].isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      child: Image.network(
                                                        r['regLogImgNm'],
                                                        fit: BoxFit.cover,
                                                        // 로고 로드 실패 시 기본 아이콘
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
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
                                                  // 기업명
                                                  Text(
                                                    r['empBusiNm'],
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  // 채용 공고 제목 (길면 말줄임표)
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
                                        const SizedBox(height: 10),
                                        // 태그 행 (기업구분, 고용형태, 마감일)
                                        Row(
                                          children: [
                                            // 기업 구분 태그 (있을 때만 표시)
                                            if (r['coClcdNm'].isNotEmpty)
                                              _buildTag(
                                                r['coClcdNm'],
                                                companyColor,
                                              ),
                                            if (r['coClcdNm'].isNotEmpty)
                                              const SizedBox(width: 6),
                                            // 고용형태 태그
                                            // 여러 개인 경우 첫 번째만 표시
                                            if (r['empWantedTypeNm'].isNotEmpty)
                                              _buildTag(
                                                r['empWantedTypeNm']
                                                    .split('|')
                                                    .first,
                                                Colors.grey,
                                              ),
                                            const Spacer(),
                                            // 채용 마감일
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
