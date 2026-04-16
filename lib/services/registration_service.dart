import 'dart:typed_data';

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

  Future<Uint8List> createRegistrationReceiptPdf({
    required String registrationId,
    required String registrationDate,
    required String studentName,
    required List<Map<String, Object?>> selectedFees,
    required int tuitionFee,
    required String? dormitoryLabel,
    required int dormitoryFee,
    required int totalFee,
    required int discountAmount,
    required int netFee,
  }) async {
    final response = await _http.post(
      '/registrations/receipt-pdf',
      body: {
        'registration_id': registrationId,
        'registration_date': registrationDate,
        'student_name': studentName,
        'selected_fees': selectedFees,
        'tuition_fee': tuitionFee,
        'dormitory_label': dormitoryLabel,
        'dormitory_fee': dormitoryFee,
        'total_fee': totalFee,
        'discount_amount': discountAmount,
        'net_fee': netFee,
      },
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }
}
