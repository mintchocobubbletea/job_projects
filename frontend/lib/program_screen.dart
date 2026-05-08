import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class ProgramScreen extends StatefulWidget {
  final String username;
  const ProgramScreen({super.key, required this.username});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  List<Map<String, dynamic>> programs = [];
  bool isLoading = true;
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    fetchPrograms();
  }

  Future<void> fetchPrograms() async {
    try {
      // 어제 날짜부터 조회 (오늘 데이터 없을 수 있어서)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr =
          '${yesterday.year}'
          '${yesterday.month.toString().padLeft(2, '0')}'
          '${yesterday.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse(
          'https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo217L01.do'
          '?authKey=f3afbffd-8083-49e1-a141-e5f16c86b0f8'
          '&returnType=XML'
          '&startPage=1'
          '&display=20',
          //'&pgmStdt=$dateStr',
        ),
      );

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
        final items = document.findAllElements('empPgmSchdInvite');
        setState(() {
          programs = items.map((item) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        title: const Text(
          '취업 프로그램',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3949AB)),
            )
          : errorMsg.isNotEmpty
          ? Center(child: Text(errorMsg))
          : RefreshIndicator(
              onRefresh: fetchPrograms,
              color: const Color(0xFF3949AB),
              child: programs.isEmpty
                  ? const Center(
                      child: Text(
                        '오늘 등록된 프로그램이 없습니다',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: programs.length,
                      itemBuilder: (context, index) {
                        final p = programs[index];
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
                            padding: const EdgeInsets.all(20),
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
                                        color: const Color(
                                          0xFF3949AB,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p['pgmNm'],
                                        style: const TextStyle(
                                          color: Color(0xFF3949AB),
                                          fontSize: 12,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
            ),
    );
  }
}
