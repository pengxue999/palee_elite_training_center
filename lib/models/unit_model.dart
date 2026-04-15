class UnitModel {
  final int unitId;
  final String unitName;

  const UnitModel({required this.unitId, required this.unitName});

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      unitId: json['unit_id'] as int,
      unitName: json['unit_name'] as String? ?? '',
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'unitId':
        return unitId;
      case 'unitName':
        return unitName;
      default:
        return null;
    }
  }
}

class UnitRequest {
  final String unitName;

  const UnitRequest({required this.unitName});

  Map<String, dynamic> toJson() => {'unit_name': unitName};
}

class UnitListResponse {
  final String code;
  final String messages;
  final List<UnitModel> data;

  const UnitListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory UnitListResponse.fromJson(Map<String, dynamic> json) {
    return UnitListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => UnitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UnitSingleResponse {
  final String code;
  final String messages;
  final UnitModel data;

  const UnitSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory UnitSingleResponse.fromJson(Map<String, dynamic> json) {
    return UnitSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: UnitModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
