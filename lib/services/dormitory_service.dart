import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import '../models/dormitory_model.dart';

class DormitoryService {
  final HttpHelper _http = HttpHelper();

  Future<DormitoryResponse> getDormitories() async {
    final response = await _http.get('/dormitories');
    return DormitoryResponse.fromJson(_http.handleJson(response));
  }

  Future<DormitorySingleResponse> createDormitory(
    DormitoryRequest request,
  ) async {
    final response = await _http.post('/dormitories', body: request.toJson());
    return DormitorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DormitorySingleResponse> updateDormitory(
    int dormitoryId,
    DormitoryRequest request,
  ) async {
    final response = await _http.put(
      '/dormitories/$dormitoryId',
      body: request.toJson(),
    );
    return DormitorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteDormitory(int dormitoryId) async {
    final response = await _http.delete('/dormitories/$dormitoryId');
    _http.handleJson(response);
  }
}
