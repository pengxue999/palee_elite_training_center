import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/models/academic_year_model.dart';
import 'package:palee_elite_training_center/models/district_model.dart';
import 'package:palee_elite_training_center/models/province_model.dart';
import 'package:palee_elite_training_center/models/report_models.dart';
import 'package:palee_elite_training_center/providers/academic_year_provider.dart';
import 'package:palee_elite_training_center/providers/district_provider.dart';
import 'package:palee_elite_training_center/providers/province_provider.dart';
import 'package:palee_elite_training_center/providers/report_provider.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_card.dart';
import 'package:palee_elite_training_center/widgets/app_data_table.dart';
import 'package:palee_elite_training_center/widgets/app_dropdown.dart';
import 'package:palee_elite_training_center/widgets/app_toast.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:typed_data';
import 'dart:convert';

class ReportStudentScreen extends ConsumerStatefulWidget {
  const ReportStudentScreen({super.key});

  @override
  ConsumerState<ReportStudentScreen> createState() =>
      _ReportStudentScreenState();
}

class _ReportStudentScreenState extends ConsumerState<ReportStudentScreen> {
  String? _selectedAcademicId;
  int? _selectedProvinceId;
  int? _selectedDistrictId;
  String? _selectedScholarship;
  String? _selectedDormitoryType;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      ref.read(academicYearProvider.notifier).getAcademicYears(),
      ref.read(provinceProvider.notifier).getProvinces(),
    ]);
    _applyFilters();
  }

  Future<void> _loadDistricts(int provinceId) async {
    await ref
        .read(districtProvider.notifier)
        .getDistrictsByProvince(provinceId);
  }

  void _applyFilters() {
    ref
        .read(reportProvider.notifier)
        .getStudentReport(
          academicId: _selectedAcademicId,
          provinceId: _selectedProvinceId,
          districtId: _selectedDistrictId,
          scholarship: _selectedScholarship,
          dormitoryType: _selectedDormitoryType,
          gender: _selectedGender,
        );
  }

  void _clearFilters() {
    setState(() {
      _selectedAcademicId = null;
      _selectedProvinceId = null;
      _selectedDistrictId = null;
      _selectedDormitoryType = null;
      _selectedScholarship = null;
      _selectedGender = null;
    });
    ref.read(districtProvider.notifier).clearDistricts();
    _applyFilters();
  }

  Future<void> _exportToCsv() async {
    final exportData = await ref
        .read(reportProvider.notifier)
        .exportStudentReport(
          academicId: _selectedAcademicId,
          provinceId: _selectedProvinceId,
          districtId: _selectedDistrictId,
          dormitoryType: _selectedDormitoryType,
          gender: _selectedGender,
        );

    if (exportData != null && mounted) {
      final csvData = utf8.encode(exportData.data);
      final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...csvData]);
      final FileSaveLocation? result = await getSaveLocation(
        suggestedName: exportData.filename,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'CSV Files', extensions: ['csv']),
        ],
      );

      if (result != null) {
        String path = result.path;
        if (!path.toLowerCase().endsWith('.csv')) {
          path += '.csv';
        }

        try {
          final xFile = XFile.fromData(
            bytes,
            name: exportData.filename,
            mimeType: 'text/csv',
          );
          await xFile.saveTo(path);

          if (mounted) {
            AppToast.success(context, 'ບັນທຶກສຳເລັດ ຢູ່ທີ: $path');
          }
        } catch (e) {
          if (mounted) {
            AppToast.error(context, 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກ: $e');
          }
        }
      }
    } else if (mounted) {
      final error = ref.read(reportProvider).error;
      AppToast.error(context, error ?? 'ບໍ່ສາມາດ Export ໄດ້');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final academicYearState = ref.watch(academicYearProvider);
    final provinceState = ref.watch(provinceProvider);
    final districtState = ref.watch(districtProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    SizedBox(
                      width: 200,
                      child: AppDropdown<String>(
                        label: 'ສົກຮຽນ',
                        value: _selectedAcademicId,
                        items: academicYearState.academicYears.map((ay) {
                          return DropdownMenuItem(
                            value: ay.academicId,
                            child: Text(ay.academicYear),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedAcademicId = value);
                          _applyFilters();
                        },
                        hint: 'ທັງໝົດ',
                      ),
                    ),

                    SizedBox(
                      width: 180,
                      child: AppDropdown<int>(
                        label: 'ແຂວງ',
                        value: _selectedProvinceId,
                        items: provinceState.provinces.map((p) {
                          return DropdownMenuItem(
                            value: p.provinceId,
                            child: Text(p.provinceName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProvinceId = value;
                            _selectedDistrictId = null;
                          });
                          if (value != null) {
                            _loadDistricts(value);
                          }
                          _applyFilters();
                        },
                        hint: 'ທັງໝົດ',
                      ),
                    ),

                    SizedBox(
                      width: 180,
                      child: AppDropdown<int>(
                        label: 'ເມືອງ',
                        value: _selectedDistrictId,
                        items: districtState.filteredDistricts.map((d) {
                          return DropdownMenuItem(
                            value: d.districtId,
                            child: Text(d.districtName),
                          );
                        }).toList(),
                        onChanged:
                            _selectedProvinceId == null ||
                                districtState.filteredDistricts.isEmpty
                            ? null
                            : (value) {
                                setState(() => _selectedDistrictId = value);
                                _applyFilters();
                              },
                        hint: _selectedProvinceId == null
                            ? 'ເລືອກແຂວງກ່ອນ'
                            : 'ທັງໝົດ',
                      ),
                    ),

                    SizedBox(
                      width: 180,
                      child: AppDropdown<String>(
                        label: 'ສະຖານະທຶນ',
                        value: _selectedScholarship,
                        items: const [
                          DropdownMenuItem(
                            value: 'ໄດ້ຮັບທຶນ',
                            child: Text('ໄດ້ຮັບທຶນ'),
                          ),
                          DropdownMenuItem(
                            value: 'ບໍ່ໄດ້ຮັບທຶນ',
                            child: Text('ບໍ່ໄດ້ຮັບທຶນ'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedScholarship = value);
                          _applyFilters();
                        },
                        hint: 'ທັງໝົດ',
                      ),
                    ),

                    SizedBox(
                      width: 160,
                      child: AppDropdown<String>(
                        label: 'ປະເພດຫໍພັກ',
                        value: _selectedDormitoryType,
                        items: const [
                          DropdownMenuItem(
                            value: 'ຫໍພັກໃນ',
                            child: Text('ຫໍພັກໃນ'),
                          ),
                          DropdownMenuItem(
                            value: 'ຫໍພັກນອກ',
                            child: Text('ຫໍພັກນອກ'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedDormitoryType = value);
                          _applyFilters();
                        },
                        hint: 'ທັງໝົດ',
                      ),
                    ),

                    SizedBox(
                      width: 140,
                      child: AppDropdown<String>(
                        label: 'ເພດ',
                        value: _selectedGender,
                        items: const [
                          DropdownMenuItem(value: 'ຊາຍ', child: Text('ຊາຍ')),
                          DropdownMenuItem(value: 'ຍິງ', child: Text('ຍິງ')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedGender = value);
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

          if (reportState.filters != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  AppButton(
                    label: reportState.isExporting
                        ? 'ກຳລັງ Export...'
                        : 'Export CSV',
                    icon: Icons.download_rounded,
                    variant: AppButtonVariant.primary,
                    onPressed:
                        reportState.students.isEmpty || reportState.isExporting
                        ? null
                        : _exportToCsv,
                  ),
                  Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${reportState.totalCount} ຄົນ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(child: _buildDataTable(reportState)),
        ],
      ),
    );
  }

  Widget _buildDataTable(ReportState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
            const SizedBox(height: 16),
            Text(
              'ເກີດຂໍ້ຜິດພາດ: ${state.error}',
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

    final columns = [
      DataColumnDef<StudentReportItem>(
        key: 'studentId',
        label: 'ລະຫັດ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'fullName',
        label: 'ຊື່-ນາມສະກຸນ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      DataColumnDef<StudentReportItem>(
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
      DataColumnDef<StudentReportItem>(
        key: 'school',
        label: 'ໂຮງຮຽນ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'provinceName',
        label: 'ແຂວງ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 14)),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'districtName',
        label: 'ເມືອງ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 14)),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'dormitoryType',
        label: 'ຫໍພັກ',
        flex: 1,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: TextStyle(
            fontSize: 14,
            color: v == 'ຫໍພັກໃນ' ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'studentContact',
        label: 'ເບີຕິດຕໍ່',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 14)),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'parentsContact',
        label: 'ເບີຕິດຕໍ່ຜູ້ປົກຄອງ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 14)),
      ),
    ];

    return AppDataTable<StudentReportItem>(
      title: '',
      subtitle: state.students.isEmpty
          ? 'ບໍ່ມີຂໍ້ມູນ'
          : 'ທັງໝົດ ${state.totalCount} ຄົນ',
      data: state.students,
      columns: columns,
      isLoading: state.isLoading,
    );
  }
}
