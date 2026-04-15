import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../models/teacher_assignment_model.dart';
import '../../providers/teacher_assignment_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/subject_detail_provider.dart';
import '../../providers/academic_year_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/success_overlay.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';

class TeacherAssigmentScreen extends ConsumerStatefulWidget {
  const TeacherAssigmentScreen({super.key});

  @override
  ConsumerState<TeacherAssigmentScreen> createState() =>
      _TeacherAssigmentScreenState();
}

class _TeacherAssigmentScreenState
    extends ConsumerState<TeacherAssigmentScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  TeacherAssignmentModel? selectedItem;
  bool isEditing = false;

  final _hourlyRateController = TextEditingController();
  String? _selectedTeacherId;
  String? _selectedSubjectDetailId;
  String? _selectedAcademicId;
  String? _selectedSubjectFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(teacherAssignmentProvider.notifier).getAssignments();
      ref.read(teacherProvider.notifier).getTeachers();
      ref.read(subjectDetailProvider.notifier).getSubjectDetails();
      ref.read(academicYearProvider.notifier).getAcademicYears();
      if (mounted) {
        final error = ref.read(teacherAssignmentProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    _hourlyRateController.clear();
    _selectedTeacherId = null;
    _selectedSubjectDetailId = null;
    _selectedAcademicId = null;
    _selectedSubjectFilter = null;
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

  void _openEdit(TeacherAssignmentModel item) {
    _hourlyRateController.text = item.hourlyRate.toStringAsFixed(0);

    final teachers = ref.read(teacherProvider).teachers;
    final teacher = teachers
        .where(
          (t) =>
              t.teacherName == item.teacherName &&
              t.teacherLastname == item.teacherLastname,
        )
        .firstOrNull;
    _selectedTeacherId = teacher?.teacherId;

    final subjectDetails = ref.read(subjectDetailProvider).subjectDetails;
    final sd = subjectDetails
        .where(
          (s) =>
              s.subjectName == item.subjectName &&
              s.levelName == item.levelName,
        )
        .firstOrNull;
    _selectedSubjectDetailId = sd?.subjectDetailId;

    final academicYears = ref.read(academicYearProvider).academicYears;
    final ay = academicYears
        .where((a) => a.academicYear == item.academicYear)
        .firstOrNull;
    _selectedAcademicId = ay?.academicId;

    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    if (_selectedTeacherId == null ||
        _selectedSubjectDetailId == null ||
        _selectedAcademicId == null ||
        _hourlyRateController.text.isEmpty) {
      return;
    }

    final hourlyRate =
        double.tryParse(_hourlyRateController.text.replaceAll(',', '')) ?? 0;

    final request = TeacherAssignmentRequest(
      teacherId: _selectedTeacherId!,
      subjectDetailId: _selectedSubjectDetailId!,
      academicId: _selectedAcademicId!,
      hourlyRate: hourlyRate,
    );

    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(teacherAssignmentProvider.notifier)
          .updateAssignment(selectedItem!.assignmentId, request);
    } else {
      success = await ref
          .read(teacherAssignmentProvider.notifier)
          .createAssignment(request);
    }

    if (success && mounted) {
      SuccessOverlay.show(
        context,
        message: isEditing ? 'ອັບເດດການມອບໝາຍສຳເລັດ' : 'ເພີ່ມການມອບໝາຍສຳເລັດ',
      );
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(teacherAssignmentProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(TeacherAssignmentModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem == null) return;
    final success = await ref
        .read(teacherAssignmentProvider.notifier)
        .deleteAssignment(selectedItem!.assignmentId);

    if (mounted) {
      setState(() {
        showDeleteDialog = false;
      });
    }

    if (success && mounted) {
      SuccessOverlay.show(context, message: 'ລຶບການມອບໝາຍສຳເລັດ');
      setState(() {
        selectedItem = null;
      });
    } else if (mounted) {
      final errorMessage = ref.read(teacherAssignmentProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
      );
    }
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignmentState = ref.watch(teacherAssignmentProvider);
    final isLoading =
        assignmentState.isLoading && assignmentState.assignments.isEmpty;

    final columns = [
      DataColumnDef<TeacherAssignmentModel>(
        key: 'assignmentId',
        label: 'ລະຫັດ',
        flex: 2,
        render: (v, row) => Text(
          v.toString(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      DataColumnDef<TeacherAssignmentModel>(
        key: 'teacherFullName',
        label: 'ອາຈານ',
        flex: 3,
        render: (v, row) => Text(row.teacherFullName),
      ),
      DataColumnDef<TeacherAssignmentModel>(
        key: 'subjectLabel',
        label: 'ວິຊາ & ຊັ້ນ',
        flex: 3,
        render: (v, row) => Text(row.subjectLabel),
      ),
      DataColumnDef<TeacherAssignmentModel>(
        key: 'academicYear',
        label: 'ສົກຮຽນ',
        flex: 2,
        render: (v, row) => Text(row.academicYear),
      ),
      DataColumnDef<TeacherAssignmentModel>(
        key: 'hourlyRate',
        label: 'ອັດຕາ/ຊ.ມ (₭)',
        flex: 2,
        render: (v, row) => Text(
          FormatUtils.formatKip(row.hourlyRate.toInt()),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
      ),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppDataTable<TeacherAssignmentModel>(
                  title: 'ຂໍ້ມູນການມອບໝາຍສອນ',
                  subtitle:
                      'ທັງໝົດ ${assignmentState.assignments.length} ລາຍການ',
                  data: isLoading
                      ? _getMockAssignments()
                      : assignmentState.assignments,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: _openEdit,
                  onDelete: _confirmDelete,
                  searchKeys: const [
                    'assignmentId',
                    'teacherFullName',
                    'subjectLabel',
                    'academicYear',
                  ],
                  addLabel: 'ເພີ່ມຂໍ້ມູນການສອນ',
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

  List<TeacherAssignmentModel> _getMockAssignments() {
    return List.generate(
      5,
      (index) => TeacherAssignmentModel(
        assignmentId: 'TA00${index + 1}',
        teacherId: 'TC${index + 1}',
        teacherName: 'ອາຈານ ${index + 1}',
        teacherLastname: 'ທ້າວ',
        subjectName: 'ວິຊາ ${index + 1}',
        levelName: 'ຊັ້ນ ${index + 1}',
        academicYear: '2024-2025',
        hourlyRate: 30000 + (index * 5000),
      ),
    );
  }

  bool get _isFormValid {
    return _selectedTeacherId != null &&
        _selectedSubjectDetailId != null &&
        _selectedAcademicId != null &&
        _hourlyRateController.text.isNotEmpty;
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
              color: _selectedSubjectDetailId != null
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.border.withOpacity(0.5),
              width: _selectedSubjectDetailId != null ? 1.5 : 1,
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
                          sd.subjectDetailId == _selectedSubjectDetailId;

                      return InkWell(
                        onTap: () => setState(
                          () => _selectedSubjectDetailId = sd.subjectDetailId,
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
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 12,
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

  Widget _buildFormModal() {
    final assignmentState = ref.watch(teacherAssignmentProvider);
    final teachers = ref.watch(teacherProvider).teachers;
    final subjectDetails = ref.watch(subjectDetailProvider).subjectDetails;
    final academicYears = ref.watch(academicYearProvider).academicYears;

    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂຂໍ້ມູນການສອນ' : 'ເພີ່ມຂໍ້ມູນການສອນໃໝ່',
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
                icon: Icons.save_rounded,
                isLoading: assignmentState.isLoading,
                onPressed: (assignmentState.isLoading || !_isFormValid)
                    ? null
                    : _save,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDropdown<String>(
                label: 'ອາຈານ',
                hint: 'ເລືອກອາຈານ',
                value: teachers.any((t) => t.teacherId == _selectedTeacherId)
                    ? _selectedTeacherId
                    : null,
                required: true,
                items: teachers
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.teacherId,
                        child: Text(t.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedTeacherId = v),
              ),
              const SizedBox(height: 16),
              _buildSubjectGrid(subjectDetails),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppDropdown<String>(
                      label: 'ສົກຮຽນ',
                      hint: 'ເລືອກສົກຮຽນ',
                      value:
                          academicYears.any(
                            (a) => a.academicId == _selectedAcademicId,
                          )
                          ? _selectedAcademicId
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
                      onChanged: (v) => setState(() => _selectedAcademicId = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'ອັດຕາຄ່າສອນຕໍ່ຊົ່ວໂມງ',
                      hint: 'ເຊັ່ນ: 50,000',
                      controller: _hourlyRateController,
                      keyboardType: TextInputType.number,
                      digitOnly: DigitOnly.integer,
                      thousandsSeparator: true,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      required: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final assignmentState = ref.watch(teacherAssignmentProvider);
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
                isLoading: assignmentState.isLoading,
                onPressed: assignmentState.isLoading ? null : _delete,
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
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.teacherFullName} - ${selectedItem!.subjectLabel}"?',
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
