import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/format_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/academic_year_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/academic_year_model.dart';
import '../widgets/custom_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    await ref.read(academicYearProvider.notifier).getAcademicYears();

    final academicYears = ref.read(academicYearProvider).academicYears;
    ref
        .read(dashboardProvider.notifier)
        .setAvailableAcademicYears(academicYears);

    await ref.read(dashboardProvider.notifier).loadDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    final padding = context.responsivePadding;
    final auth = ref.watch(authProvider);
    final dashboard = ref.watch(dashboardProvider);
    final academicYears = ref.watch(academicYearProvider).academicYears;
    final userName = auth.userName ?? 'ຜູ້ໃຊ້';

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dashboardProvider.notifier).refreshStats();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(context, userName, dashboard),
            const SizedBox(height: 28),
            _buildSectionHeaderWithFilter(
              'ສະຖິຕິພາບລວມ',
              academicYears,
              dashboard,
            ),
            const SizedBox(height: 16),
            if (dashboard.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (dashboard.error != null)
              _buildErrorWidget(dashboard.error!)
            else
              _buildStatsGrid(context, dashboard),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 48),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              ref.read(dashboardProvider.notifier).refreshStats();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('ລອງໃໝ່'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderWithFilter(
    String title,
    List<AcademicYearModel> academicYears,
    DashboardState dashboard,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF4338CA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (academicYears.isNotEmpty)
          _buildAcademicYearDropdown(academicYears, dashboard),
      ],
    );
  }

  Widget _buildAcademicYearDropdown(
    List<AcademicYearModel> academicYears,
    DashboardState dashboard,
  ) {
    final selectedYear = dashboard.selectedAcademicYear;
    final selectedFromList = selectedYear != null
        ? academicYears.firstWhere(
            (year) => year.academicId == selectedYear.academicId,
            orElse: () => academicYears.first,
          )
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AcademicYearModel>(
          value: selectedFromList,
          isDense: true,
          hint: const Text('ເລືອກສົກຮຽນ'),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: academicYears.map((year) {
            return DropdownMenuItem<AcademicYearModel>(
              value: year,
              child: Text(
                year.academicYear,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (AcademicYearModel? value) {
            if (value != null) {
              ref.read(dashboardProvider.notifier).selectAcademicYear(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(
    BuildContext context,
    String userName,
    DashboardState dashboard,
  ) {
    final academicYearText = dashboard.currentAcademicYear;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.35),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        'ສົກຮຽນ $academicYearText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ຍິນດີຕ້ອນຮັບ, $userName',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ລະບົບບໍລິຫານຈັດການສູນປາລີບຳລຸງນັກຮຽນເກັ່ງ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'ວັນທີ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      FormatUtils.getCurrentDateLao(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardState dashboard) {
    final cards = [
      CustomCard(
        icon: Icons.school_rounded,
        label: 'ນັກຮຽນທັງໝົດ',
        value: dashboard.totalStudents.toString(),
        subLabel: 'ກຳລັງຮຽນ: ${dashboard.activeStudents}',
        badge: 'ຄົນ',
        iconColor: const Color(0xFF2563EB),
        iconBackgroundColor: const Color(0xFFEFF6FF),
        accentColor: const Color(0xFF2563EB),
      ),
      CustomCard(
        icon: Icons.people_rounded,
        label: 'ອາຈານທັງໝົດ',
        value: dashboard.totalTeachers.toString(),
        subLabel: 'ເຮັດວຽກ: ${dashboard.activeTeachers}',
        badge: 'ຄົນ',
        iconColor: const Color(0xFF7C3AED),
        iconBackgroundColor: const Color(0xFFF5F3FF),
        accentColor: const Color(0xFF7C3AED),
      ),
      CustomCard(
        icon: Icons.trending_up_rounded,
        label: 'ລາຍຮັບທັງໝົດ',
        value: FormatUtils.formatKip(dashboard.totalIncome.toInt()),
        subLabel: dashboard.currentAcademicYear,
        badge: 'ກີບ',
        iconColor: const Color(0xFF059669),
        iconBackgroundColor: const Color(0xFFECFDF5),
        accentColor: const Color(0xFF059669),
      ),
      CustomCard(
        icon: Icons.trending_down_rounded,
        label: 'ລາຍຈ່າຍທັງໝົດ',
        value: FormatUtils.formatKip(dashboard.totalExpenses.toInt()),
        subLabel: dashboard.currentAcademicYear,
        badge: 'ກີບ',
        iconColor: const Color(0xFFDC2626),
        iconBackgroundColor: const Color(0xFFFEF2F2),
        accentColor: const Color(0xFFDC2626),
      ),
      CustomCard(
        icon: Icons.account_balance_wallet_rounded,
        label: 'ຍອດເຫຼືອ',
        value: FormatUtils.formatKip(dashboard.balance.toInt()),
        subLabel: dashboard.currentAcademicYear,
        badge: dashboard.balance >= 0 ? 'ກຳໄລ' : 'ຂາດດຸນ',
        iconColor: dashboard.balance >= 0
            ? const Color(0xFF059669)
            : const Color(0xFFDC2626),
        iconBackgroundColor: dashboard.balance >= 0
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFEF2F2),
        accentColor: dashboard.balance >= 0
            ? const Color(0xFF059669)
            : const Color(0xFFDC2626),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width < 600
            ? 1
            : width < 900
            ? 2
            : width < 1200
            ? 3
            : 4;

        const spacing = 16.0;
        final itemWidth =
            (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(width: itemWidth, child: card);
          }).toList(),
        );
      },
    );
  }
}
