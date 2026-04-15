import 'package:palee_elite_training_center/core/utils/http_helper.dart';

import '../models/district_model.dart';

class DistrictService {
  final HttpHelper _http = HttpHelper();

  Future<DistrictResponse> getDistricts() async {
    final response = await _http.get('/districts');
    return DistrictResponse.fromJson(_http.handleJson(response));
  }

  Future<DistrictResponse> getDistrictsByProvince(int provinceId) async {
    final response = await _http.get('/districts/province/$provinceId');
    return DistrictResponse.fromJson(_http.handleJson(response));
  }
}
