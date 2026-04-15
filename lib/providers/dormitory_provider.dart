import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dormitory_model.dart';
import '../services/dormitory_service.dart';

final dormitoryServiceProvider =
    Provider<DormitoryService>((_) => DormitoryService());

class DormitoryState {
  final List<DormitoryModel> dormitories;
  final bool isLoading;
  final String? error;

  const DormitoryState({
    this.dormitories = const [],
    this.isLoading = false,
    this.error,
  });

  DormitoryState copyWith({
    List<DormitoryModel>? dormitories,
    bool? isLoading,
    String? error,
  }) {
    return DormitoryState(
      dormitories: dormitories ?? this.dormitories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DormitoryNotifier extends StateNotifier<DormitoryState> {
  final DormitoryService _service;

  DormitoryNotifier(this._service) : super(const DormitoryState());

  Future<void> getDormitories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getDormitories();
      state = state.copyWith(dormitories: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createDormitory(DormitoryRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createDormitory(request);
      await getDormitories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateDormitory(
      int dormitoryId, DormitoryRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateDormitory(dormitoryId, request);
      await getDormitories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteDormitory(int dormitoryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteDormitory(dormitoryId);
      state = state.copyWith(
        dormitories: state.dormitories
            .where((d) => d.dormitoryId != dormitoryId)
            .toList(),
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

final dormitoryProvider =
    StateNotifierProvider<DormitoryNotifier, DormitoryState>(
  (ref) => DormitoryNotifier(ref.read(dormitoryServiceProvider)),
);
