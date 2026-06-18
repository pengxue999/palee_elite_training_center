import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/report_export_action_helper.dart';
import 'package:palee_elite_training_center/models/report_models.dart';
import 'package:palee_elite_training_center/providers/level_provider.dart';
import 'package:palee_elite_training_center/providers/report_provider.dart';
import 'package:palee_elite_training_center/providers/subject_provider.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_card.dart';
import 'package:palee_elite_training_center/widgets/app_data_table.dart';
import 'package:palee_elite_training_center/widgets/app_dropdown.dart';
import 'package:palee_elite_training_center/widgets/loading_widget.dart';

class ReportScholarshipScreen extends ConsumerStatefulWidget {
  const ReportScholarshipScreen({super.key});

  @override
  ConsumerState<ReportScholarshipScreen> createState() =>
      _ReportScholarshipScreenState();
}

class _ReportScholarshipScreenState
    extends ConsumerState<ReportScholarshipScreen> {
  String _selectedScholarship = 'ໄດ້ຮັບທຶນ';
  String? _selectedSubjectId;
  String? _selectedLevelId;

  // (display label, api value, color)
  static const _scholarshipOptions = [
    ('ໄດ້ຮັບທຶນ', 'ໄດ້ຮັບທຶນ', Color(0xFF16A34A)),
    ('ບໍ່ໄດ້ຮັບທຶນ', 'ບໍ່ໄດ້ຮັບທຶນ', Color(0xFFDC2626)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      ref.read(subjectProvider.notifier).getSubjects(),
      ref.read(levelProvider.notifier).getLevels(),
    ]);
    _applyFilters();
  }

  void _applyFilters() {
    ref
        .read(reportProvider.notifier)
        .getScholarshipReport(
          scholarship: _selectedScholarship,
          subjectId: _selectedSubjectId,
          levelId: _selectedLevelId,
        );
  }

  void _clearFilters() {
    setState(() {
      _selectedScholarship = 'ໄດ້ຮັບທຶນ';
      _selectedSubjectId = null;
      _selectedLevelId = null;
    });
    _applyFilters();
  }

  Future<void> _handleExport() async {
    await ReportExportActionHelper.exportReport(
      context: context,
      reportTitle: 'ລາຍງານນັກຮຽນທຶນ',
      requestExport: (format) {
        return ref
            .read(reportProvider.notifier)
            .exportScholarshipReport(
              scholarship: _selectedScholarship,
              subjectId: _selectedSubjectId,
              levelId: _selectedLevelId,
              format: format,
            );
      },
      resolveErrorMessage: () =>
          ref.read(reportProvider).scholarshipReportError ??
          'ບໍ່ສາມາດ Export ໄດ້',
    );
  }

  Color _scholarshipColor(String? value) {
    for (final (label, apiValue, color) in _scholarshipOptions) {
      if (label == value || apiValue == value) return color;
    }
    return AppColors.mutedForeground;
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final subjectState = ref.watch(subjectProvider);
    final levelState = ref.watch(levelProvider);
    final data = reportState.scholarshipReportData;
    final hasData = (data?.students.isNotEmpty) ?? false;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.filter_alt_sharp,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ຕົວກອງ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    // Scholarship status filter
                    SizedBox(
                      width: 200,
                      child: AppDropdown<String>(
                        label: 'ສະຖານະທຶນ',
                        value: _selectedScholarship,
                        items: _scholarshipOptions.map((e) {
                          final (label, apiValue, color) = e;
                          return DropdownMenuItem<String>(
                            value: apiValue,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedScholarship = value);
                          _applyFilters();
                        },
                      ),
                    ),
                    // Subject filter
                    SizedBox(
                      width: 200,
                      child: AppDropdown<String>(
                        label: 'ວິຊາ',
                        value: _selectedSubjectId,
                        items: subjectState.subjects.map((s) {
                          return DropdownMenuItem(
                            value: s.subjectId,
                            child: Text(s.subjectName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedSubjectId = value);
                          _applyFilters();
                        },
                        hint: 'ທັງໝົດ',
                      ),
                    ),
                    // Level filter
                    SizedBox(
                      width: 180,
                      child: AppDropdown<String>(
                        label: 'ຊັ້ນຮຽນ',
                        value: _selectedLevelId,
                        items: levelState.levels.map((l) {
                          return DropdownMenuItem(
                            value: l.levelId,
                            child: Text(l.levelName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedLevelId = value);
                          _applyFilters();
                        },
                        hint: 'ທັງໝົດ',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action + summary bar
          if (data != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  if (hasData)
                    AppButton(
                      label: reportState.isScholarshipReportExporting
                          ? 'ກຳລັງບັນທຶກ...'
                          : 'ສົ່ງອອກເປັນ Excel/CSV',
                      icon: Icons.download_rounded,
                      variant: AppButtonVariant.success,
                      onPressed: reportState.isScholarshipReportExporting
                          ? null
                          : _handleExport,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'ບໍ່ມີຂໍ້ມູນ ຈຶ່ງບໍ່ສາມາດ Export ໄດ້',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  const Spacer(),
                  _buildCountBadge(
                    'ທັງໝົດ',
                    data.totalCount,
                    _scholarshipColor(_selectedScholarship),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          Expanded(child: _buildDataTable(reportState)),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $count',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDataTable(ReportState state) {
    if (state.isScholarshipReportLoading) {
      return const LoadingWidget(message: 'ກຳລັງໂຫຼດຂໍ້ມູນ...');
    }

    if (state.scholarshipReportError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
            const SizedBox(height: 16),
            Text(
              'ເກີດຂໍ້ຜິດພາດ: ${state.scholarshipReportError}',
              style: TextStyle(color: AppColors.destructive),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'ລອງໃໝ່',
              icon: Icons.refresh,
              onPressed: _applyFilters,
            ),
          ],
        ),
      );
    }

    final students = state.scholarshipReportData?.students ?? [];

    final columns = [
      DataColumnDef<ScholarshipReportItem>(
        key: 'fullName',
        label: 'ຊື່-ນາມສະກຸນ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      DataColumnDef<ScholarshipReportItem>(
        key: 'gender',
        label: 'ເພດ',
        flex: 1,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: TextStyle(
            fontSize: 14,
            color: v == 'ຊາຍ' ? Colors.blue : Colors.pink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      DataColumnDef<ScholarshipReportItem>(
        key: 'scholarshipSubject',
        label: 'ວິຊາທີ່ໄດ້ຮັບທຶນ',
        flex: 2,
        render: (v, row) {
          const color = Color(0xFF16A34A);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              v?.toString() ?? '-',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          );
        },
      ),
      DataColumnDef<ScholarshipReportItem>(
        key: 'studentContact',
        label: 'ເບີຕິດຕໍ່',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
      ),
      DataColumnDef<ScholarshipReportItem>(
        key: 'school',
        label: 'ໂຮງຮຽນ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DataColumnDef<ScholarshipReportItem>(
        key: 'districtName',
        label: 'ເມືອງ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
      ),
      DataColumnDef<ScholarshipReportItem>(
        key: 'provinceName',
        label: 'ແຂວງ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
      ),
    ];

    return AppDataTable<ScholarshipReportItem>(
      title: '',
      data: students,
      columns: columns,
      isLoading: state.isScholarshipReportLoading,
    );
  }
}
