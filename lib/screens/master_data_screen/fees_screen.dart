import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/utils/format_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../models/fee_model.dart';
import '../../providers/fee_provider.dart';
import '../../providers/subject_detail_provider.dart';
import '../../providers/academic_year_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/success_overlay.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_dropdown.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  FeeModel? selectedItem;
  bool isEditing = false;

  String? selectedSubjectDetailId;
  String? selectedAcademicId;
  String? _selectedSubjectFilter;
  final _feeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(feeProvider.notifier).getFees();
      ref.read(subjectDetailProvider.notifier).getSubjectDetails();
      ref.read(academicYearProvider.notifier).getAcademicYears();
      if (mounted) {
        final error = ref.read(feeProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    selectedSubjectDetailId = null;
    selectedAcademicId = null;
    _selectedSubjectFilter = null;
    _feeController.clear();
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

  void _openEdit(FeeModel item) {
    final subjectDetails = ref.read(subjectDetailProvider).subjectDetails;
    final academicYears = ref.read(academicYearProvider).academicYears;

    final subjectDetail = subjectDetails
        .where(
          (sd) =>
              sd.subjectName == item.subjectName &&
              sd.levelName == item.levelName,
        )
        .firstOrNull;
    final academic = academicYears
        .where((a) => a.academicYear == item.academicYear)
        .firstOrNull;

    selectedSubjectDetailId = subjectDetail?.subjectDetailId;
    selectedAcademicId = academic?.academicId;
    _feeController.text = item.fee.toStringAsFixed(0);

    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    if (selectedSubjectDetailId == null ||
        selectedAcademicId == null ||
        _feeController.text.isEmpty) {
      return;
    }

    final feeValue =
        double.tryParse(_feeController.text.replaceAll(',', '')) ?? 0;
    final request = FeeRequest(
      subjectDetailId: selectedSubjectDetailId!,
      academicId: selectedAcademicId!,
      fee: feeValue,
    );

    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(feeProvider.notifier)
          .updateFee(selectedItem!.feeId, request);
    } else {
      success = await ref.read(feeProvider.notifier).createFee(request);
    }

    if (success && mounted) {
      SuccessOverlay.show(
        context,
        message: isEditing ? 'ອັບເດດຄ່າທຳນຽມສຳເລັດ' : 'ເພີ່ມຄ່າທຳນຽມສຳເລັດ',
      );
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(feeProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(FeeModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem != null) {
      final success = await ref
          .read(feeProvider.notifier)
          .deleteFee(selectedItem!.feeId);

      if (mounted) {
        setState(() {
          showDeleteDialog = false;
        });
      }

      if (success && mounted) {
        SuccessOverlay.show(context, message: 'ລຶບຄ່າທຳນຽມສຳເລັດ');
        setState(() {
          selectedItem = null;
        });
      } else if (mounted) {
        final errorMessage = ref.read(feeProvider).error;
        ApiErrorHandler.handle(
          context,
          errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
        );
      }
    }
  }

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feeState = ref.watch(feeProvider);
    final isLoading = feeState.isLoading && feeState.fees.isEmpty;

    final columns = [
      DataColumnDef<FeeModel>(key: 'feeId', label: 'ລະຫັດ', flex: 1),
      DataColumnDef<FeeModel>(key: 'subjectName', label: 'ວິຊາ', flex: 2),
      DataColumnDef<FeeModel>(key: 'levelName', label: 'ລະດັບ', flex: 2),
      DataColumnDef<FeeModel>(key: 'academicYear', label: 'ສົກຮຽນ', flex: 2),
      DataColumnDef<FeeModel>(
        key: 'fee',
        label: 'ຄ່າທຳນຽມ',
        flex: 2,
        render: (value, item) => Text(FormatUtils.formatKip(item.fee.toInt())),
      ),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: AppDataTable<FeeModel>(
            key: ValueKey('fees_table_${feeState.fees.length}_$isLoading'),
            data: isLoading ? _getMockFees() : feeState.fees,
            columns: columns,
            onAdd: _openAdd,
            onEdit: _openEdit,
            onDelete: _confirmDelete,
            searchKeys: const ['subjectName', 'levelName', 'academicYear'],
            addLabel: 'ເພີ່ມຄ່າທຳນຽມ',
            isLoading: isLoading,
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  List<FeeModel> _getMockFees() {
    return List.generate(
      5,
      (index) => FeeModel(
        feeId: 'FEE00${index + 1}',
        subjectName: 'ວິຊາ ${index + 1}',
        levelName: 'ຊັ້ນ ${index + 1}',
        academicYear: '2024-2025',
        fee: 500000 + (index * 100000),
        subjectCategory: '',
      ),
    );
  }

  bool get _isFormValid {
    return selectedSubjectDetailId != null &&
        selectedAcademicId != null &&
        _feeController.text.isNotEmpty;
  }

  Widget _buildFormModal() {
    final subjectDetails = ref.watch(subjectDetailProvider).subjectDetails;
    final academicYears = ref.watch(academicYearProvider).academicYears;
    final isLoading = ref.watch(feeProvider).isLoading;

    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂຄ່າທຳນຽມ' : 'ເພີ່ມຄ່າທຳນຽມໃໝ່',
          size: AppDialogSize.large,
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
                onPressed: (isLoading || !_isFormValid) ? null : _save,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                AppDropdown<String>(
                  label: 'ສົກຮຽນ',
                  hint: 'ເລືອກສົກຮຽນ',
                  value:
                      academicYears.any(
                        (a) => a.academicId == selectedAcademicId,
                      )
                      ? selectedAcademicId
                      : null,
                  required: true,
                  items: academicYears
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.academicId,
                          child: Text(a.academicYear),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedAcademicId = v),
                ),
                const SizedBox(height: 16),
                _buildSubjectGrid(subjectDetails),

                const SizedBox(height: 16),
                AppTextField(
                  label: 'ຄ່າທຳນຽມ',
                  hint: 'ເຊັ່ນ: 500000',
                  controller: _feeController,
                  required: true,
                  keyboardType: TextInputType.number,
                  digitOnly: DigitOnly.integer,
                  thousandsSeparator: true,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectGrid(subjectDetails) {
    final subjects = subjectDetails.map((sd) => sd.subjectName).toSet().toList()
      ..sort();

    final filteredDetails = _selectedSubjectFilter == null
        ? subjectDetails
        : subjectDetails
              .where((sd) => sd.subjectName == _selectedSubjectFilter)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ເລືອກວິຊາ ແລະ ຊັ້ນຮຽນ/ລະດັບ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: AppColors.foreground.withOpacity(0.85),
                fontFamily: 'NotoSansLao',
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.destructive,
                fontFamily: 'NotoSansLao',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (subjects.isNotEmpty)
          Container(
            height: 48,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: subjects.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedSubjectFilter == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        'ທັງໝົດ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.foreground,
                          fontFamily: 'NotoSansLao',
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedSubjectFilter = null),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.muted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  );
                }
                final subject = subjects[index - 1];
                final isSelected = _selectedSubjectFilter == subject;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.foreground,
                        fontFamily: 'NotoSansLao',
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedSubjectFilter = subject),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.muted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    showCheckmark: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                );
              },
            ),
          ),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: AppColors.input,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedSubjectDetailId != null
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.border.withOpacity(0.5),
              width: selectedSubjectDetailId != null ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: subjectDetails.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 32,
                          color: AppColors.mutedForeground.withOpacity(0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ບໍ່ມີຂໍ້ມູນວິຊາ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground.withOpacity(0.6),
                            fontFamily: 'NotoSansLao',
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: filteredDetails.length,
                    itemBuilder: (context, index) {
                      final sd = filteredDetails[index];
                      final isSelected =
                          sd.subjectDetailId == selectedSubjectDetailId;

                      return InkWell(
                        onTap: () => setState(
                          () => selectedSubjectDetailId = sd.subjectDetailId,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border.withOpacity(0.5),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(
                                        0.15,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        sd.subjectName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.foreground
                                                    .withOpacity(0.8),
                                          fontFamily: 'NotoSansLao',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sd.levelName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? AppColors.primary.withOpacity(
                                                  0.8,
                                                )
                                              : AppColors.mutedForeground,
                                          fontFamily: 'NotoSansLao',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(feeProvider).isLoading;
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
                onPressed: isLoading ? null : _delete,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.subjectName} - ${selectedItem!.levelName}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 8),
              const Text(
                '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
