import 'dart:convert';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
// 직업정보 모델
// ─────────────────────────────────────────────

class JobInfo {
  final String jobCd;
  final String jobNm;
  final String jobDtlNm;
  final String summary;

  JobInfo({
    required this.jobCd,
    required this.jobNm,
    required this.jobDtlNm,
    required this.summary,
  });

  factory JobInfo.fromJson(Map<String, dynamic> json) {
    return JobInfo(
      jobCd: json['jobCd']?.toString() ?? '',
      jobNm: json['jobNm']?.toString() ?? '',
      jobDtlNm: json['jobDtlNm']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
    );
  }
}

class JobInfoDetail {
  final String jobCd;
  final String jobNm;
  final String jobDtlNm;
  final String summary;
  final String work; // 하는 일
  final String salary; // 임금
  final String employ; // 고용현황
  final String outlook; // 직업전망
  final String aptitude; // 적성 및 흥미
  final String prepare; // 준비방법
  final String relJobNm; // 관련직업
  final String relEduOrg; // 관련 교육기관

  JobInfoDetail({
    required this.jobCd,
    required this.jobNm,
    required this.jobDtlNm,
    required this.summary,
    required this.work,
    required this.salary,
    required this.employ,
    required this.outlook,
    required this.aptitude,
    required this.prepare,
    required this.relJobNm,
    required this.relEduOrg,
  });

  factory JobInfoDetail.fromJson(Map<String, dynamic> json) {
    return JobInfoDetail(
      jobCd: json['jobCd']?.toString() ?? '',
      jobNm: json['jobNm']?.toString() ?? '',
      jobDtlNm: json['jobDtlNm']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      work: json['work']?.toString() ?? '',
      salary: json['salary']?.toString() ?? '',
      employ: json['employ']?.toString() ?? '',
      outlook: json['outlook']?.toString() ?? '',
      aptitude: json['aptitude']?.toString() ?? '',
      prepare: json['prepare']?.toString() ?? '',
      relJobNm: json['relJobNm']?.toString() ?? '',
      relEduOrg: json['relEduOrg']?.toString() ?? '',
    );
  }
}

// ─────────────────────────────────────────────
// 직업정보 API 서비스
// ─────────────────────────────────────────────

class JobInfoService {
  static const String _listUrl =
      'https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo212L01.do';
  static const String _detailUrl =
      'https://www.work24.go.kr/cm/openApi/call/wk/callOpenApiSvcInfo212D01.do';

  static const String _authKey = '40ead606-39be-4a5e-af2f-56f4eb8a2da8';

  /// 직업 목록 조회
  /// [keyword] 검색어 (빈 문자열이면 전체 조회)
  /// [startPage] 시작 페이지 (1부터)
  /// [display] 한 페이지 결과 수 (최대 100)
  static Future<Map<String, dynamic>> fetchJobList({
    String keyword = '',
    int startPage = 1,
    int display = 20,
  }) async {
    final params = {
      'authKey': _authKey,
      'returnType': 'JSON',
      'startPage': startPage.toString(),
      'display': display.toString(),
      if (keyword.isNotEmpty) 'srchJobNm': keyword,
    };

    final uri = Uri.parse(_listUrl).replace(queryParameters: params);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return _parseListResponse(decoded);
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('직업 목록 조회 실패: $e');
    }
  }

  /// 직업 상세 조회
  /// [jobCd] 직업 코드
  static Future<JobInfoDetail> fetchJobDetail(String jobCd) async {
    final params = {'authKey': _authKey, 'returnType': 'JSON', 'jobCd': jobCd};

    final uri = Uri.parse(_detailUrl).replace(queryParameters: params);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return _parseDetailResponse(decoded);
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('직업 상세 조회 실패: $e');
    }
  }

  // ─── 파싱 헬퍼 ───────────────────────────────

  static Map<String, dynamic> _parseListResponse(dynamic decoded) {
    // API 응답이 리스트로 올 경우 첫 번째 항목 추출
    final data = decoded is List ? decoded[0] : decoded;

    final total = int.tryParse(data['total']?.toString() ?? '0') ?? 0;
    final jobs = <JobInfo>[];

    final jobsNode = data['jobs'];
    if (jobsNode != null) {
      final jobList = jobsNode['job'];
      if (jobList is List) {
        for (final item in jobList) {
          jobs.add(JobInfo.fromJson(item as Map<String, dynamic>));
        }
      } else if (jobList is Map) {
        // 결과가 1건일 때 배열이 아닌 단일 객체로 오는 경우 대응
        jobs.add(JobInfo.fromJson(jobList as Map<String, dynamic>));
      }
    }

    return {'total': total, 'jobs': jobs};
  }

  static JobInfoDetail _parseDetailResponse(dynamic decoded) {
    final data = decoded is List ? decoded[0] : decoded;
    final jobNode = data['jobs']?['job'];
    if (jobNode == null) throw Exception('직업 정보를 찾을 수 없습니다.');
    return JobInfoDetail.fromJson(jobNode as Map<String, dynamic>);
  }
}
