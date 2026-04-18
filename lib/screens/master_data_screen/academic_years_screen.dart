import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/academic_year_model.dart';
import '../../providers/academic_year_provider.dart';
import '../../widgets/app_alerts.dart';

import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_date_field.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_button.dart';

class AcademicYearsScreen extends ConsumerStatefulWidget {
  const AcademicYearsScreen({super.key});

  @override
  ConsumerState<AcademicYearsScreen> createState() =>
      _AcademicYearsScreenState();
}

class _AcademicYearsScreenState extends ConsumerState<AcademicYearsScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  AcademicYearModel? selectedItem;
  bool isEditing = false;

  final _yearController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  String _selectedStatus = 'ດໍາເນີນການ';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(academicYearProvider.notifier).getAcademicYears();
      if (mounted) {
        final error = ref.read(academicYearProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    _yearController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _selectedStatus = 'ດໍາເນີນການ';
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

  String _toIsoDate(String ddMmYyyy) {
    final parts = ddMmYyyy.split('-');
    if (parts.length == 3 && parts[0].length == 2) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return ddMmYyyy;
  }

  void _openEdit(AcademicYearModel item) {
    _yearController.text = item.academicYear;
    _startDateController.text = _toIsoDate(item.startDate);
    _endDateController.text = _toIsoDate(item.endDate);
    _selectedStatus = item.academicStatus;
    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    if (_yearController.text.trim().isEmpty ||
        _startDateController.text.isEmpty ||
        _endDateController.text.isEmpty) {
      return;
    }

    final request = AcademicYearRequest(
      academicYear: _yearController.text,
      startDate: _startDateController.text,
      endDate: _endDateController.text,
      academicStatus: _selectedStatus,
    );

    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(academicYearProvider.notifier)
          .updateAcademicYear(selectedItem!.academicId!, request);
    } else {
      success = await ref
          .read(academicYearProvider.notifier)
          .createAcademicYear(request);
    }

    if (success && mounted) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(academicYearProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(AcademicYearModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem != null) {
      final success = await ref
          .read(academicYearProvider.notifier)
          .deleteAcademicYear(selectedItem!.academicId!);

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
        final errorMessage = ref.read(academicYearProvider).error;
        ApiErrorHandler.handle(
          context,
          errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
        );
      }
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) =>
      status == 'ດໍາເນີນການ' ? AppColors.success : AppColors.mutedForeground;

  @override
  Widget build(BuildContext context) {
    final academicYearState = ref.watch(academicYearProvider);
    final items = academicYearState.academicYears.isNotEmpty
        ? academicYearState.academicYears
        : <AcademicYearModel>[];
    final isLoading = academicYearState.isLoading && items.isEmpty;

    final columns = [
      DataColumnDef<AcademicYearModel>(
        key: 'academicId',
        label: 'ລະຫັດ',
        flex: 1,
      ),
      DataColumnDef<AcademicYearModel>(
        key: 'academicYear',
        label: 'ສົກຮຽນ',
        flex: 2,
      ),
      DataColumnDef<AcademicYearModel>(
        key: 'startDate',
        label: 'ເລີ່ມຮຽນ',
        flex: 2,
      ),
      DataColumnDef<AcademicYearModel>(
        key: 'endDate',
        label: 'ສິ້ນສຸດຮຽນ',
        flex: 2,
      ),
      DataColumnDef<AcademicYearModel>(
        key: 'academicStatus',
        label: 'ສະຖານະ',
        flex: 2,
        render: (value, row) => Text(
          value,
          style: TextStyle(
            color: _statusColor(value),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
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
                child: AppDataTable<AcademicYearModel>(
                  data: isLoading ? _getMockAcademicYears() : items,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: _openEdit,
                  onDelete: _confirmDelete,
                  searchKeys: const ['academicYear', 'academicStatus'],
                  addLabel: 'ເພີ່ມສົກຮຽນ',
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

  List<AcademicYearModel> _getMockAcademicYears() {
    return List.generate(
      5,
      (index) => AcademicYearModel(
        academicId: '${1000 + index + 1}',
        academicYear: '202${index + 4}-202${index + 5}',
        startDate: '01-09-202${index + 4}',
        endDate: '31-05-202${index + 5}',
        academicStatus: index % 2 == 0 ? 'ດໍາເນີນການ' : 'ສິ້ນສຸດ',
      ),
    );
  }

  bool get _isFormValid {
    return _yearController.text.isNotEmpty &&
        _startDateController.text.isNotEmpty &&
        _endDateController.text.isNotEmpty;
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(academicYearProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂສົກຮຽນ' : 'ເພີ່ມສົກຮຽນໃໝ່',
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
                icon: Icons.save,
                isLoading: isLoading,
                onPressed: (isLoading || !_isFormValid) ? null : _save,
              ),
            ],
          ),
          child: Column(
            children: [
              AppTextField(
                label: 'ສົກຮຽນ',
                hint: '2024-2025',
                controller: _yearController,
                required: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppDateField(
                      label: 'ວັນທີເລີ່ມ',
                      controller: _startDateController,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppDateField(
                      label: 'ວັນທີສິ້ນສຸດ',
                      controller: _endDateController,
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppDropdown<String>(
                label: 'ສະຖານະ',
                value: _selectedStatus,
                items: ['ດໍາເນີນການ', 'ສິ້ນສຸດ']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() {
                  if (v != null) _selectedStatus = v;
                }),
                required: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(academicYearProvider).isLoading;
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
                icon: Icons.delete,
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
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.academicYear}"?',
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
