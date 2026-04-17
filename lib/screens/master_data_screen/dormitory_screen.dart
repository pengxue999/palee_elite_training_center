import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/dormitory_model.dart';
import '../../providers/dormitory_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/success_overlay.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';

class DormitoryScreen extends ConsumerStatefulWidget {
  const DormitoryScreen({super.key});

  @override
  ConsumerState<DormitoryScreen> createState() => _DormitoryScreenState();
}

class _DormitoryScreenState extends ConsumerState<DormitoryScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  DormitoryModel? selectedItem;
  bool isEditing = false;

  static const List<String> _genders = ['ຊາຍ', 'ຍິງ'];

  String _selectedGender = 'ຊາຍ';
  final _capacityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(dormitoryProvider.notifier).getDormitories();
      if (mounted) {
        final error = ref.read(dormitoryProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    _selectedGender = 'ຊາຍ';
    _capacityController.clear();
    selectedItem = null;
    isEditing = false;
  }

  String _normalizeGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'm':
        return 'ຊາຍ';
      case 'female':
      case 'f':
        return 'ຍິງ';
      case 'ຊາຍ':
      case 'ຍິງ':
        return gender;
      default:
        return 'ຊາຍ';
    }
  }

  void _openAdd() {
    _resetForm();
    setState(() {
      showAddEditModal = true;
      isEditing = false;
    });
  }

  void _openEdit(DormitoryModel item) {
    _selectedGender = item.gender;
    _capacityController.text = item.maxCapacity.toString();
    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    final capacity = int.tryParse(_capacityController.text.trim());
    if (capacity == null || capacity <= 0 || _selectedGender.isEmpty) {
      return;
    }

    final request = DormitoryRequest(
      gender: _selectedGender,
      maxCapacity: capacity,
    );
    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(dormitoryProvider.notifier)
          .updateDormitory(selectedItem!.dormitoryId, request);
    } else {
      success = await ref
          .read(dormitoryProvider.notifier)
          .createDormitory(request);
    }
    if (success && mounted) {
      SuccessOverlay.show(
        context,
        message: isEditing ? 'ອັບເດດຫໍພັກສຳເລັດ' : 'ເພີ່ມຫໍພັກສຳເລັດ',
      );
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(dormitoryProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(DormitoryModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem == null) return;
    final success = await ref
        .read(dormitoryProvider.notifier)
        .deleteDormitory(selectedItem!.dormitoryId);

    if (mounted) {
      setState(() {
        showDeleteDialog = false;
      });
    }

    if (success && mounted) {
      SuccessOverlay.show(context, message: 'ລຶບຫໍພັກສຳເລັດ');
      setState(() {
        selectedItem = null;
      });
    } else if (mounted) {
      final errorMessage = ref.read(dormitoryProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
      );
    }
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dormitoryProvider);
    final isLoading = state.isLoading && state.dormitories.isEmpty;

    final columns = [
      DataColumnDef<DormitoryModel>(
        key: 'dormitoryId',
        label: 'ລະຫັດ',
        flex: 1,
        render: (_, item) =>
            Text('${item.dormitoryId}', style: const TextStyle(fontSize: 13)),
      ),
      DataColumnDef<DormitoryModel>(
        key: 'gender',
        label: 'ເພດ',
        flex: 2,
        render: (_, item) => Text(
          _normalizeGender(item.gender),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      DataColumnDef<DormitoryModel>(
        key: 'maxCapacity',
        label: 'ຈຳນວນທີ່ຮອງຮັບ (ຄົນ)',
        flex: 3,
        render: (_, item) => Text(
          '${item.maxCapacity} ຄົນ',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: AppDataTable<DormitoryModel>(
                  data: isLoading ? _getMockDormitories() : state.dormitories,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: _openEdit,
                  onDelete: _confirmDelete,
                  searchKeys: const ['dormitoryName', 'dormitoryType'],
                  addLabel: 'ເພີ່ມຫໍພັກ',
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  List<DormitoryModel> _getMockDormitories() {
    return List.generate(
      5,
      (index) => DormitoryModel(
        dormitoryId: index + 1,
        gender: index % 2 == 0 ? 'ຊາຍ' : 'ຍິງ',
        maxCapacity: 50 + (index * 10),
      ),
    );
  }

  bool get _isFormValid {
    return _capacityController.text.isNotEmpty;
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(dormitoryProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂຫໍພັກ' : 'ເພີ່ມຫໍພັກໃໝ່',
          size: AppDialogSize.medium,
          onClose: () => setState(() {
            showAddEditModal = false;
            _resetForm();
          }),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() {
                  showAddEditModal = false;
                  _resetForm();
                }),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: isEditing ? 'ຢືນຢັນ' : 'ບັນທຶກ',
                icon: Icons.save_rounded,
                onPressed: (isLoading || !_isFormValid) ? null : _save,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDropdown<String>(
                label: 'ເພດ',
                value: _selectedGender,
                items: _genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() {
                  if (v != null) _selectedGender = v;
                }),
                required: true,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'ຈຳນວນທີ່ຮອງຮັບ (ຄົນ)',
                hint: 'ເຊັ່ນ: 50',
                controller: _capacityController,
                required: true,
                keyboardType: TextInputType.number,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                digitOnly: DigitOnly.integer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(dormitoryProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: 'ຢືນຢັນການລຶບ',
          size: AppDialogSize.small,
          onClose: () => setState(() {
            showDeleteDialog = false;
            selectedItem = null;
          }),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() {
                  showDeleteDialog = false;
                  selectedItem = null;
                }),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'ລຶບ',
                icon: Icons.delete_rounded,
                variant: AppButtonVariant.danger,
                onPressed: isLoading ? null : _delete,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: AppColors.warning,
              ),
              const SizedBox(height: 16),
              Text(
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.displayName}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
