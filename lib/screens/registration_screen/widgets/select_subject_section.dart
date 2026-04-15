import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/responsive_utils.dart';
import 'package:palee_elite_training_center/models/fee_model.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/fee_card.dart';
import 'package:palee_elite_training_center/widgets/section_card.dart';

class SelectSubjectSection extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final List<FeeModel> allFees;
  final List<FeeModel> filteredFees;
  final Set<String> selectedFeeIds;
  final bool isLoading;
  final bool enabled;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onToggleFee;

  const SelectSubjectSection({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.allFees,
    required this.filteredFees,
    required this.selectedFeeIds,
    required this.isLoading,
    required this.enabled,
    required this.onCategoryChanged,
    required this.onToggleFee,
  });

  @override
  State<SelectSubjectSection> createState() => SelectSubjectSectionState();
}

class SelectSubjectSectionState extends State<SelectSubjectSection> {
  String _selectedSubject = '';

  Map<String, List<FeeModel>> get _groupedBySubject {
    final map = <String, List<FeeModel>>{};
    for (final fee in widget.allFees) {
      map.putIfAbsent(fee.subjectName, () => []).add(fee);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.levelName.compareTo(b.levelName));
    }
    return map;
  }

  List<String> get _subjectNames => _groupedBySubject.keys.toList()..sort();

  void _selectFeeExclusive(String feeId, String subject) {
    final subjectFees = (_groupedBySubject[subject] ?? []);

    debugPrint('🔍 SELECT_FEE DEBUG:');
    debugPrint('   FeeId: $feeId');
    debugPrint('   Subject: $subject');
    debugPrint('   Currently selected FeeIds: ${widget.selectedFeeIds}');
    debugPrint(
      '   Is already selected: ${widget.selectedFeeIds.contains(feeId)}',
    );
    debugPrint('   Subject fees count: ${subjectFees.length}');

    if (widget.selectedFeeIds.contains(feeId)) {
      debugPrint('   ✓ DESELECTING (toggling off)');
      widget.onToggleFee(feeId);
      return;
    }

    debugPrint('   ✓ Fees to deselect in this subject:');
    for (final fee in subjectFees) {
      if (fee.feeId != feeId && widget.selectedFeeIds.contains(fee.feeId)) {
        debugPrint('     - Deselecting: ${fee.feeId} (${fee.levelName})');
        widget.onToggleFee(fee.feeId);
      }
    }

    debugPrint('   ✓ SELECTING new fee: $feeId');
    widget.onToggleFee(feeId);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_subjectNames.isNotEmpty && _selectedSubject.isEmpty) {
        setState(() => _selectedSubject = _subjectNames.first);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SelectSubjectSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_subjectNames.contains(_selectedSubject) && _subjectNames.isNotEmpty) {
      setState(() => _selectedSubject = _subjectNames.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSelected = widget.selectedFeeIds.length;
    final grouped = _groupedBySubject;
    final currentSubjectFees = grouped[_selectedSubject] ?? [];

    return SectionCard(
      stepNum: 2,
      stepColor: const Color(0xFF6366F1),
      icon: Icons.menu_book_rounded,
      title: 'ເລືອກວິຊາຮຽນ',
      badge: totalSelected > 0 ? '$totalSelected ວິຊາ' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_subjectNames.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _subjectNames.map((subject) {
                    final active = subject == _selectedSubject;
                    final selectedInSubject =
                        grouped[subject]
                            ?.where(
                              (f) => widget.selectedFeeIds.contains(f.feeId),
                            )
                            .length ??
                        0;

                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSubject = subject),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: active
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      Color(0xFF6366F1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                              if (selectedInSubject > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$selectedInSubject',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 14),

          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          if (grouped.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'ບໍ່ມີຂໍ້ມູນວິຊາ',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          else if (currentSubjectFees.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'ບໍ່ມີຂໍ້ມູນສຳລັບວິຊານີ້',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          else
            Stack(
              children: [
                LayoutBuilder(
                  builder: (ctx, box) {
                    int cols = 3;
                    if (box.maxWidth < Breakpoints.tablet) cols = 2;
                    if (box.maxWidth < 400) cols = 1;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 100,
                      ),
                      itemCount: currentSubjectFees.length,
                      itemBuilder: (_, i) {
                        final fee = currentSubjectFees[i];
                        final sel = widget.selectedFeeIds.contains(fee.feeId);
                        return FeeCard(
                          fee: fee,
                          isSelected: sel,
                          onTap: widget.enabled
                              ? () => _selectFeeExclusive(
                                  fee.feeId,
                                  _selectedSubject,
                                )
                              : () {},
                        );
                      },
                    );
                  },
                ),
                if (!widget.enabled)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 50,
                              color: AppColors.warning,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ກະລຸນາເລືອກນັກຮຽນກ່ອນ',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
