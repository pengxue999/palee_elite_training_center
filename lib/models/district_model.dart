class DistrictModel {
  final int districtId;
  final String districtName;
  final String provinceName;

  const DistrictModel({
    required this.districtId,
    required this.districtName,
    required this.provinceName,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      districtId: json['district_id'] as int,
      districtName: json['district_name'] as String,
      provinceName: json['province_name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'district_id': districtId,
        'district_name': districtName,
        'province_name': provinceName,
      };
}

class DistrictResponse {
  final String code;
  final String messages;
  final List<DistrictModel> data;

  const DistrictResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory DistrictResponse.fromJson(Map<String, dynamic> json) {
    return DistrictResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => DistrictModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
