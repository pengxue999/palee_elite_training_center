import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/format_utils.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/custom_data_row.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/panel_card.dart';

class SummarySection extends StatelessWidget {
  final int stepNum;
  final String academicYear;
  final String registrationDate;
  final String? studentName;
  final int totalFee;
  final int discount;
  final int netFee;
  final bool autoRenew;
  final ValueChanged<bool> onAutoRenewChanged;
  final bool canSave;

  const SummarySection({
    super.key,
    required this.stepNum,
    required this.academicYear,
    required this.registrationDate,
    required this.studentName,
    required this.totalFee,
    required this.discount,
    required this.netFee,
    required this.autoRenew,
    required this.onAutoRenewChanged,
    required this.canSave,
  });

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      stepNum: stepNum,
      stepColor: AppColors.warning,
      icon: Icons.summarize_rounded,
      title: 'ສະຫຼຸບລາຍການລົງທະບຽນ',
      footer: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ຈຳນວນເງິນທີ່ຕ້ອງຈ່າຍ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              FormatUtils.formatKip(netFee),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          CustomDataRow(label: 'ສົກຮຽນ', value: academicYear),
          const SizedBox(height: 4),
          CustomDataRow(label: 'ວັນທີລົງທະບຽນ', value: registrationDate),
          const SizedBox(height: 4),
          CustomDataRow(label: 'ນັກຮຽນ', value: studentName ?? '—'),
          const Divider(height: 12),
          CustomDataRow(
            label: 'ລວມຄ່າຮຽນ',
            value: FormatUtils.formatKip(totalFee),
            bold: true,
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'ສ່ວນຫຼຸດ',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const Spacer(),
                Text(
                  '- ${FormatUtils.formatKip(discount)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.destructive,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
