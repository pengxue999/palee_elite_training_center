import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/province_model.dart';
import '../services/province_service.dart';

final provinceServiceProvider = Provider<ProvinceService>((_) => ProvinceService());

class ProvinceState {
  final List<ProvinceModel> provinces;
  final bool isLoading;
  final String? error;

  const ProvinceState({
    this.provinces = const [],
    this.isLoading = false,
    this.error,
  });

  ProvinceState copyWith({
    List<ProvinceModel>? provinces,
    bool? isLoading,
    String? error,
  }) {
    return ProvinceState(
      provinces: provinces ?? this.provinces,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProvinceNotifier extends StateNotifier<ProvinceState> {
  final ProvinceService _service;

  ProvinceNotifier(this._service) : super(const ProvinceState());

  Future<void> getProvinces() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getProvinces();
      state = state.copyWith(provinces: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final provinceProvider = StateNotifierProvider<ProvinceNotifier, ProvinceState>(
  (ref) => ProvinceNotifier(ref.read(provinceServiceProvider)),
);
