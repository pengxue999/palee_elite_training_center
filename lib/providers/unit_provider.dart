import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/unit_model.dart';
import '../services/unit_service.dart';

final unitServiceProvider =
    Provider<UnitService>((_) => UnitService());

class UnitState {
  final List<UnitModel> units;
  final bool isLoading;
  final String? error;

  const UnitState({
    this.units = const [],
    this.isLoading = false,
    this.error,
  });

  UnitState copyWith({
    List<UnitModel>? units,
    bool? isLoading,
    String? error,
  }) {
    return UnitState(
      units: units ?? this.units,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UnitNotifier extends StateNotifier<UnitState> {
  final UnitService _service;

  UnitNotifier(this._service) : super(const UnitState());

  Future<void> getUnits() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getUnits();
      state = state.copyWith(units: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createUnit(UnitRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createUnit(request);
      await getUnits();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateUnit(int unitId, UnitRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateUnit(unitId, request);
      await getUnits();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteUnit(int unitId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteUnit(unitId);
      state = state.copyWith(
        units: state.units.where((u) => u.unitId != unitId).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final unitProvider = StateNotifierProvider<UnitNotifier, UnitState>(
  (ref) => UnitNotifier(ref.read(unitServiceProvider)),
);
