import '../core/utils/http_helper.dart';
import '../models/teacher_assignment_model.dart';

class TeacherAssignmentService {
  final HttpHelper _http = HttpHelper();

  Future<TeacherAssignmentResponse> getAssignments() async {
    final response = await _http.get('/teacher-assignments');
    return TeacherAssignmentResponse.fromJson(_http.handleJson(response));
  }

  Future<TeacherAssignmentResponse> getAssignmentsByTeacher(
    String teacherId,
  ) async {
    final response = await _http.get(
      '/teacher-assignments/by-teacher/$teacherId',
    );
    return TeacherAssignmentResponse.fromJson(_http.handleJson(response));
  }

  Future<TeacherAssignmentSingleResponse> createAssignment(
    TeacherAssignmentRequest request,
  ) async {
    final response = await _http.post(
      '/teacher-assignments',
      body: request.toJson(),
    );
    return TeacherAssignmentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<TeacherAssignmentSingleResponse> updateAssignment(
    String assignmentId,
    TeacherAssignmentRequest request,
  ) async {
    final response = await _http.put(
      '/teacher-assignments/$assignmentId',
      body: request.toJson(),
    );
    return TeacherAssignmentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteAssignment(String assignmentId) async {
    final response = await _http.delete('/teacher-assignments/$assignmentId');
    _http.handleJson(response);
  }
}
