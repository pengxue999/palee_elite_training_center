import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import '../models/report_models.dart';

class ReportService {
  final HttpHelper _http = HttpHelper();

  Future<FinanceReportResponse> getFinanceReport({
    String? academicId,
    int? year,
  }) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (year != null) queryParams['year'] = year.toString();

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/finance?$queryString');
    return FinanceReportResponse.fromJson(_http.handleJson(response));
  }

  Future<ExportReportResponse> exportFinanceReport({
    String? academicId,
    int? year,
    String format = 'csv',
  }) async {
    final queryParams = <String, String>{'format': format};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (year != null) queryParams['year'] = year.toString();

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/finance/export?$queryString');
    return ExportReportResponse.fromJson(_http.handleJson(response));
  }

  Future<StudentReportResponse> getStudentReport({
    String? academicId,
    int? provinceId,
    int? districtId,
    String? scholarship,
    String? dormitoryType,
    String? gender,
  }) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (provinceId != null) queryParams['province_id'] = provinceId.toString();
    if (districtId != null) queryParams['district_id'] = districtId.toString();
    if (scholarship != null) queryParams['scholarship'] = scholarship;
    if (dormitoryType != null) queryParams['dormitory_type'] = dormitoryType;
    if (gender != null) queryParams['gender'] = gender;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/students?$queryString');
    return StudentReportResponse.fromJson(_http.handleJson(response));
  }

  Future<ExportReportResponse> exportStudentReport({
    String? academicId,
    int? provinceId,
    int? districtId,
    String? scholarship,
    String? dormitoryType,
    String? gender,
    String format = 'csv',
  }) async {
    final queryParams = <String, String>{'format': format};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (provinceId != null) queryParams['province_id'] = provinceId.toString();
    if (districtId != null) queryParams['district_id'] = districtId.toString();
    if (scholarship != null) queryParams['scholarship'] = scholarship;
    if (dormitoryType != null) queryParams['dormitory_type'] = dormitoryType;
    if (gender != null) queryParams['gender'] = gender;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/students/export?$queryString');
    return ExportReportResponse.fromJson(_http.handleJson(response));
  }

  Future<StudentSummaryResponse> getStudentSummary({String? academicId}) async {
    final queryString = academicId != null
        ? '?academic_id=${Uri.encodeComponent(academicId)}'
        : '';

    final response = await _http.get('/reports/students/summary$queryString');
    return StudentSummaryResponse.fromJson(_http.handleJson(response));
  }

  Future<TeacherAttendanceReportResponse> getTeacherAttendanceReport({
    String? academicId,
    String? month,
    String? status,
    String? teacherId,
  }) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (month != null) queryParams['month'] = month;
    if (status != null) queryParams['status'] = status;
    if (teacherId != null) queryParams['teacher_id'] = teacherId;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/teacher-attendance?$queryString');
    return TeacherAttendanceReportResponse.fromJson(_http.handleJson(response));
  }

  Future<ExportReportResponse> exportTeacherAttendanceReport({
    String? academicId,
    String? month,
    String? status,
    String? teacherId,
    String format = 'csv',
  }) async {
    final queryParams = <String, String>{'format': format};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (month != null) queryParams['month'] = month;
    if (status != null) queryParams['status'] = status;
    if (teacherId != null) queryParams['teacher_id'] = teacherId;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/teacher-attendance/export?$queryString');
    return ExportReportResponse.fromJson(_http.handleJson(response));
  }

  Future<PopularSubjectsReportResponse> getPopularSubjectsReport({
    String? academicId,
  }) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/popular-subjects?$queryString');
    return PopularSubjectsReportResponse.fromJson(_http.handleJson(response));
  }
}
