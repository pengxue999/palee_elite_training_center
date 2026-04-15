import '../core/utils/http_helper.dart';
import '../models/tuition_payment_model.dart';

class TuitionPaymentService {
  final HttpHelper _http = HttpHelper();

  Future<TuitionPaymentListResponse> getTuitionPayments() async {
    final response = await _http.get('/tuition-payments');
    return TuitionPaymentListResponse.fromJson(_http.handleJson(response));
  }

  Future<TuitionPaymentListResponse> getPaymentsByRegistration(
    String registrationId,
  ) async {
    final response = await _http.get(
      '/tuition-payments/by-registration/$registrationId',
    );
    return TuitionPaymentListResponse.fromJson(_http.handleJson(response));
  }

  Future<TuitionPaymentSingleResponse> getTuitionPaymentById(String id) async {
    final response = await _http.get('/tuition-payments/$id');
    return TuitionPaymentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<TuitionPaymentSingleResponse> createTuitionPayment(
    TuitionPaymentRequest request,
  ) async {
    final response = await _http.post(
      '/tuition-payments',
      body: request.toJson(),
    );
    return TuitionPaymentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteTuitionPayment(String id) async {
    final response = await _http.delete('/tuition-payments/$id');
    _http.handleJson(response);
  }
}
