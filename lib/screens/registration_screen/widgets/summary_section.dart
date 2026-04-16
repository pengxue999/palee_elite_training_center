import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/format_utils.dart';
import 'package:palee_elite_training_center/models/discount_model.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/custom_data_row.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/panel_card.dart';
import 'package:palee_elite_training_center/widgets/app_dropdown.dart';
import 'package:palee_elite_training_center/widgets/app_text_field.dart';

class SummarySection extends StatelessWidget {
  final int stepNum;
  final String academicYear;
  final String registrationDate;
  final String? studentName;
  final int tuitionFee;
  final int otherFee;
  final String otherFeeLabel;
  final int totalFee;
  final int discount;
  final int netFee;
  final List<DiscountModel> discounts;
  final String? selectedDiscountId;
  final ValueChanged<String?> onDiscountChanged;
  final bool discountEnabled;
  final TextEditingController otherFeeController;
  final ValueChanged<String> onOtherFeeChanged;
  final bool autoRenew;
  final ValueChanged<bool> onAutoRenewChanged;
  final bool canSave;

  const SummarySection({
    super.key,
    required this.stepNum,
    required this.academicYear,
    required this.registrationDate,
    required this.studentName,
    required this.tuitionFee,
    required this.otherFee,
    required this.otherFeeLabel,
    required this.totalFee,
    required this.discount,
    required this.netFee,
    required this.discounts,
    required this.selectedDiscountId,
    required this.onDiscountChanged,
    required this.discountEnabled,
    required this.otherFeeController,
    required this.onOtherFeeChanged,
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
      title: 'ກຳນົດສ່ວນຫຼຸດ ແລະ ຄ່າອື່ນໆ',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDropdown<String?>(
            label: 'ເລືອກສ່ວນຫຼຸດ',
            value: selectedDiscountId,
            hint: 'ເລືອກສ່ວນຫຼຸດ...',
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('ບໍ່ມີສ່ວນຫຼຸດ'),
              ),
              ...discounts.map(
                (discountItem) => DropdownMenuItem<String?>(
                  value: discountItem.discountId,
                  child: Text(
                    '${discountItem.discountDescription} (${discountItem.discountAmount.toInt()}%)',
                  ),
                ),
              ),
            ],
            onChanged: discountEnabled ? onDiscountChanged : null,
            enabled: discountEnabled,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: otherFeeLabel,
            hint: 'ປ້ອນຈຳນວນເງິນ...',
            controller: otherFeeController,
            enabled: discountEnabled,
            thousandsSeparator: true,
            digitOnly: DigitOnly.integer,
            onChanged: onOtherFeeChanged,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            suffixIcon: otherFeeController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      otherFeeController.clear();
                      onOtherFeeChanged('');
                    },
                    icon: const Icon(Icons.close_rounded, size: 20),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.info,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ຜູ້ໃຊ້ສາມາດແກ້ໄຂຄ່າອື່ນໆໄດ້ຕາມສະຖານະການຈິງ.',
                    style: TextStyle(fontSize: 13, color: AppColors.foreground),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          CustomDataRow(label: 'ສົກຮຽນ', value: academicYear),
          const SizedBox(height: 4),
          CustomDataRow(label: 'ວັນທີລົງທະບຽນ', value: registrationDate),
          const SizedBox(height: 4),
          CustomDataRow(label: 'ນັກຮຽນ', value: studentName ?? '—'),
          const Divider(height: 12),
          CustomDataRow(
            label: 'ລວມຄ່າຮຽນ',
            value: FormatUtils.formatKip(tuitionFee),
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
          if (otherFee > 0) ...[
            const SizedBox(height: 8),
            CustomDataRow(
              label: otherFeeLabel,
              value: FormatUtils.formatKip(otherFee),
            ),
          ],
        ],
      ),
    );
  }
}
