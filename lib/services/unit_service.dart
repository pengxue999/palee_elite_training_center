import '../core/utils/http_helper.dart';
import '../models/unit_model.dart';

class UnitService {
  final HttpHelper _http = HttpHelper();

  Future<UnitListResponse> getUnits() async {
    final response = await _http.get('/units');
    return UnitListResponse.fromJson(_http.handleJson(response));
  }

  Future<UnitSingleResponse> getUnitById(int unitId) async {
    final response = await _http.get('/units/$unitId');
    return UnitSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<UnitSingleResponse> createUnit(UnitRequest request) async {
    final response = await _http.post('/units', body: request.toJson());
    return UnitSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<UnitSingleResponse> updateUnit(int unitId, UnitRequest request) async {
    final response = await _http.put('/units/$unitId', body: request.toJson());
    return UnitSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteUnit(int unitId) async {
    final response = await _http.delete('/units/$unitId');
    _http.handleJson(response);
  }
}
