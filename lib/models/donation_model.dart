class DonationModel {
  final int donationId;
  final String? donorId;
  final String donorName;
  final String? donorLastname;
  final int? donationCategoryId;
  final String donationCategory;
  final String donationName;
  final double amount;
  final int? unitId;
  final String? unitName;
  final String? description;
  final String donationDate;
  final String? createdAt;

  DonationModel({
    required this.donationId,
    this.donorId,
    required this.donorName,
    this.donorLastname,
    this.donationCategoryId,
    required this.donationCategory,
    required this.donationName,
    required this.amount,
    this.unitId,
    this.unitName,
    this.description,
    required this.donationDate,
    this.createdAt,
  });

  String get donorFullName => '$donorName ${donorLastname ?? ''}';

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return DonationModel(
      donationId: json['donation_id'] as int,
      donorId: json['donor_id'] as String?,
      donorName: json['donor_name'] as String? ?? '',
      donorLastname: json['donor_lastname'] as String?,
      donationCategoryId: json['donation_category_id'] as int?,
      donationCategory:
          json['donation_category_name'] as String? ??
          json['donation_category'] as String? ??
          '',
      donationName: json['donation_name'] as String? ?? '',
      amount: parseAmount(json['amount']),
      unitId: json['unit_id'] as int?,
      unitName: json['unit_name'] as String?,
      description: json['description'] as String?,
      donationDate: json['donation_date'] as String? ?? '',
      createdAt: json['created_at'] as String?,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'donationId':
        return donationId;
      case 'donorId':
        return donorId;
      case 'donorName':
        return donorName;
      case 'donorLastname':
        return donorLastname;
      case 'donorFullName':
        return donorFullName;
      case 'donationCategoryId':
        return donationCategoryId;
      case 'donationCategory':
        return donationCategory;
      case 'donationName':
        return donationName;
      case 'amount':
        return amount;
      case 'unitId':
        return unitId;
      case 'unitName':
        return unitName;
      case 'description':
        return description;
      case 'donationDate':
        return donationDate;
      case 'createdAt':
        return createdAt;
      default:
        return null;
    }
  }
}

class DonationRequest {
  final String donorId;
  final String donationCategory;
  final String donationName;
  final double amount;
  final int? unitId;
  final String? description;
  final String donationDate;

  DonationRequest({
    required this.donorId,
    required this.donationCategory,
    required this.donationName,
    required this.amount,
    this.unitId,
    this.description,
    required this.donationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'donor_id': donorId,
      'donation_category': donationCategory,
      'donation_name': donationName,
      'amount': amount,
      if (unitId != null) 'unit_id': unitId,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'donation_date': donationDate,
    };
  }
}

class DonationUpdateRequest {
  final String? donorId;
  final String? donationCategory;
  final String? donationName;
  final double? amount;
  final int? unitId;
  final String? description;
  final String? donationDate;

  DonationUpdateRequest({
    this.donorId,
    this.donationCategory,
    this.donationName,
    this.amount,
    this.unitId,
    this.description,
    this.donationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      if (donorId != null) 'donor_id': donorId,
      if (donationCategory != null) 'donation_category': donationCategory,
      if (donationName != null) 'donation_name': donationName,
      if (amount != null) 'amount': amount,
      if (unitId != null) 'unit_id': unitId,
      if (description != null) 'description': description,
      if (donationDate != null) 'donation_date': donationDate,
    };
  }
}

class DonationListResponse {
  final List<DonationModel> data;
  final String message;

  DonationListResponse({required this.data, required this.message});

  factory DonationListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List<dynamic>? ?? [];
    return DonationListResponse(
      data: rawData
          .map((e) => DonationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['messages'] as String? ?? '',
    );
  }
}

class DonationSingleResponse {
  final DonationModel data;
  final String message;

  DonationSingleResponse({required this.data, required this.message});

  factory DonationSingleResponse.fromJson(Map<String, dynamic> json) {
    return DonationSingleResponse(
      data: DonationModel.fromJson(json['data'] as Map<String, dynamic>),
      message: json['messages'] as String? ?? '',
    );
  }
}
