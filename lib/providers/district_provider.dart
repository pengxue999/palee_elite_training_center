import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/services/district_serivice.dart';
import '../models/district_model.dart';

final districtServiceProvider =
    Provider<DistrictService>((_) => DistrictService());

class DistrictState {
  final List<DistrictModel> districts;
  final List<DistrictModel> filteredDistricts;
  final bool isLoading;
  final String? error;

  const DistrictState({
    this.districts = const [],
    this.filteredDistricts = const [],
    this.isLoading = false,
    this.error,
  });

  DistrictState copyWith({
    List<DistrictModel>? districts,
    List<DistrictModel>? filteredDistricts,
    bool? isLoading,
    String? error,
  }) {
    return DistrictState(
      districts: districts ?? this.districts,
      filteredDistricts: filteredDistricts ?? this.filteredDistricts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DistrictNotifier extends StateNotifier<DistrictState> {
  final DistrictService _service;

  DistrictNotifier(this._service) : super(const DistrictState());

  Future<void> getDistricts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getDistricts();
      state = state.copyWith(districts: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> getDistrictsByProvince(int provinceId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getDistrictsByProvince(provinceId);
      state = state.copyWith(filteredDistricts: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearDistricts() {
    state = state.copyWith(filteredDistricts: []);
  }
}

final districtProvider =
    StateNotifierProvider<DistrictNotifier, DistrictState>(
  (ref) => DistrictNotifier(ref.read(districtServiceProvider)),
);
