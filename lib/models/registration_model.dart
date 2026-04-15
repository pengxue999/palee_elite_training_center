class RegistrationModel {
  final String registrationId;
  final String? studentId;
  final String studentName;
  final String studentLastname;
  final String? discountDescription;
  final double totalAmount;
  final double finalAmount;
  final double paidAmount;
  final String status;
  final String registrationDate;

  RegistrationModel({
    required this.registrationId,
    this.studentId,
    required this.studentName,
    required this.studentLastname,
    this.discountDescription,
    required this.totalAmount,
    required this.finalAmount,
    this.paidAmount = 0.0,
    required this.status,
    required this.registrationDate,
  });

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return RegistrationModel(
      registrationId: json['registration_id'] as String? ?? '',
      studentId: json['student_id'] as String?,
      studentName: json['student_name'] as String? ?? '',
      studentLastname: json['student_lastname'] as String? ?? '',
      discountDescription: json['discount_description'] as String?,
      totalAmount: parseAmount(json['total_amount']),
      finalAmount: parseAmount(json['final_amount']),
      paidAmount: parseAmount(json['paid_amount']),
      status: json['status'] as String? ?? '',
      registrationDate: json['registration_date'] as String? ?? '',
    );
  }

  double get remainingAmount =>
      (finalAmount - paidAmount).clamp(0.0, double.infinity);

  String get studentFullName => '$studentName $studentLastname';

  dynamic operator [](String key) {
    switch (key) {
      case 'registrationId':
        return registrationId;
      case 'studentId':
        return studentId ?? '';
      case 'studentName':
        return studentFullName;
      case 'studentFirstName':
        return studentName;
      case 'studentLastname':
        return studentLastname;
      case 'discountDescription':
        return discountDescription ?? '-';
      case 'totalAmount':
        return totalAmount;
      case 'finalAmount':
        return finalAmount;
      case 'paidAmount':
        return paidAmount;
      case 'remainingAmount':
        return remainingAmount;
      case 'status':
        return status;
      case 'registrationDate':
        return registrationDate;
      default:
        return null;
    }
  }
}

class RegistrationRequest {
  final String? registrationId;
  final String studentId;
  final String? discountId;
  final double totalAmount;
  final double finalAmount;
  final String status;
  final DateTime registrationDate;

  RegistrationRequest({
    this.registrationId,
    required this.studentId,
    this.discountId,
    required this.totalAmount,
    required this.finalAmount,
    required this.status,
    required this.registrationDate,
  });

  Map<String, dynamic> toJson() => {
    if (registrationId != null) 'registration_id': registrationId,
    'student_id': studentId,
    'discount_id': discountId,
    'total_amount': totalAmount,
    'final_amount': finalAmount,
    'status': status,
    'registration_date': registrationDate.toIso8601String(),
  };
}

class RegistrationListResponse {
  final String code;
  final String messages;
  final List<RegistrationModel> data;

  RegistrationListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory RegistrationListResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationListResponse(
      code: json['code'] as String? ?? '',
      messages: json['messages'] as String? ?? '',
      data:
          (json['data'] as List?)
              ?.map(
                (e) => RegistrationModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class RegistrationSingleResponse {
  final String code;
  final String messages;
  final RegistrationModel data;

  RegistrationSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory RegistrationSingleResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationSingleResponse(
      code: json['code'] as String? ?? '',
      messages: json['messages'] as String? ?? '',
      data: RegistrationModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
