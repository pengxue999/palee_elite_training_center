import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../models/report_models.dart';
import '../../models/academic_year_model.dart';
import '../../providers/report_provider.dart';
import '../../providers/academic_year_provider.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_widget.dart';

class ReportPopularSubjectScreen extends ConsumerStatefulWidget {
  const ReportPopularSubjectScreen({super.key});

  @override
  ConsumerState<ReportPopularSubjectScreen> createState() =>
      _ReportPopularSubjectScreenState();
}

class _ReportPopularSubjectScreenState
    extends ConsumerState<ReportPopularSubjectScreen> {
  String _activeTab = 'overview';
  String? _selectedAcademicYear;
  String? _selectedSubjectCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      ref.read(academicYearProvider.notifier).getAcademicYears(),
    ]);
    _setDefaultAcademicYear();
    setState(() => _isLoading = false);
  }

  void _setDefaultAcademicYear() {
    final academicYears = ref.read(academicYearProvider).academicYears;
    final activeYear = academicYears.firstWhere(
      (y) =>
          y.academicStatus == 'ກຳລັງດໍາເນີນ' ||
          y.academicStatus == 'ດໍາເນີນການ',
      orElse: () => academicYears.isNotEmpty
          ? academicYears.first
          : const AcademicYearModel(
              academicYear: '',
              startDate: '',
              endDate: '',
            ),
    );
    if (activeYear.academicYear.isNotEmpty) {
      setState(() => _selectedAcademicYear = activeYear.academicYear);
      _loadPopularSubjectsReport();
    }
  }

  Future<void> _loadPopularSubjectsReport() async {
    final academicYears = ref.read(academicYearProvider).academicYears;
    final selectedYear = academicYears.firstWhere(
      (y) => y.academicYear == _selectedAcademicYear,
      orElse: () => academicYears.isNotEmpty
          ? academicYears.first
          : const AcademicYearModel(
              academicYear: '',
              startDate: '',
              endDate: '',
            ),
    );

    await ref
        .read(reportProvider.notifier)
        .getPopularSubjectsReport(
          academicId: selectedYear.academicId!.isNotEmpty
              ? selectedYear.academicId
              : null,
        );
  }

  PopularSubjectsReportData? get _reportData {
    return ref.watch(reportProvider).popularSubjectsData;
  }

  List<PopularSubjectItem> get _filteredSubjects {
    final subjects = _reportData?.subjects ?? [];
    if (_selectedSubjectCategory == null) return subjects;
    return subjects
        .where((s) => s.subjectCategory == _selectedSubjectCategory)
        .toList();
  }

  List<LevelStatsItem> get _filteredLevels {
    final levels = _reportData?.levels ?? [];
    if (_selectedSubjectCategory == null) return levels;
    return levels
        .where((l) => l.subjectCategory == _selectedSubjectCategory)
        .toList();
  }

  List<String> get _subjectCategories {
    final categories = _reportData?.categories.keys.toList() ?? [];
    categories.sort();
    return categories;
  }

  int get _totalStudents {
    return _reportData?.summary.totalStudents ?? 0;
  }

  void _clearFilters() {
    setState(() {
      _selectedSubjectCategory = null;
      _setDefaultAcademicYear();
    });
  }

  String _formatAmount(double amount) {
    return FormatUtils.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    final academicYears = ref.watch(academicYearProvider).academicYears;
    final reportState = ref.watch(reportProvider);
    final filteredSubjects = _filteredSubjects;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadInitialData();
          await _loadPopularSubjectsReport();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(academicYears),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading || reportState.isPopularSubjectsLoading
                  ? const LoadingWidget(message: 'ກຳລັງໂຫຼດຂໍ້ມູນ...')
                  : reportState.popularSubjectsError != null
                  ? _buildErrorWidget(reportState.popularSubjectsError!)
                  : _reportData == null || filteredSubjects.isEmpty
                  ? EmptyWidget(
                      title: 'ບໍ່ມີຂໍ້ມູນ',
                      subtitle: 'ບໍ່ພົບຂໍ້ມູນວິຊາສຳລັບສົກຮຽນທີ່ເລືອກ',
                      icon: Icons.school_outlined,
                    )
                  : _buildContent(filteredSubjects),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.destructive, size: 48),
          const SizedBox(height: 16),
          Text(
            'ເກີດຂໍ້ຜິດພາດ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: AppColors.mutedForeground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            onPressed: () {
              ref.read(reportProvider.notifier).clearPopularSubjectsError();
              _loadPopularSubjectsReport();
            },
            label: 'ລອງໃໝ່',
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<AcademicYearModel> academicYears) {
    return Row(
      spacing: 16,
      children: [
        SizedBox(
          width: 180,
          child: AppDropdown<String>(
            value: _selectedAcademicYear,
            items: academicYears.map((year) {
              return DropdownMenuItem(
                value: year.academicYear,
                child: Text(year.academicYear, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedAcademicYear = value);
              _loadPopularSubjectsReport();
            },
            hint: 'ສົກຮຽນ',
          ),
        ),
        _buildTabs(),
      ],
    );
  }

  Widget _buildTabs() {
    final tabs = [
      ('overview', 'ພາບລວມ', Icons.dashboard_rounded),
      ('subjects', 'ວິຊານິຍົມ', Icons.trending_up_rounded),
      ('levels', 'ລະດັບ/ຊັ້ນ', Icons.format_list_numbered_rounded),
    ];

    return Row(
      children: tabs.map((tab) {
        final isActive = _activeTab == tab.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: isActive ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => setState(() => _activeTab = tab.$1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tab.$3,
                      size: 18,
                      color: isActive
                          ? Colors.white
                          : AppColors.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab.$2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : AppColors.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContent(List<PopularSubjectItem> subjects) {
    switch (_activeTab) {
      case 'overview':
        return _buildOverviewTab(subjects);
      case 'subjects':
        return _buildSubjectsTab(subjects);
      case 'levels':
        return _buildLevelsTab();
      default:
        return _buildOverviewTab(subjects);
    }
  }

  Widget _buildOverviewTab(List<PopularSubjectItem> subjects) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSubjectPieChart(subjects)),
              const SizedBox(width: 16),
              Expanded(child: _buildCategoryBarChart()),
            ],
          ),
          const SizedBox(height: 16),
          _buildTopSubjectsCard(subjects),
        ],
      ),
    );
  }

  Widget _buildSubjectPieChart(List<PopularSubjectItem> subjects) {
    if (subjects.isEmpty) {
      return AppCard(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                color: AppColors.mutedForeground,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'ບໍ່ມີຂໍ້ມູນ',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    final colors = [
      AppColors.primary,
      AppColors.success,
      const Color.fromARGB(255, 255, 140, 0),
      const Color.fromARGB(255, 255, 0, 0),
      const Color.fromARGB(255, 245, 1, 123),
    ];

    final totalStudents = _totalStudents;
    final sortedSubjects = List.from(subjects)
      ..sort((a, b) => b.studentCount.compareTo(a.studentCount));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ສັດສ່ວນນັກຮຽນຕາມວິຊາ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: sortedSubjects.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final percentage = totalStudents > 0
                      ? (item.studentCount / totalStudents) * 100
                      : 0;
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: item.studentCount.toDouble(),
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 160,
                    titleStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 1,
                centerSpaceRadius: 2,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: sortedSubjects.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.subjectName} (${item.studentCount} ຄົນ)',
                    style: TextStyle(fontSize: 14, color: AppColors.foreground),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBarChart() {
    final categoryStats = _reportData?.categories ?? {};

    if (categoryStats.isEmpty) {
      return AppCard(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                color: AppColors.mutedForeground,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'ບໍ່ມີຂໍ້ມູນ',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    final maxY = categoryStats.values.reduce((a, b) => a > b ? a : b);
    final interval = maxY > 0 ? maxY / 5 : 10;

    final sortedEntries = categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ສະຖິຕິຕາມໝວດວິຊາ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY > 0 ? maxY * 1.2 : 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = sortedEntries[groupIndex];
                      return BarTooltipItem(
                        '${item.key}\n',
                        const TextStyle(color: Colors.white, fontSize: 14),
                        children: [
                          TextSpan(
                            text: '${item.value} ຄົນ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()} ຄົນ',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.mutedForeground,
                          ),
                        );
                      },
                      interval: interval > 0 ? interval.toDouble() : 10.0,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedEntries.length) {
                          return const SizedBox.shrink();
                        }
                        return RotatedBox(
                          quarterTurns: 0,
                          child: Text(
                            sortedEntries[index].key.length > 10
                                ? '${sortedEntries[index].key.substring(0, 10)}...'
                                : sortedEntries[index].key,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.foreground,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: interval > 0 ? interval.toDouble() : 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppColors.border, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: sortedEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.value.toDouble(),
                        color: AppColors.primary,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTopSubjectsCard(List<PopularSubjectItem> subjects) {
    final sortedSubjects = List.from(subjects)
      ..sort((a, b) => b.studentCount.compareTo(a.studentCount));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ວິຊານິຍົມອັນດັບສູງສຸດ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedSubjects.take(5).toList().asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final subject = entry.value;
            final percentage = _totalStudents > 0
                ? (subject.studentCount / _totalStudents) * 100
                : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? AppColors.primary
                          : AppColors.infoLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: rank <= 3
                              ? Colors.white
                              : AppColors.foreground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              subject.subjectName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                subject.subjectCategory,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          backgroundColor: AppColors.muted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${subject.studentCount} ຄົນ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubjectsTab(List<PopularSubjectItem> subjects) {
    final sortedSubjects = List<PopularSubjectItem>.from(subjects)
      ..sort((a, b) => b.studentCount.compareTo(a.studentCount));

    final columns = [
      DataColumnDef<PopularSubjectItem>(
        key: 'subjectName',
        label: 'ວິຊາ',
        flex: 2,
        render: (v, row) => Text(
          row.subjectName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      DataColumnDef<PopularSubjectItem>(
        key: 'subjectCategory',
        label: 'ໝວດ',
        flex: 2,
        render: (v, row) => Text(
          row.subjectCategory,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary,
          ),
        ),
      ),
      DataColumnDef<PopularSubjectItem>(
        key: 'studentCount',
        label: 'ນັກຮຽນ',
        flex: 1,
        render: (v, row) => Text(
          '${row.studentCount} ຄົນ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ),
      DataColumnDef<PopularSubjectItem>(
        key: 'percentage',
        label: 'ສັດສ່ວນ',
        flex: 1,
        render: (v, row) {
          final percentage = _totalStudents > 0
              ? (row.studentCount / _totalStudents) * 100
              : 0;
          return Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 13),
          );
        },
      ),
    ];

    return AppDataTable<PopularSubjectItem>(
      title: 'ລາຍການວິຊານິຍົມ',
      subtitle: 'ທັງໝົດ ${sortedSubjects.length} ວິຊາ',
      data: sortedSubjects,
      columns: columns,
      showActions: false,
    );
  }

  Widget _buildLevelsTab() {
    final levelData = _filteredLevels;

    levelData.sort((a, b) => b.studentCount.compareTo(a.studentCount));

    final columns = [
      DataColumnDef<LevelStatsItem>(
        key: 'subjectName',
        label: 'ວິຊາ',
        flex: 2,
        render: (v, row) => Text(
          row.subjectName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      DataColumnDef<LevelStatsItem>(
        key: 'subjectCategory',
        label: 'ໝວດ',
        flex: 2,
        render: (v, row) => Text(
          row.subjectCategory,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary,
          ),
        ),
      ),
      DataColumnDef<LevelStatsItem>(
        key: 'levelName',
        label: 'ລະດັບ/ຊັ້ນ',
        flex: 2,
        render: (v, row) =>
            Text(row.levelName, style: const TextStyle(fontSize: 14)),
      ),
      DataColumnDef<LevelStatsItem>(
        key: 'studentCount',
        label: 'ນັກຮຽນ',
        flex: 1,
        render: (v, row) => Text(
          '${row.studentCount} ຄົນ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ),
    ];

    return AppDataTable<LevelStatsItem>(
      title: 'ລາຍລະອຽດຕາມລະດັບ/ຊັ້ນ',
      subtitle: 'ທັງໝົດ ${levelData.length} ລະດັບ',
      data: levelData,
      columns: columns,
      showActions: false,
    );
  }
}

class SubjectStats {
  final String subjectName;
  final String subjectCategory;
  final int levelCount;
  final int studentCount;
  final double totalFee;
  final double avgFee;
  final List<String> levels;

  SubjectStats({
    required this.subjectName,
    required this.subjectCategory,
    required this.levelCount,
    required this.studentCount,
    required this.totalFee,
    required this.avgFee,
    required this.levels,
  });
}

class LevelStats {
  final String levelName;
  final int studentCount;
  final double fee;

  LevelStats({
    required this.levelName,
    required this.studentCount,
    required this.fee,
  });
}
