import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../models/unit_model.dart';
import '../../providers/unit_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';

class UnitScreen extends ConsumerStatefulWidget {
  const UnitScreen({super.key});

  @override
  ConsumerState<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends ConsumerState<UnitScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  UnitModel? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(unitProvider.notifier).getUnits();
      if (mounted) {
        final error = ref.read(unitProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    _nameController.clear();
    selectedItem = null;
    isEditing = false;
  }

  void _openAdd() {
    _resetForm();
    setState(() {
      showAddEditModal = true;
      isEditing = false;
    });
  }

  void _openEdit(UnitModel item) {
    _nameController.text = item.unitName;
    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    final request = UnitRequest(unitName: _nameController.text.trim());
    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(unitProvider.notifier)
          .updateUnit(selectedItem!.unitId, request);
    } else {
      success = await ref.read(unitProvider.notifier).createUnit(request);
    }
    if (success && mounted) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(unitProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(UnitModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem == null) return;
    final success = await ref
        .read(unitProvider.notifier)
        .deleteUnit(selectedItem!.unitId);

    if (mounted) {
      setState(() {
        showDeleteDialog = false;
      });
    }

    if (success && mounted) {
      setState(() {
        selectedItem = null;
      });
    } else if (mounted) {
      final errorMessage = ref.read(unitProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unitProvider);
    final isLoading = state.isLoading && state.units.isEmpty;

    final columns = [
      DataColumnDef<UnitModel>(key: 'unitId', label: 'ລະຫັດ', flex: 1),
      DataColumnDef<UnitModel>(key: 'unitName', label: 'ຊື່ຫົວໜ່ວຍ', flex: 5),
    ];

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppDataTable<UnitModel>(
                  data: isLoading ? _getMockUnits() : state.units,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: _openEdit,
                  onDelete: _confirmDelete,
                  searchKeys: const ['unitName'],
                  addLabel: 'ເພີ່ມຫົວໜ່ວຍ',
                  isLoading: isLoading,
                ),
              ),
            ),
          ],
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  List<UnitModel> _getMockUnits() {
    return List.generate(
      5,
      (index) => UnitModel(unitId: index + 1, unitName: 'ຫົວໜ່ວຍ ${index + 1}'),
    );
  }

  bool get _isFormValid {
    return _nameController.text.isNotEmpty;
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(unitProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂຫົວໜ່ວຍ' : 'ເພີ່ມຫົວໜ່ວຍໃໝ່',
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
                isLoading: isLoading,
                onPressed: (isLoading || !_isFormValid) ? null : _save,
              ),
            ],
          ),
          child: AppTextField(
            label: 'ຫົວໜ່ວຍ',
            hint: 'ປ້ອນຫົວນ່ວຍ',
            controller: _nameController,
            required: true,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(unitProvider).isLoading;
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
                isLoading: isLoading,
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
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.unitName}"?',
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
