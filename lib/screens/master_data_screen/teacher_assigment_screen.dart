import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/format_utils.dart';
import '../../models/subject_detail_model.dart';
import '../../models/teacher_assignment_model.dart';
import '../../providers/teacher_assignment_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/subject_detail_provider.dart';
import '../../providers/academic_year_provider.dart';
import '../../widgets/app_alerts.dart';
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

  Widget _buildSubjectGrid(List<SubjectDetailModel> subjectDetails) {
    final subjects = subjectDetails.map((sd) => sd.subjectName).toSet().toList()
      ..sort();

    final filteredDetails = _selectedSubjectFilter == null
        ? subjectDetails
        : subjectDetails
              .where((sd) => sd.subjectName == _selectedSubjectFilter)
              .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < Breakpoints.desktop;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildSectionTitle()],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildSectionTitle()),
                      const SizedBox(width: 16),
                    ],
                  ),
            const SizedBox(height: 16),
            if (subjects.isNotEmpty) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildSubjectFilterChip(
                    label: 'ທັງໝົດ',
                    isSelected: _selectedSubjectFilter == null,
                    onTap: () => setState(() => _selectedSubjectFilter = null),
                    showCheck: false,
                  ),
                  ...subjects.map((subject) {
                    return _buildSubjectFilterChip(
                      label: subject,
                      isSelected: _selectedSubjectFilter == subject,
                      onTap: () =>
                          setState(() => _selectedSubjectFilter = subject),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 380,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF8FBFF),
                        AppColors.primaryLight.withOpacity(0.28),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: subjectDetails.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(
                                        0.08,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.menu_book_outlined,
                                  size: 28,
                                  color: AppColors.primary.withOpacity(0.75),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'ບໍ່ມີຂໍ້ມູນວິຊາ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.foreground,
                                  fontFamily: 'NotoSansLao',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ເພີ່ມຂໍ້ມູນວິຊາແລະລະດັບກ່ອນ ແລ້ວຈຶ່ງຈະສາມາດກຳນົດການສອນໄດ້',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedForeground,
                                  fontFamily: 'NotoSansLao',
                                ),
                              ),
                            ],
                          ),
                        )
                      : filteredDetails.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_list_off,
                                size: 28,
                                color: AppColors.mutedForeground,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'ບໍ່ພົບລາຍການສຳລັບວິຊານີ້',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.mutedForeground,
                                  fontFamily: 'NotoSansLao',
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, gridConstraints) {
                            final width = gridConstraints.maxWidth;
                            int crossAxisCount = 4;
                            if (width < 620) {
                              crossAxisCount = 1;
                            } else if (width < Breakpoints.desktop) {
                              crossAxisCount = 4;
                            } else if (width < 1240) {
                              crossAxisCount = 6;
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    mainAxisExtent: 112,
                                  ),
                              itemCount: filteredDetails.length,
                              itemBuilder: (context, index) {
                                final sd = filteredDetails[index];
                                final isSelected =
                                    sd.subjectDetailId ==
                                    _selectedSubjectDetailId;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => setState(
                                      () => _selectedSubjectDetailId =
                                          sd.subjectDetailId,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFFEAF3FF),
                                                  Color(0xFFDDEBFF),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : const LinearGradient(
                                                colors: [
                                                  Colors.white,
                                                  Color(0xFFF8FAFC),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.border,
                                          width: isSelected ? 1.8 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? AppColors.primary.withOpacity(
                                                    0.16,
                                                  )
                                                : const Color(
                                                    0xFF0F172A,
                                                  ).withOpacity(0.05),
                                            blurRadius: isSelected ? 18 : 10,
                                            offset: Offset(
                                              0,
                                              isSelected ? 10 : 4,
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? AppColors.primary
                                                              .withOpacity(0.12)
                                                        : AppColors.background,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    sd.subjectName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isSelected
                                                          ? AppColors
                                                                .primaryDark
                                                          : AppColors
                                                                .mutedForeground,
                                                      fontFamily: 'NotoSansLao',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 220,
                                                ),
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : AppColors.border,
                                                  ),
                                                ),
                                                child: Icon(
                                                  isSelected
                                                      ? Icons.check_rounded
                                                      : Icons
                                                            .arrow_forward_rounded,
                                                  size: 16,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : AppColors
                                                            .mutedForeground,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text(
                                            sd.levelName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w800,
                                              color: isSelected
                                                  ? AppColors.primaryDark
                                                  : AppColors.foreground,
                                              letterSpacing: 0.1,
                                              fontFamily: 'NotoSansLao',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isSelected
                                                ? 'ກຳລັງເລືອກຢູ່'
                                                : 'ກົດເພື່ອເລືອກວິຊານີ້',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.mutedForeground,
                                              fontFamily: 'NotoSansLao',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ເລືອກວິຊາ ແລະ ຊັ້ນຮຽນ/ລະດັບ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: AppColors.foreground,
                fontFamily: 'NotoSansLao',
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.destructive,
                fontFamily: 'NotoSansLao',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubjectFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool showCheck = true,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? null : Colors.white,
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.18)
                    : const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: isSelected ? 14 : 8,
                offset: Offset(0, isSelected ? 8 : 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCheck && isSelected) ...[
                const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.foreground,
                  fontFamily: 'NotoSansLao',
                ),
              ),
            ],
          ),
        ),
      ),
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
          child: SingleChildScrollView(
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
                        onChanged: (v) =>
                            setState(() => _selectedAcademicId = v),
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
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
