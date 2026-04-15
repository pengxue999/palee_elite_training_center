import '../core/utils/http_helper.dart';
import '../models/donation_category_model.dart';

class DonationCategoryService {
  final HttpHelper _http = HttpHelper();

  Future<DonationCategoryListResponse> getDonationCategories() async {
    final response = await _http.get('/donation-categories');
    return DonationCategoryListResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationCategorySingleResponse> getDonationCategoryById(
    int categoryId,
  ) async {
    final response = await _http.get('/donation-categories/$categoryId');
    return DonationCategorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationCategorySingleResponse> createDonationCategory(
    DonationCategoryRequest request,
  ) async {
    final response = await _http.post(
      '/donation-categories',
      body: request.toJson(),
    );
    return DonationCategorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationCategorySingleResponse> updateDonationCategory(
    int categoryId,
    DonationCategoryRequest request,
  ) async {
    final response = await _http.put(
      '/donation-categories/$categoryId',
      body: request.toJson(),
    );
    return DonationCategorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteDonationCategory(int categoryId) async {
    final response = await _http.delete('/donation-categories/$categoryId');
    _http.handleJson(response);
  }
}
