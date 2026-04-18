import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/format_utils.dart';
import 'package:palee_elite_training_center/models/evaluation_model.dart';
import 'package:palee_elite_training_center/providers/evaluation_provider.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_card.dart';
import 'package:palee_elite_training_center/widgets/app_data_table.dart';
import 'package:palee_elite_training_center/widgets/app_dropdown.dart';
import 'package:palee_elite_training_center/widgets/app_text_field.dart';
import 'package:palee_elite_training_center/widgets/success_overlay.dart';

class EvaluateStudentScreen extends ConsumerStatefulWidget {
  const EvaluateStudentScreen({super.key});

  @override
  ConsumerState<EvaluateStudentScreen> createState() =>
      _EvaluateStudentScreenState();
}

class _EvaluateStudentScreenState extends ConsumerState<EvaluateStudentScreen> {
  static const _semesters = [
    {'value': 'ກາງພາກ', 'label': 'ກາງພາກ'},
    {'value': 'ທ້າຍພາກ', 'label': 'ທ້າຍພາກ'},
  ];

  final Map<int, TextEditingController> _scoreControllers = {};
  final Map<int, TextEditingController> _prizeControllers = {};

  List<EvaluationScoreEntryStudent> _displayStudents = [];
  bool _hasScoreInput = false;

  String? _selectedSemester;
  String? _selectedSubjectId;
  String? _selectedSubjectDetailId;
  String? _selectedLevelId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSubjects();
    });
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    _scoreControllers.clear();

    for (final controller in _prizeControllers.values) {
      controller.dispose();
    }
    _prizeControllers.clear();
  }

  double? _readScore(int regisDetailId) {
    final rawScore =
        _scoreControllers[regisDetailId]?.text.trim().replaceAll(',', '') ?? '';
    if (rawScore.isEmpty) {
      return null;
    }
    return double.tryParse(rawScore);
  }

  double? _readPrize(int regisDetailId) {
    final rawPrize =
        _prizeControllers[regisDetailId]?.text.trim().replaceAll(',', '') ?? '';
    if (rawPrize.isEmpty) {
      return null;
    }
    return double.tryParse(rawPrize);
  }

  String _formatMoneyInput(double? value) {
    if (value == null) {
      return '';
    }

    return FormatUtils.formatNumber(value.toInt());
  }

  String _formatAverage(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  bool get _hasAnyScore => _displayStudents.any(
    (student) => _readScore(student.regisDetailId) != null,
  );

  void _handleScoreChanged() {
    final hasScoreInput = _hasAnyScore;
    if (hasScoreInput != _hasScoreInput) {
      setState(() {
        _hasScoreInput = hasScoreInput;
      });
    }
  }

  bool _hasPersistedScores(EvaluationScoreSheet? sheet) {
    if (sheet == null) {
      return false;
    }

    return sheet.students.any((student) => student.score != null);
  }

  String _resolveEvaluationDate(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now().toIso8601String().split('T').first;
    }

    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return value;
    }

    final parts = value.split('-');
    if (parts.length == 3 && parts[0].length == 2) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }

    return DateTime.now().toIso8601String().split('T').first;
  }

  String _semesterLabel(String? value) {
    switch (value) {
      case 'Semester 1':
      case 'ກາງພາກ':
        return 'ກາງພາກ';
      case 'Semester 2':
      case 'ທ້າຍພາກ':
        return 'ທ້າຍພາກ';
      default:
        return value ?? '-';
    }
  }

  String _currentRankingLabel(EvaluationScoreEntryStudent student) {
    if (student.ranking == null) {
      return '-';
    }
    return student.ranking.toString();
  }

  List<DataColumnDef<EvaluationScoreEntryStudent>> _buildColumns() {
    return [
      DataColumnDef<EvaluationScoreEntryStudent>(
        key: 'student',
        label: 'ນັກຮຽນ',
        flex: 4,
        render: (_, student) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              student.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '${student.registrationId} | ${student.studentId} | ${student.subjectName}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
      DataColumnDef<EvaluationScoreEntryStudent>(
        key: 'score',
        label: 'ຄະແນນ',
        flex: 2,
        render: (_, student) => AppTextField(
          controller: _scoreControllers[student.regisDetailId],
          hint: '0-10',
          digitOnly: DigitOnly.decimal,
          maxLength: 3,
          maxValue: 10,
          onChanged: (_) => _handleScoreChanged(),
        ),
      ),
      DataColumnDef<EvaluationScoreEntryStudent>(
        key: 'ranking',
        label: 'ຈັດອັນດັບ',
        flex: 2,
        render: (_, student) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _currentRankingLabel(student),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
      DataColumnDef<EvaluationScoreEntryStudent>(
        key: 'prize',
        label: 'ລາງວັນ',
        flex: 2,
        render: (_, student) => AppTextField(
          controller: _prizeControllers[student.regisDetailId],
          hint: '0',
          digitOnly: DigitOnly.integer,
          thousandsSeparator: true,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          suffixIcon: IconButton(
            onPressed: () {
              _prizeControllers[student.regisDetailId]?.clear();
            },
            icon:
                _prizeControllers[student.regisDetailId]?.text.isNotEmpty ==
                    true
                ? const Icon(Icons.close_rounded, size: 18)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ];
  }

  Future<void> _loadSubjects() async {
    await ref.read(evaluationProvider.notifier).loadScoreSubjects();
    final state = ref.read(evaluationProvider);
    if (!mounted) {
      return;
    }
    if (state.error != null) {
      ApiErrorHandler.handle(context, state.error!);
    }
  }

  Future<void> _loadLevelsForSubject() async {
    final subjectId = _selectedSubjectId;
    if (subjectId == null) {
      ref.read(evaluationProvider.notifier).clearSheet(clearSubjects: false);
      _syncControllers(null);
      return;
    }

    await ref
        .read(evaluationProvider.notifier)
        .loadScoreLevels(subjectId: subjectId);
    final state = ref.read(evaluationProvider);
    if (!mounted) {
      return;
    }
    if (state.error != null) {
      ApiErrorHandler.handle(context, state.error!);
    }
  }

  Future<void> _loadSheet() async {
    if (_selectedSemester == null ||
        _selectedLevelId == null ||
        _selectedSubjectDetailId == null) {
      ref.read(evaluationProvider.notifier).clearSheet(clearLevels: false);
      _syncControllers(null);
      return;
    }

    await ref
        .read(evaluationProvider.notifier)
        .loadScoreSheet(
          semester: _selectedSemester!,
          levelId: _selectedLevelId!,
          subjectDetailId: _selectedSubjectDetailId!,
        );

    final state = ref.read(evaluationProvider);
    if (!mounted) return;

    if (state.error != null) {
      ApiErrorHandler.handle(context, state.error!);
      return;
    }

    _syncControllers(state.sheet);
  }

  void _syncControllers(EvaluationScoreSheet? sheet) {
    _disposeControllers();

    if (sheet == null) {
      setState(() {
        _displayStudents = [];
        _hasScoreInput = false;
      });
      return;
    }

    for (final student in sheet.students) {
      _scoreControllers[student.regisDetailId] = TextEditingController(
        text: student.score == null ? '' : _formatAverage(student.score!),
      );
      _prizeControllers[student.regisDetailId] = TextEditingController(
        text: _formatMoneyInput(student.prize),
      );
    }

    setState(() {
      _displayStudents = [...sheet.students];
      _hasScoreInput = _hasAnyScore;
    });
  }

  Future<void> _arrangeAndPersistSheet() async {
    final sheet = ref.read(evaluationProvider).sheet;
    if (sheet == null) {
      ApiErrorHandler.handle(context, 'ກະລຸນາເລືອກຂໍ້ມູນໃຫ້ຄົບກ່ອນ');
      return;
    }

    if (!_hasAnyScore) {
      ApiErrorHandler.handle(context, 'ກະລຸນາປ້ອນຄະແນນຢ່າງນ້ອຍ 1 ຄົນກ່ອນ');
      return;
    }

    final request = EvaluationScoreSheetRequest(
      semester: _selectedSemester ?? _semesterLabel(sheet.semester),
      levelId: sheet.levelId,
      subjectDetailId: sheet.subjectDetailId,
      evaluationDate: _resolveEvaluationDate(sheet.evaluationDate),
      scores: _displayStudents.map((student) {
        return EvaluationScoreUpdateItem(
          regisDetailId: student.regisDetailId,
          score: _readScore(student.regisDetailId),
          prize: _readPrize(student.regisDetailId),
        );
      }).toList(),
    );

    final success = await ref
        .read(evaluationProvider.notifier)
        .saveScoreSheet(request);
    final state = ref.read(evaluationProvider);

    if (!mounted) return;

    if (!success) {
      ApiErrorHandler.handle(
        context,
        state.error ?? 'ບັນທຶກການຈັດອັນດັບບໍ່ສຳເລັດ',
      );
      return;
    }

    _syncControllers(state.sheet);
    await SuccessOverlay.show(
      context,
      message: _hasPersistedScores(sheet)
          ? 'ອັບເດດຂໍ້ມູນສຳເລັດ'
          : 'ບັນທຶກຂໍ້ມູນສຳເລັດ',
    );
    _resetForm();
  }

  void _resetForm() {
    ref.read(evaluationProvider.notifier).resetScoreEntryForm();
    _disposeControllers();
    setState(() {
      _selectedSemester = null;
      _selectedSubjectId = null;
      _selectedSubjectDetailId = null;
      _selectedLevelId = null;
      _displayStudents = [];
      _hasScoreInput = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final evaluationState = ref.watch(evaluationProvider);
    final sheet = evaluationState.sheet;
    final availableSubjects = evaluationState.availableSubjects;
    final availableLevels = evaluationState.availableLevels;
    final hasExistingScores = _hasPersistedScores(sheet);
    final canSave =
        sheet != null && !evaluationState.isSaving && _hasScoreInput;
    final primaryActionLabel = hasExistingScores ? 'ອັບເດດ' : 'ບັນທຶກ';
    final primaryActionIcon = hasExistingScores
        ? Icons.edit_note_rounded
        : Icons.save_rounded;
    final tableColumns = _buildColumns();
    final tableTitle = 'ຕາຕະລາງປະເມີນ';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ປະເມີນຜົນການຮຽນ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ເລືອກຮອບປະເມີນ,ວິຊາ  ແລະ ຊັ້ນຮຽນ/ລະດັບ ເພື່ອສະແດງນັກຮຽນ.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 180,
                      child: AppDropdown<String>(
                        label: 'ຮອບປະເມີນ',
                        value: _selectedSemester,
                        items: _semesters.map((item) {
                          return DropdownMenuItem(
                            value: item['value'],
                            child: Text(item['label'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          setState(() => _selectedSemester = value);
                          await _loadSheet();
                        },
                        hint: 'ເລືອກຮອບປະເມີນ',
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: AppDropdown<String>(
                        label: 'ວິຊາ',
                        value: _selectedSubjectId,
                        items: availableSubjects.map((item) {
                          return DropdownMenuItem(
                            value: item.subjectId,
                            child: Text(item.subjectName),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          setState(() {
                            _selectedSubjectId = value;
                            _selectedSubjectDetailId = null;
                            _selectedLevelId = null;
                          });
                          ref.read(evaluationProvider.notifier).clearSheet();
                          _syncControllers(null);
                          await _loadLevelsForSubject();
                        },
                        hint: evaluationState.isLoadingSubjects
                            ? 'ກຳລັງໂຫຼດວິຊາ...'
                            : 'ເລືອກວິຊາ',
                        enabled: !evaluationState.isLoadingSubjects,
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: AppDropdown<String>(
                        label: 'ຊັ້ນຮຽນ/ລະດັບ',
                        value: _selectedLevelId,
                        items: availableLevels.map((item) {
                          return DropdownMenuItem(
                            value: item.levelId,
                            child: Text(item.levelName),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          final selectedLevel = availableLevels
                              .where((item) => item.levelId == value)
                              .firstOrNull;
                          setState(() {
                            _selectedLevelId = value;
                            _selectedSubjectDetailId =
                                selectedLevel?.subjectDetailId;
                          });
                          await _loadSheet();
                        },
                        hint: evaluationState.isLoadingLevels
                            ? 'ກຳລັງໂຫຼດລະດັບ...'
                            : 'ເລືອກລະດັບ',
                        enabled:
                            _selectedSubjectId != null &&
                            !evaluationState.isLoadingLevels,
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: AppButton(
                          label: primaryActionLabel,
                          icon: primaryActionIcon,
                          onPressed: canSave ? _arrangeAndPersistSheet : null,
                          isLoading: evaluationState.isSaving,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: AppButton(
                          label: 'ເລີ່ມໃໝ່',
                          icon: Icons.restart_alt_rounded,
                          variant: AppButtonVariant.danger,
                          onPressed: evaluationState.isSaving
                              ? null
                              : _resetForm,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AppDataTable<EvaluationScoreEntryStudent>(
              columns: tableColumns,
              data: _displayStudents,
              isLoading: evaluationState.isLoading,
              rowHeight: 68,
              showActions: false,
              title: tableTitle,
            ),
          ),
        ],
      ),
    );
  }
}
