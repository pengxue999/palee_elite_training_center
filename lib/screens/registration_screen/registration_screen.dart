import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/registration_receipt_printer.dart';
import '../../models/fee_model.dart';
import '../../models/registration_model.dart';
import '../../providers/registration_provider.dart';
import '../../services/fee_service.dart';
import '../../services/registration_detail_service.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/success_overlay.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_button.dart';
import '../../widgets/print_preparation_overlay.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  bool showWizard = false;
  bool showDeleteDialog = false;
  bool _isPreparingPrint = false;
  RegistrationModel? selectedReg;
  final RegistrationDetailService _registrationDetailService =
      RegistrationDetailService();
  final FeeService _feeService = FeeService();

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

  Future<void> _printRegistration(RegistrationModel registration) async {
    if (_isPreparingPrint) {
      return;
    }

    setState(() => _isPreparingPrint = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      final detailsFuture = _registrationDetailService.getRegistrationDetails();
      final feesFuture = _feeService.getFees();

      final details = await detailsFuture;
      final fees = (await feesFuture).data;

      final selectedDetails = details
          .where(
            (detail) => detail.registrationId == registration.registrationId,
          )
          .toList(growable: false);
      final feeById = {for (final fee in fees) fee.feeId: fee};
      final selectedFees = selectedDetails
          .map((detail) => feeById[detail.feeId])
          .whereType<FeeModel>()
          .toList(growable: false);

      final tuitionFee = selectedFees.fold<int>(
        0,
        (sum, fee) => sum + fee.fee.toInt(),
      );
      final totalFee = registration.totalAmount.toInt();
      final discountAmount =
          (registration.totalAmount - registration.finalAmount).toInt();
      final otherFeeAmount = (totalFee - tuitionFee).clamp(0, totalFee);

      if (!mounted) {
        return;
      }

      await showRegistrationPrintDialog(
        context: context,
        registrationId: registration.registrationId,
        registrationDate: registration.registrationDate,
        studentName: registration.studentFullName,
        selectedFees: selectedFees,
        tuitionFee: tuitionFee,
        dormitoryLabel: otherFeeAmount > 0 ? 'ຄ່າອື່ນໆ' : null,
        dormitoryFee: otherFeeAmount,
        totalFee: totalFee,
        discountAmount: discountAmount,
        netFee: registration.finalAmount.toInt(),
        onPreviewReady: () {
          if (mounted && _isPreparingPrint) {
            setState(() => _isPreparingPrint = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ApiErrorHandler.handle(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isPreparingPrint = false);
      }
    }
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
                    data: registrations,
                    columns: columns,
                    onAdd: () => context.push('/registration/new'),
                    onPrint: (r) => _printRegistration(r),
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
        if (showDeleteDialog) _buildDeleteDialog(),
        if (_isPreparingPrint)
          const PrintPreparationOverlay(
            icon: Icons.print_rounded,
            title: 'ກຳລັງໂຫຼດ....',
            message:
                'ລະບົບກຳລັງດຶງຂໍ້ມູນການລົງທະບຽນ ແລະ ສ້າງ preview ໃຫ້ພ້ອມສຳລັບການພິມ',
            hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
          ),
      ],
    );
  }

  Widget _buildWizard() {
    return const SizedBox.shrink();
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
