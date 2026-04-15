import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/csv_export_helper.dart';
import '../../models/donation_model.dart';
import '../../models/donor_model.dart';
import '../../models/donation_category_model.dart';
import '../../providers/donation_provider.dart';
import '../../providers/donor_provider.dart';
import '../../providers/donation_category_provider.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_widget.dart';

class ReportDonationScreen extends ConsumerStatefulWidget {
  const ReportDonationScreen({super.key});

  @override
  ConsumerState<ReportDonationScreen> createState() =>
      _ReportDonationScreenState();
}

class _ReportDonationScreenState extends ConsumerState<ReportDonationScreen> {
  String _activeTab = 'overview';
  String? _selectedDonorId;
  int? _selectedCategoryId;
  String? _selectedYear;
  final List<String> _availableYears = [];
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      ref.read(donationProvider.notifier).getDonations(),
      ref.read(donorProvider.notifier).getDonors(),
      ref.read(donationCategoryProvider.notifier).getDonationCategories(),
    ]);
    _generateAvailableYears();
  }

  void _generateAvailableYears() {
    final donations = ref.read(donationProvider).donations;
    final years = donations
        .map((d) {
          try {
            final parts = d.donationDate.split('-');
            if (parts.length == 3) {
              return parts[2].length == 4 ? parts[2] : parts[0];
            }
            return DateTime.now().year.toString();
          } catch (_) {
            return null;
          }
        })
        .whereType<String>()
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));

    setState(() {
      _availableYears.clear();
      _availableYears.addAll(years);
      if (_availableYears.isNotEmpty && _selectedYear == null) {
        _selectedYear = _availableYears.first;
      }
    });
  }

  List<DonationModel> _getFilteredDonations() {
    final donations = ref.watch(donationProvider).donations;
    return donations.where((d) {
      if (_selectedDonorId != null && d.donorId != _selectedDonorId) {
        return false;
      }
      if (_selectedCategoryId != null &&
          d.donationCategoryId != _selectedCategoryId) {
        return false;
      }
      if (_selectedYear != null) {
        try {
          final parts = d.donationDate.split('-');
          if (parts.length == 3) {
            final year = parts[2].length == 4 ? parts[2] : parts[0];
            if (year != _selectedYear) return false;
          }
        } catch (_) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _handleExport() async {
    final filteredDonations = _getFilteredDonations();
    if (filteredDonations.isEmpty) {
      AppToast.error(context, 'ບໍ່ມີຂໍ້ມູນສຳລັບ Export');
      return;
    }

    setState(() => _isExporting = true);

    try {
      final data = filteredDonations
          .map(
            (d) => {
              'donationId': d.donationId.toString(),
              'donorName': d.donorFullName,
              'category': d.donationCategory,
              'donationName': d.donationName,
              'amount': d.amount.toString(),
              'unit': d.unitName ?? '-',
              'date': d.donationDate,
              'description': d.description ?? '-',
            },
          )
          .toList();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'donation_report_$timestamp.csv';

      await CsvExportHelper.exportToCsv(
        headers: [
          'ລະຫັດ',
          'ຜູ້ບໍລິຈາກ',
          'ປະເພດ',
          'ຊື່ການບໍລິຈາກ',
          'ຈຳນວນເງິນ',
          'ຫົວໜ່ວຍ',
          'ວັນທີ',
          'ລາຍລະອຽດ',
        ],
        data: data,
        filename: filename,
        columnMapping: {
          'ລະຫັດ': 'donationId',
          'ຜູ້ບໍລິຈາກ': 'donorName',
          'ປະເພດ': 'category',
          'ຊື່ການບໍລິຈາກ': 'donationName',
          'ຈຳນວນເງິນ': 'amount',
          'ຫົວໜ່ວຍ': 'unit',
          'ວັນທີ': 'date',
          'ລາຍລະອຽດ': 'description',
        },
      );

      AppToast.success(context, 'Export CSV ສຳເລັດ');
    } catch (e) {
      AppToast.error(context, 'Export ບໍ່ສຳເລັດ: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDonorId = null;
      _selectedCategoryId = null;
      _selectedYear = _availableYears.isNotEmpty ? _availableYears.first : null;
    });
  }

  String _formatAmount(double amount) {
    return FormatUtils.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    final donationState = ref.watch(donationProvider);
    final donors = ref.watch(donorProvider).donors;
    final categories = ref.watch(donationCategoryProvider).donationCategories;
    final filteredDonations = _getFilteredDonations();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(donors, categories),
            Expanded(
              child: donationState.isLoading
                  ? const LoadingWidget(message: 'ກຳລັງໂຫຼດຂໍ້ມູນ...')
                  : filteredDonations.isEmpty
                  ? EmptyWidget(
                      title: 'ບໍ່ມີຂໍ້ມູນ',
                      subtitle: 'ບໍ່ພົບຂໍ້ມູນການບໍລິຈາກຕາມທີ່ກຳນົດ',
                      icon: Icons.volunteer_activism_outlined,
                      onAction: _clearFilters,
                    )
                  : _buildListTab(filteredDonations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(
    List<DonorModel> donors,
    List<DonationCategoryModel> categories,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'ກອງຂໍ້ມູນ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
                label: Text(
                  'Refresh',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 140,
                child: AppDropdown<String>(
                  value: _selectedYear,
                  items: _availableYears.map((year) {
                    return DropdownMenuItem(value: year, child: Text(year));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedYear = value);
                  },
                  hint: 'ສົກຮຽນ',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 200,
                child: AppDropdown<String>(
                  value: _selectedDonorId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('ທັງໝົດຜູ້ບໍລິຈາກ'),
                    ),
                    ...donors.map((donor) {
                      return DropdownMenuItem(
                        value: donor.donorId,
                        child: Text(
                          donor.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDonorId = value);
                  },
                  hint: 'ຜູ້ບໍລິຈາກ',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: AppDropdown<int>(
                  value: _selectedCategoryId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('ທັງໝົດປະເພດ'),
                    ),
                    ...categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.donationCategoryId,
                        child: Text(
                          cat.donationCategory,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                  hint: 'ປະເພດການບໍລິຈາກ',
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Export CSV',
                icon: Icons.download_rounded,
                variant: AppButtonVariant.primary,
                isLoading: _isExporting,
                onPressed: _handleExport,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListTab(List<DonationModel> donations) {
    final columns = [
      DataColumnDef<DonationModel>(
        key: 'donorFullName',
        label: 'ຜູ້ບໍລິຈາກ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      DataColumnDef<DonationModel>(
        key: 'donationCategory',
        label: 'ປະເພດ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ),
      DataColumnDef<DonationModel>(
        key: 'donationName',
        label: 'ລາຍການການບໍລິຈາກ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DataColumnDef<DonationModel>(
        key: 'amount',
        label: 'ຈຳນວນ',
        flex: 2,
        render: (v, row) {
          final amount = (v as num).toDouble();
          final isCashDonation = row.donationCategory == 'ເງິນສົດ';
          final displayText = isCashDonation
              ? _formatAmount(amount)
              : amount.toString();

          return Text(
            displayText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          );
        },
      ),
      DataColumnDef<DonationModel>(
        key: 'unitName',
        label: 'ຫົວໜ່ວຍ',
        flex: 1,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      DataColumnDef<DonationModel>(
        key: 'donationDate',
        label: 'ວັນທີ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    ];

    return AppDataTable<DonationModel>(
      title: 'ລາຍການບໍລິຈາກ',
      subtitle: 'ທັງໝົດ ${donations.length} ລາຍການ',
      data: donations,
      columns: columns,
      showActions: false,
    );
  }
}
