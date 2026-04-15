import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../models/registration_model.dart';
import '../../providers/registration_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/success_overlay.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_button.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  bool showWizard = false;
  bool showViewModal = false;
  bool showPrintModal = false;
  bool showDeleteDialog = false;
  RegistrationModel? selectedReg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(registrationProvider.notifier).getRegistrations();
      if (mounted) {
        final error = ref.read(registrationProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  String _formatKip(double value) {
    return FormatUtils.formatKip(value.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationProvider);
    final registrations = state.registrations;
    final isLoading = state.isLoading && state.registrations.isEmpty;

    final columns = [
      DataColumnDef<RegistrationModel>(
        key: 'registrationId',
        label: 'ລະຫັດ',
        flex: 1,
      ),
      DataColumnDef<RegistrationModel>(
        key: 'studentName',
        label: 'ຊື່ນັກຮຽນ ແລະ ນາມສະກຸນ',
        flex: 3,
      ),
      DataColumnDef<RegistrationModel>(
        key: 'totalAmount',
        label: 'ລາຄາລວມ',
        flex: 2,
        render: (v, row) => Text(_formatKip(v as double)),
      ),
      DataColumnDef<RegistrationModel>(
        key: 'discountDescription',
        label: 'ສ່ວນຫຼຸດ',
        flex: 2,
        render: (v, row) => Text(
          v != null ? _formatKip(row.totalAmount - row.finalAmount) : '-',
        ),
      ),
      DataColumnDef<RegistrationModel>(
        key: 'finalAmount',
        label: 'ຈຳນວນທີ່ຕ້ອງຈ່າຍ',
        flex: 2,
        render: (v, row) => Text(
          _formatKip(v as double),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      DataColumnDef<RegistrationModel>(
        key: 'registrationDate',
        label: 'ວັນທີລົງທະບຽນ',
        flex: 2,
      ),
    ];

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.background,
                      AppColors.background.withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppDataTable<RegistrationModel>(
                    title: 'ລົງທະບຽນນັກຮຽນ',
                    subtitle: 'ທັງໝົດ ${registrations.length} ລາຍການ',
                    data: registrations,
                    columns: columns,
                    onAdd: () => context.push('/registration/new'),
                    onView: (r) => setState(() {
                      selectedReg = r;
                      showViewModal = true;
                    }),
                    onDelete: (r) => setState(() {
                      selectedReg = r;
                      showDeleteDialog = true;
                    }),
                    searchKeys: const ['studentName', 'registrationId'],
                    addLabel: 'ລົງທະບຽນໃໝ່',
                    isLoading: isLoading,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showWizard) _buildWizard(),
        if (showViewModal) _buildViewModal(),
        if (showPrintModal) _buildPrintModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  Widget _buildWizard() {
    return const SizedBox.shrink();
  }

  Widget _buildViewModal() {
    if (selectedReg == null) return const SizedBox.shrink();

    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, const Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ລາຍລະອຽດການລົງທະບຽນ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ລະຫັດ: ${selectedReg!.registrationId}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => showViewModal = false),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildModernInfoItem(
                          'ລະຫັດ',
                          selectedReg!.registrationId,
                          Icons.code_rounded,
                        ),
                        _buildModernInfoItem(
                          'ນັກຮຽນ ແລະ ນາມສະກຸນ',
                          selectedReg!.studentFullName,
                          Icons.person_rounded,
                        ),
                        _buildModernInfoItem(
                          'ສ່ວນຫຼຸດ',
                          selectedReg!.discountDescription != null
                              ? '${selectedReg!.discountDescription} (${_formatKip(selectedReg!.totalAmount - selectedReg!.finalAmount)})'
                              : '-',
                          Icons.discount_rounded,
                        ),
                        _buildModernInfoItem(
                          'ວັນທີລົງທະບຽນ',
                          selectedReg!.registrationDate,
                          Icons.event_rounded,
                        ),
                        _buildModernInfoItem(
                          'ສະຖານະ',
                          selectedReg!.status,
                          Icons.info_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.infoLight.withValues(alpha: 0.5),
                            AppColors.infoLight.withValues(alpha: 0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildModernPriceRow(
                            'ລາຄາລວມ',
                            _formatKip(selectedReg!.totalAmount),
                            false,
                            Icons.attach_money_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildModernPriceRow(
                            'ສ່ວນຫຼຸດ',
                            selectedReg!.discountDescription != null
                                ? '-${_formatKip(selectedReg!.totalAmount - selectedReg!.finalAmount)}'
                                : '-${_formatKip(0)}',
                            true,
                            Icons.discount_rounded,
                          ),
                          const Divider(height: 20),
                          _buildModernPriceRow(
                            'ຕ້ອງຈ່າຍ',
                            _formatKip(selectedReg!.finalAmount),
                            false,
                            Icons.payment_rounded,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => showViewModal = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ປິດ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrintModal() {
    if (selectedReg == null) return const SizedBox.shrink();

    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: 'ໃບບິນລົງທະບຽນ',
          size: AppDialogSize.medium,
          onClose: () => setState(() => showPrintModal = false),
          footer: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: 'ປິດ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() => showPrintModal = false),
              ),
              const SizedBox(width: 12),
              AppButton(label: 'ພິມ', icon: Icons.print, onPressed: () {}),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'ສູນຝຶກອົບຮົມ Palee Elite',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ໃບບິນລົງທະບຽນ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildBillRow('ລະຫັດ:', selectedReg!.registrationId),
                      _buildBillRow('ນັກຮຽນ:', selectedReg!.studentFullName),
                      _buildBillRow(
                        'ສ່ວນຫຼຸດ:',
                        selectedReg!.discountDescription ?? '-',
                      ),
                      _buildBillRow('ວັນທີ:', selectedReg!.registrationDate),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.06),
                        const Color(0xFF6366F1).withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildBillRow(
                        'ລາຄາລວມ:',
                        _formatKip(selectedReg!.totalAmount),
                      ),
                      _buildBillRow(
                        'ສ່ວນຫຼຸດ:',
                        selectedReg!.discountDescription != null
                            ? '-${_formatKip(selectedReg!.totalAmount - selectedReg!.finalAmount)}'
                            : '-${_formatKip(0)}',
                      ),
                      const Divider(height: 16),
                      _buildBillRow(
                        'ຍອດທີ່ຕ້ອງຈ່າຍ:',
                        _formatKip(selectedReg!.finalAmount),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoItem(String label, String value, IconData icon) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPriceRow(
    String label,
    String value,
    bool isNegative,
    IconData icon, {
    bool isBold = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isNegative
                ? AppColors.destructive.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isNegative ? AppColors.destructive : AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isNegative ? AppColors.destructive : AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.primary : AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedReg == null) return const SizedBox.shrink();
    final isLoading = ref.watch(registrationProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: 'ຢືນຢັນການລຶບ',
          size: AppDialogSize.small,
          onClose: () => setState(() {
            showDeleteDialog = false;
            selectedReg = null;
          }),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() {
                  showDeleteDialog = false;
                  selectedReg = null;
                }),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'ລຶບ',
                icon: Icons.delete,
                variant: AppButtonVariant.danger,
                onPressed: isLoading ? null : _delete,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.warning, size: 38, color: AppColors.warning),
              const SizedBox(height: 20),
              Text(
                'ທ່ານແນ່ໃຈບໍ່?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ຕ້ອງການລຶບການລົງທະບຽນຂອງ "${selectedReg!.studentFullName}" ແທ້ບໍ່?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    if (selectedReg == null) return;
    final success = await ref
        .read(registrationProvider.notifier)
        .deleteRegistration(selectedReg!.registrationId);

    if (mounted) {
      setState(() {
        showDeleteDialog = false;
      });
    }

    if (success && mounted) {
      SuccessOverlay.show(context, message: 'ລຶບການລົງທະບຽນສຳເລັດ');
      setState(() {
        selectedReg = null;
      });
    } else if (mounted) {
      final errorMessage = ref.read(registrationProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
      );
    }
  }
}
