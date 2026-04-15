class DonationCategoryModel {
  final int donationCategoryId;
  final String donationCategory;

  const DonationCategoryModel({
    required this.donationCategoryId,
    required this.donationCategory,
  });

  factory DonationCategoryModel.fromJson(Map<String, dynamic> json) {
    return DonationCategoryModel(
      donationCategoryId: json['donation_category_id'] as int,
      donationCategory: json['donation_category'] as String? ?? '',
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'donationCategoryId':
        return donationCategoryId;
      case 'donationCategory':
        return donationCategory;
      default:
        return null;
    }
  }
}

class DonationCategoryRequest {
  final String donationCategory;

  const DonationCategoryRequest({required this.donationCategory});

  Map<String, dynamic> toJson() => {'donation_category': donationCategory};
}

class DonationCategoryListResponse {
  final String code;
  final String messages;
  final List<DonationCategoryModel> data;

  const DonationCategoryListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory DonationCategoryListResponse.fromJson(Map<String, dynamic> json) {
    return DonationCategoryListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => DonationCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DonationCategorySingleResponse {
  final String code;
  final String messages;
  final DonationCategoryModel data;

  const DonationCategorySingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory DonationCategorySingleResponse.fromJson(Map<String, dynamic> json) {
    return DonationCategorySingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: DonationCategoryModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
