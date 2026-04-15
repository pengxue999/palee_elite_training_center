class ProvinceModel {
  final int provinceId;
  final String provinceName;

  const ProvinceModel({
    required this.provinceId,
    required this.provinceName,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      provinceId: json['province_id'] as int,
      provinceName: json['province_name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'province_id': provinceId,
        'province_name': provinceName,
      };
}

class ProvinceResponse {
  final String code;
  final String messages;
  final List<ProvinceModel> data;

  const ProvinceResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory ProvinceResponse.fromJson(Map<String, dynamic> json) {
    return ProvinceResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
