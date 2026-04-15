import '../core/utils/http_helper.dart';
import '../models/donation_model.dart';

class DonationService {
  final HttpHelper _http = HttpHelper();

  Future<DonationListResponse> getDonations() async {
    final response = await _http.get('/donations');
    return DonationListResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationSingleResponse> getDonationById(int donationId) async {
    final response = await _http.get('/donations/$donationId');
    return DonationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationListResponse> getDonationsByDonor(String donorId) async {
    final response = await _http.get('/donations/by-donor/$donorId');
    return DonationListResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationSingleResponse> createDonation(DonationRequest request) async {
    final response = await _http.post(
      '/donations',
      body: request.toJson(),
    );
    return DonationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationSingleResponse> updateDonation(
    int donationId,
    DonationUpdateRequest request,
  ) async {
    final response = await _http.put(
      '/donations/$donationId',
      body: request.toJson(),
    );
    return DonationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteDonation(int donationId) async {
    final response = await _http.delete('/donations/$donationId');
    _http.handleJson(response);
  }
}
