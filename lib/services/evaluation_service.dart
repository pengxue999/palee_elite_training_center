import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import 'package:palee_elite_training_center/models/evaluation_model.dart';

class EvaluationService {
  final HttpHelper _http = HttpHelper();

  Future<EvaluationScoreSubjectListResponse> getScoreSubjects() async {
    final query = Uri(path: '/evaluations/score-entry/subjects').toString();
    final response = await _http.get(query);
    return EvaluationScoreSubjectListResponse.fromJson(
      _http.handleJson(response),
    );
  }

  Future<EvaluationScoreLevelListResponse> getScoreLevels({
    required String subjectId,
  }) async {
    final query = Uri(
      path: '/evaluations/score-entry/levels',
      queryParameters: {'subject_id': subjectId},
    ).toString();

    final response = await _http.get(query);
    return EvaluationScoreLevelListResponse.fromJson(
      _http.handleJson(response),
    );
  }

  Future<EvaluationScoreSheetResponse> getScoreSheet({
    required String semester,
    required String levelId,
    required String subjectDetailId,
  }) async {
    final query = Uri(
      path: '/evaluations/score-entry/sheet',
      queryParameters: {
        'semester': semester,
        'level_id': levelId,
        'subject_detail_id': subjectDetailId,
      },
    ).toString();

    final response = await _http.get(query);
    return EvaluationScoreSheetResponse.fromJson(_http.handleJson(response));
  }

  Future<EvaluationScoreSheetResponse> previewScoreSheet(
    EvaluationScoreSheetRequest request,
  ) async {
    final response = await _http.post(
      '/evaluations/score-entry/preview',
      body: request.toJson(),
    );
    return EvaluationScoreSheetResponse.fromJson(_http.handleJson(response));
  }

  Future<EvaluationScoreSheetResponse> saveScoreSheet(
    EvaluationScoreSheetRequest request,
  ) async {
    final response = await _http.put(
      '/evaluations/score-entry/sheet',
      body: request.toJson(),
    );
    return EvaluationScoreSheetResponse.fromJson(_http.handleJson(response));
  }

  Future<AssessmentReportListResponse> getAssessmentResults({
    required String semester,
    String? academicId,
    String? subjectId,
    String? levelId,
    String? ranking,
  }) async {
    final params = <String, String>{'semester': semester};
    if (academicId != null && academicId.isNotEmpty) {
      params['academic_id'] = academicId;
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      params['subject_id'] = subjectId;
    }
    if (levelId != null && levelId.isNotEmpty) {
      params['level_id'] = levelId;
    }
    if (ranking != null && ranking.isNotEmpty) {
      params['ranking'] = ranking;
    }

    final query = Uri(
      path: '/reports/assessment-results',
      queryParameters: params,
    ).toString();

    final response = await _http.get(query);
    return AssessmentReportListResponse.fromJson(_http.handleJson(response));
  }
}
