class DormitoryRequest {
  final String gender;
  final int maxCapacity;

  const DormitoryRequest({required this.gender, required this.maxCapacity});

  Map<String, dynamic> toJson() => {
        'gender': gender,
        'max_capacity': maxCapacity,
      };
}

class DormitorySingleResponse {
  final String code;
  final String messages;
  final DormitoryModel data;

  const DormitorySingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory DormitorySingleResponse.fromJson(Map<String, dynamic> json) {
    return DormitorySingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: DormitoryModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class DormitoryModel {
  final int dormitoryId;
  final String gender;
  final int maxCapacity;

  const DormitoryModel({
    required this.dormitoryId,
    required this.gender,
    required this.maxCapacity,
  });

  factory DormitoryModel.fromJson(Map<String, dynamic> json) {
    return DormitoryModel(
      dormitoryId: json['dormitory_id'] as int,
      gender: json['gender'] as String,
      maxCapacity: json['max_capacity'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'dormitory_id': dormitoryId,
        'gender': gender,
        'max_capacity': maxCapacity,
      };

  String get displayName => 'ຫໍພັກ ($gender)';
}

class DormitoryResponse {
  final String code;
  final String messages;
  final List<DormitoryModel> data;

  const DormitoryResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory DormitoryResponse.fromJson(Map<String, dynamic> json) {
    return DormitoryResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => DormitoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
