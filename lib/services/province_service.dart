import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import '../models/province_model.dart';

class ProvinceService {
  final HttpHelper _http = HttpHelper();

  Future<ProvinceResponse> getProvinces() async {
    final response = await _http.get('/provinces');
    return ProvinceResponse.fromJson(_http.handleJson(response));
  }
}
