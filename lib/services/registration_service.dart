import '../core/utils/http_helper.dart';
import '../models/registration_model.dart';

class RegistrationService {
  final HttpHelper _http = HttpHelper();

  Future<RegistrationListResponse> getRegistrations() async {
    final response = await _http.get('/registrations');
    return RegistrationListResponse.fromJson(_http.handleJson(response));
  }

  Future<RegistrationSingleResponse> getRegistrationById(
    String registrationId,
  ) async {
    final response = await _http.get('/registrations/$registrationId');
    return RegistrationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<RegistrationSingleResponse> createRegistration(
    RegistrationRequest request,
  ) async {
    final response = await _http.post('/registrations', body: request.toJson());
    return RegistrationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<RegistrationSingleResponse> createRegistrationBulk(
    RegistrationRequest request,
    List<Map<String, dynamic>> details,
  ) async {
    final body = {...request.toJson(), 'details': details};
    final response = await _http.post('/registrations/bulk', body: body);
    return RegistrationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<RegistrationSingleResponse> updateRegistration(
    String registrationId,
    RegistrationRequest request,
  ) async {
    final response = await _http.put(
      '/registrations/$registrationId',
      body: request.toJson(),
    );
    return RegistrationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteRegistration(String registrationId) async {
    final response = await _http.delete('/registrations/$registrationId');
    _http.handleJson(response);
  }
}
