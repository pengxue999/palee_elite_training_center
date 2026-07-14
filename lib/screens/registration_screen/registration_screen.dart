import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/registration_receipt_printer.dart';
import '../../models/discount_model.dart';
import '../../models/fee_model.dart';
import '../../models/registration_detail_model.dart';
import '../../models/registration_model.dart';
import '../../providers/discount_provider.dart';
import '../../providers/registration_provider.dart';
import '../../services/fee_service.dart';
import '../../services/registration_detail_service.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/success_overlay.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/print_preparation_overlay.dart';
import 'widgets/select_subject_section.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  static const String _mandatorySubjectName = 'ຄະນິດສາດຄິດໄວ';
  static const int _mandatoryFeeAmount = 300000;

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
      ref.read(discountProvider.notifier).getDiscounts();
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

  String _normalizeSubjectName(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').trim();
  }

  bool _isMandatorySubject(FeeModel fee) {
    final normalizedSubjectName = _normalizeSubjectName(fee.subjectName);
    final normalizedMandatoryName = _normalizeSubjectName(
      _mandatorySubjectName,
    );
    return normalizedSubjectName == normalizedMandatoryName ||
        normalizedSubjectName.contains(normalizedMandatoryName);
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
      final allMappedFees = selectedDetails
          .map((detail) => feeById[detail.feeId])
          .whereType<FeeModel>()
          .toList(growable: false);

      final containsMandatoryInDetails = allMappedFees.any(_isMandatorySubject);
      final selectedFees = allMappedFees
          .where((fee) => !_isMandatorySubject(fee))
          .toList(growable: false);

      final tuitionFee = selectedFees.fold<int>(
        0,
        (sum, fee) => sum + fee.fee.toInt(),
      );
      final totalFee = registration.totalAmount.toInt();
      final discountAmount =
          (registration.totalAmount - registration.finalAmount).toInt();
      final mandatoryFee =
          (containsMandatoryInDetails || selectedFees.isNotEmpty)
          ? _mandatoryFeeAmount
          : 0;
      final otherFeeAmount = (totalFee - tuitionFee - mandatoryFee).clamp(
        0,
        totalFee,
      );

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
        mandatoryLabel: 'ຄ່າວິຊາບັງຄັບ ($_mandatorySubjectName)',
        mandatoryFee: mandatoryFee,
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
                    onEdit: (r) => _openChangeSubjectsDialog(r),
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

  Future<void> _openChangeSubjectsDialog(RegistrationModel registration) async {
    if (ref.read(discountProvider).discounts.isEmpty) {
      await ref.read(discountProvider.notifier).getDiscounts();
    }

    if (!mounted) return;

    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ChangeSubjectsDialog(
        registration: registration,
        discounts: ref.read(discountProvider).discounts,
        feeService: _feeService,
        registrationDetailService: _registrationDetailService,
        onSave: (request, details) =>
            _updateSubjectsAndAmounts(registration, request, details),
      ),
    );

    if (updated == true && mounted) {
      SuccessOverlay.show(context, message: 'ປ່ຽນວິຊາລົງທະບຽນສຳເລັດ');
    } else if (updated == false && mounted) {
      final errorMessage = ref.read(registrationProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ບໍ່ສາມາດປ່ຽນວິຊາລົງທະບຽນໄດ້',
      );
    }
  }

  Future<bool> _updateSubjectsAndAmounts(
    RegistrationModel registration,
    RegistrationWithDetailsUpdateRequest request,
    List<Map<String, dynamic>> details,
  ) async {
    try {
      final currentDetails = await _registrationDetailService
          .getRegistrationDetails();
      final existingDetails =
          currentDetails
              .where(
                (detail) =>
                    detail.registrationId == registration.registrationId,
              )
              .toList()
            ..sort((a, b) => a.regisDetailId.compareTo(b.regisDetailId));
      final newDetails = details
          .map(
            (detail) => RegistrationDetailCreateRequest(
              registrationId: registration.registrationId,
              feeId: detail['fee_id'] as String,
              scholarship: detail['scholarship'] as String,
            ),
          )
          .toList();

      final existingByFeeId = {
        for (final detail in existingDetails) detail.feeId: detail,
      };
      final newByFeeId = {
        for (final detail in newDetails) detail.feeId: detail,
      };

      for (final detail in newDetails) {
        final existing = existingByFeeId[detail.feeId];
        if (existing == null) continue;
        await _registrationDetailService.updateRegistrationDetail(
          existing.regisDetailId,
          detail,
        );
      }

      final detailsToChange = existingDetails
          .where((detail) => !newByFeeId.containsKey(detail.feeId))
          .toList();
      final detailsToAdd = newDetails
          .where((detail) => !existingByFeeId.containsKey(detail.feeId))
          .toList();
      final updateCount = detailsToChange.length < detailsToAdd.length
          ? detailsToChange.length
          : detailsToAdd.length;

      for (var i = 0; i < updateCount; i++) {
        await _registrationDetailService.updateRegistrationDetail(
          detailsToChange[i].regisDetailId,
          detailsToAdd[i],
        );
      }

      for (var i = updateCount; i < detailsToAdd.length; i++) {
        await _registrationDetailService.createRegistrationDetail(
          detailsToAdd[i],
        );
      }

      for (var i = updateCount; i < detailsToChange.length; i++) {
        await _registrationDetailService.deleteRegistrationDetail(
          detailsToChange[i].regisDetailId,
        );
      }

      await ref
          .read(registrationServiceProvider)
          .updateRegistrationPartial(registration.registrationId, request);
      await ref.read(registrationProvider.notifier).getRegistrations();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ApiErrorHandler.handle(context, e.toString());
      return false;
    }
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

class _ChangeSubjectsDialog extends StatefulWidget {
  final RegistrationModel registration;
  final List<DiscountModel> discounts;
  final FeeService feeService;
  final RegistrationDetailService registrationDetailService;
  final Future<bool> Function(
    RegistrationWithDetailsUpdateRequest request,
    List<Map<String, dynamic>> details,
  )
  onSave;

  const _ChangeSubjectsDialog({
    required this.registration,
    required this.discounts,
    required this.feeService,
    required this.registrationDetailService,
    required this.onSave,
  });

  @override
  State<_ChangeSubjectsDialog> createState() => _ChangeSubjectsDialogState();
}

class _ChangeSubjectsDialogState extends State<_ChangeSubjectsDialog> {
  static const String _mandatorySubjectName = 'ຄະນິດສາດຄິດໄວ';
  static const int _mandatoryFeeAmount = 300000;

  final Set<String> _selectedFeeIds = {};
  Map<String, String> _scholarshipStatusByFee = {};
  List<FeeModel> _fees = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  int _otherFeeAmount = 0;
  String? _selectedDiscountId;

  int get _selectedSubjectFee => _selectedFeeIds.fold(0, (sum, feeId) {
    final fee = _fees.firstWhere(
      (f) => f.feeId == feeId,
      orElse: () => const FeeModel(
        feeId: '',
        subjectName: '',
        levelName: '',
        subjectCategory: '',
        academicYear: '',
        fee: 0,
      ),
    );
    return sum + fee.fee.toInt();
  });

  Set<String> get _scholarshipFeeIds => _selectedFeeIds
      .where((feeId) => _scholarshipStatusByFee[feeId] == 'ໄດ້ຮັບທຶນ')
      .toSet();

  List<FeeModel> get _scholarshipFees => _fees
      .where((fee) => _scholarshipFeeIds.contains(fee.feeId))
      .toList(growable: false);

  List<FeeModel> get _selectedFees => _fees
      .where((fee) => _selectedFeeIds.contains(fee.feeId))
      .toList(growable: false);

  int get _mandatoryFee => _selectedFeeIds.isEmpty ? 0 : _mandatoryFeeAmount;

  int get _totalFee => _selectedSubjectFee + _mandatoryFee + _otherFeeAmount;

  int get _selectedDiscountAmount {
    if (_selectedDiscountId == null) return 0;

    final discount = widget.discounts.firstWhere(
      (d) => d.discountId == _selectedDiscountId,
      orElse: () => const DiscountModel(
        discountId: '',
        discountAmount: 0,
        discountDescription: '',
        academicYear: '',
      ),
    );
    final discountPercentage = discount.discountAmount.toInt();

    if (discount.discountDescription.contains('ຮຽນ3ວິຊາຂື້ນໄປ')) {
      final calculationSubjectFee = _fees
          .where(
            (fee) =>
                _selectedFeeIds.contains(fee.feeId) &&
                fee.subjectCategory == 'ສາຍຄິດໄລ່',
          )
          .fold(0.0, (sum, fee) => sum + fee.fee)
          .toInt();
      return ((calculationSubjectFee * discountPercentage) / 100).round();
    }

    // ລົງທະບຽນຮຽນຊ້າ ແມ່ນຫຼຸດຈາກຄ່າຮຽນ ແລະ ຄ່າວິຊາບັງຄັບ
    if (discount.discountDescription.contains('ລົງທະບຽນຮຽນຊ້າ')) {
      return ((_selectedSubjectFee + _mandatoryFee) * discountPercentage / 100).round();
    }

    return ((_selectedSubjectFee * discountPercentage) / 100).round();
  }

  int get _netFee {
    final amount = _totalFee - _selectedDiscountAmount;
    return amount < 0 ? 0 : amount;
  }

  String get _mandatoryFeeLabel => 'ຄ່າວິຊາບັງຄັບ ($_mandatorySubjectName)';

  @override
  void initState() {
    super.initState();
    _selectedDiscountId = _initialDiscountId();
    _loadCurrentSubjects();
  }

  String? _initialDiscountId() {
    final discountId = widget.registration.discountId;
    if (discountId != null && discountId.isNotEmpty) {
      return discountId;
    }

    final description = widget.registration.discountDescription;
    if (description == null || description.isEmpty) {
      return null;
    }

    for (final discount in widget.discounts) {
      if (discount.discountDescription == description) {
        return discount.discountId;
      }
    }
    return null;
  }

  Future<void> _loadCurrentSubjects() async {
    try {
      final detailsFuture = widget.registrationDetailService
          .getRegistrationDetails();
      final feesFuture = widget.feeService.getFees();
      final details = await detailsFuture;
      final fees = (await feesFuture).data;
      final currentDetails = details
          .where(
            (detail) =>
                detail.registrationId == widget.registration.registrationId,
          )
          .toList(growable: false);
      final feeById = {for (final fee in fees) fee.feeId: fee};
      final currentSubjectFee = currentDetails.fold<int>(
        0,
        (sum, detail) => sum + (feeById[detail.feeId]?.fee.toInt() ?? 0),
      );
      final currentMandatoryFee = currentDetails.isEmpty
          ? 0
          : _mandatoryFeeAmount;
      final currentOtherFee =
          (widget.registration.totalAmount -
                  currentSubjectFee -
                  currentMandatoryFee)
              .round()
              .clamp(0, widget.registration.totalAmount.round());

      if (!mounted) return;
      setState(() {
        _fees = fees;
        _selectedFeeIds
          ..clear()
          ..addAll(currentDetails.map((detail) => detail.feeId));
        _scholarshipStatusByFee = {
          for (final detail in currentDetails) detail.feeId: detail.scholarship,
        };
        _otherFeeAmount = currentOtherFee;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ApiErrorHandler.handle(context, e.toString());
    }
  }

  void _toggleFee(String feeId) {
    setState(() {
      if (_selectedFeeIds.contains(feeId)) {
        _selectedFeeIds.remove(feeId);
        _scholarshipStatusByFee.remove(feeId);
      } else {
        _selectedFeeIds.add(feeId);
        _scholarshipStatusByFee[feeId] = 'ບໍ່ໄດ້ຮັບທຶນ';
      }
    });
  }

  void _toggleScholarship(String feeId) {
    setState(() {
      if (_scholarshipStatusByFee[feeId] == 'ໄດ້ຮັບທຶນ') {
        _scholarshipStatusByFee[feeId] = 'ບໍ່ໄດ້ຮັບທຶນ';
      } else {
        _scholarshipStatusByFee[feeId] = 'ໄດ້ຮັບທຶນ';
      }
    });
  }

  DateTime _parseRegistrationDate(String raw) {
    final parts = raw.trim().split(RegExp(r'[\s:-]+'));
    if (parts.length >= 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      final hour = parts.length > 3 ? int.tryParse(parts[3]) ?? 0 : 0;
      final minute = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;
      final second = parts.length > 5 ? int.tryParse(parts[5]) ?? 0 : 0;
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day, hour, minute, second);
      }
    }
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  Future<void> _save() async {
    if (_selectedFeeIds.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    final request = RegistrationWithDetailsUpdateRequest(
      studentId: widget.registration.studentId,
      discountId: _selectedDiscountId,
      totalAmount: _totalFee.toDouble(),
      finalAmount: _netFee.toDouble(),
      status: widget.registration.status,
      registrationDate: _parseRegistrationDate(
        widget.registration.registrationDate,
      ),
    );
    final details = _selectedFeeIds.map((feeId) {
      return {
        'fee_id': feeId,
        'scholarship': _scholarshipStatusByFee[feeId] ?? 'ບໍ່ໄດ້ຮັບທຶນ',
      };
    }).toList();

    final success = await widget.onSave(request, details);
    if (!mounted) return;

    setState(() => _isSaving = false);
    Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'ປ່ຽນວິຊາລົງທະບຽນ',
      size: AppDialogSize.large,
      onClose: _isSaving ? () {} : () => Navigator.of(context).pop(),
      footer: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: 'ຍົກເລີກ',
            variant: AppButtonVariant.ghost,
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: 'ບັນທຶກ',
            icon: Icons.save_rounded,
            isLoading: _isSaving,
            onPressed: _isSaving || _isLoading || _selectedFeeIds.isEmpty
                ? null
                : _save,
          ),
        ],
      ),
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: LoadingWidget(message: 'ກຳລັງໂຫຼດວິຊາ...'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.registration.registrationId} | ${widget.registration.studentFullName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 16),
                SelectSubjectSection(
                  allFees: _fees,
                  selectedFeeIds: _selectedFeeIds,
                  scholarshipFeeIds: _scholarshipFeeIds,
                  isLoading: false,
                  enabled: true,
                  onToggleFee: _toggleFee,
                ),
                const SizedBox(height: 16),
                AppDropdown<String?>(
                  label: 'ເລືອກສ່ວນຫຼຸດ',
                  value: _selectedDiscountId,
                  hint: 'ເລືອກສ່ວນຫຼຸດ...',
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('ບໍ່ມີສ່ວນຫຼຸດ'),
                    ),
                    ...widget.discounts.map(
                      (discount) => DropdownMenuItem<String?>(
                        value: discount.discountId,
                        child: Text(
                          '${discount.discountDescription} (${discount.discountAmount.toInt()}%)',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDiscountId = value);
                  },
                ),
                if (_selectedFees.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSubjectDetails(),
                ],
                const SizedBox(height: 16),
                _buildAmountSummary(),
              ],
            ),
    );
  }

  Widget _buildSubjectDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'ລາຍລະອຽດວິຊາທີ່ລົງທະບຽນ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              const Spacer(),
              Text(
                'ໄດ້ທຶນ ${_scholarshipFees.length}/${_selectedFees.length} ວິຊາ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ..._selectedFees.map((fee) {
            final isScholarship = _scholarshipFeeIds.contains(fee.feeId);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: fee.subjectName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                          TextSpan(
                            text: '  ${fee.levelName}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 140,
                    child: AppDropdown<String>(
                      value: _scholarshipStatusByFee[fee.feeId] ?? 'ບໍ່ໄດ້ຮັບທຶນ',
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
                        if (value != null) {
                          setState(() {
                            _scholarshipStatusByFee[fee.feeId] = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAmountSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _amountRow('ຄ່າຮຽນ', _selectedSubjectFee),
          _amountRow(_mandatoryFeeLabel, _mandatoryFee),
          if (_otherFeeAmount > 0)
            _amountRow('ຄ່າຫໍພັກໃນ(ຄ່ານ້ຳ,ຄ່າໄຟ)', _otherFeeAmount),
          const Divider(height: 20),
          _amountRow('ລວມທັງໝົດ', _totalFee, bold: true),
          if (_selectedDiscountAmount > 0)
            _amountRow('ສ່ວນຫຼຸດ', -_selectedDiscountAmount),
          _amountRow(
            'ຈຳນວນທີ່ຕ້ອງຈ່າຍ',
            _netFee,
            bold: true,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    String label,
    int amount, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color ?? AppColors.foreground,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            FormatUtils.formatKip(amount),
            style: TextStyle(
              color: color ?? AppColors.foreground,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
