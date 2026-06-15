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
import 'package:palee_elite_training_center/core/utils/registration_report_printer.dart';
import 'package:palee_elite_training_center/widgets/loading_widget.dart';
import 'package:palee_elite_training_center/widgets/print_preparation_overlay.dart';

class ReportRegistrationScreen extends ConsumerStatefulWidget {
  const ReportRegistrationScreen({super.key});

  @override
  ConsumerState<ReportRegistrationScreen> createState() =>
      _ReportRegistrationScreenState();
}

class _ReportRegistrationScreenState
    extends ConsumerState<ReportRegistrationScreen> {
  String? _selectedStatus = 'PAID_OR_PARTIAL';
  String? _selectedSubjectId;
  String? _selectedLevelId;
  bool _isPreparingPrint = false;

  // (display label, api value, color)
  static const _statusOptions = [
    ('ຈ່າຍແລ້ວ', 'ຈ່າຍແລ້ວ', Color(0xFF16A34A)),
    ('ຍັງບໍ່ທັນຈ່າຍ', 'ຍັງບໍ່ທັນຈ່າຍ', Color(0xFFDC2626)),
    ('ຈ່າຍບາງສ່ວນ', 'ຈ່າຍບາງສ່ວນ', Color(0xFFD97706)),
    ('ຈ່າຍແລ້ວ + ຈ່າຍບາງສ່ວນ', 'PAID_OR_PARTIAL', Color(0xFF2563EB)),
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
        .getRegistrationReport(
          status: _selectedStatus,
          subjectId: _selectedSubjectId,
          levelId: _selectedLevelId,
        );
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedSubjectId = null;
      _selectedLevelId = null;
    });
    _applyFilters();
  }

  Future<void> _handleExport() async {
    await ReportExportActionHelper.exportReport(
      context: context,
      reportTitle: 'ລາຍງານການລົງທະບຽນ',
      requestExport: (format) {
        return ref
            .read(reportProvider.notifier)
            .exportRegistrationReport(
              status: _selectedStatus,
              subjectId: _selectedSubjectId,
              levelId: _selectedLevelId,
            );
      },
      resolveErrorMessage: () =>
          ref.read(reportProvider).registrationReportError ??
          'ບໍ່ສາມາດ Export ໄດ້',
    );
  }

  Future<void> _handlePrint() async {
    if (_isPreparingPrint) return;
    setState(() => _isPreparingPrint = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      await showRegistrationReportPrintDialog(
        context: context,
        status: _selectedStatus,
        subjectId: _selectedSubjectId,
        levelId: _selectedLevelId,
        onPreviewReady: () {
          if (mounted && _isPreparingPrint) {
            setState(() => _isPreparingPrint = false);
          }
        },
      );
    } finally {
      if (mounted && _isPreparingPrint) {
        setState(() => _isPreparingPrint = false);
      }
    }
  }

  Color _statusColor(String? status) {
    for (final (label, apiValue, color) in _statusOptions) {
      if (label == status || apiValue == status) return color;
    }
    return AppColors.mutedForeground;
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final subjectState = ref.watch(subjectProvider);
    final levelState = ref.watch(levelProvider);
    final data = reportState.registrationReportData;
    final hasData = (data?.registrations.isNotEmpty) ?? false;

    return Stack(
      children: [
        Padding(
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
                        label: 'ລະດັບ/ຊັ້ນຮຽນ',
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
                    // Status filter
                    SizedBox(
                      width: 220,
                      child: AppDropdown<String>(
                        label: 'ສະຖານະການຊຳລະ',
                        value: _selectedStatus,
                        items: _statusOptions.map((e) {
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
                          setState(() => _selectedStatus = value);
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
                  if (hasData) ...[
                    AppButton(
                      label: reportState.isRegistrationReportExporting
                          ? 'ກຳລັງບັນທຶກ...'
                          : 'ສົ່ງອອກເປັນ Excel',
                      icon: Icons.download_rounded,
                      variant: AppButtonVariant.success,
                      onPressed: reportState.isRegistrationReportExporting || _isPreparingPrint
                          ? null
                          : _handleExport,
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: _isPreparingPrint ? 'ກຳລັງ ພິມ...' : 'ພິມ PDF',
                      icon: Icons.print_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: reportState.isRegistrationReportExporting || _isPreparingPrint
                          ? null
                          : _handlePrint,
                    ),
                  ] else
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
                    AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildCountBadge(
                    'ຈ່າຍແລ້ວ',
                    data.paidCount,
                    const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  _buildCountBadge(
                    'ຍັງບໍ່ຈ່າຍ',
                    data.unpaidCount,
                    const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 8),
                  _buildCountBadge(
                    'ຈ່າຍບາງສ່ວນ',
                    data.partialCount,
                    const Color(0xFFD97706),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          Expanded(child: _buildDataTable(reportState)),
        ],
      ),
        ),
        if (_isPreparingPrint)
          const PrintPreparationOverlay(
            icon: Icons.print_rounded,
            title: 'ກຳລັງໂຫຼດ...',
            message: 'ລະບົບກຳລັງສ້າງ PDF ລາຍງານການລົງທະບຽນ',
            hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
          ),
      ],
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
    if (state.isRegistrationReportLoading) {
      return const LoadingWidget(message: 'ກຳລັງໂຫຼດຂໍ້ມູນ...');
    }

    if (state.registrationReportError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
            const SizedBox(height: 16),
            Text(
              'ເກີດຂໍ້ຜິດພາດ: ${state.registrationReportError}',
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

    final registrations = state.registrationReportData?.registrations ?? [];

    final columns = [
      DataColumnDef<RegistrationReportItem>(
        key: 'studentId',
        label: 'ລະຫັດນັກຮຽນ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
      ),
      DataColumnDef<RegistrationReportItem>(
        key: 'fullName',
        label: 'ຊື່-ນາມສະກຸນ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      DataColumnDef<RegistrationReportItem>(
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
      DataColumnDef<RegistrationReportItem>(
        key: 'school',
        label: 'ໂຮງຮຽນ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DataColumnDef<RegistrationReportItem>(
        key: 'districtName',
        label: 'ເມືອງ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
      ),
      DataColumnDef<RegistrationReportItem>(
        key: 'provinceName',
        label: 'ແຂວງ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
      ),
      DataColumnDef<RegistrationReportItem>(
        key: 'status',
        label: 'ສະຖານະ',
        flex: 1,
        render: (v, row) {
          final color = _statusColor(v?.toString());
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              v?.toString() ?? '-',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          );
        },
      ),
    ];

    return AppDataTable<RegistrationReportItem>(
      title: '',
      data: registrations,
      columns: columns,
      isLoading: state.isRegistrationReportLoading,
    );
  }
}
