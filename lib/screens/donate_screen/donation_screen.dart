import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants/fixed_donation_categories.dart';
import '../../core/utils/format_utils.dart';
import '../../models/donation_model.dart';
import '../../models/donor_model.dart';
import '../../models/unit_model.dart';
import '../../providers/donation_provider.dart';
import '../../providers/donor_provider.dart';
import '../../providers/unit_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/success_overlay.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_date_field.dart';
import '../../widgets/app_button.dart';

class DonationScreen extends ConsumerStatefulWidget {
  const DonationScreen({super.key});

  @override
  ConsumerState<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends ConsumerState<DonationScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  DonationModel? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedDonorId;
  String? _selectedCategory;
  int? _selectedUnitId;
  bool _autoValidate = false;

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _amountController.text.trim().isNotEmpty &&
        _selectedDonorId != null &&
        _selectedCategory != null &&
        _selectedUnitId != null;
  }

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(donationProvider.notifier).getDonations();
      ref.read(donorProvider.notifier).getDonors();
      ref.read(unitProvider.notifier).getUnits();
      if (mounted) {
        final error = ref.read(donationProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  List<DonationModel> get _donations => ref.watch(donationProvider).donations;
  List<DonorModel> get _donors => ref.watch(donorProvider).donors;
  List<UnitModel> get _units => ref.watch(unitProvider).units;

  String _formatDateForApi(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return dateStr;
        }
        return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  void _resetForm() {
    _nameController.clear();
    _amountController.clear();
    _descriptionController.clear();
    final now = DateTime.now();
    _dateController.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _selectedDonorId = null;
    _selectedCategory = null;
    _selectedUnitId = null;
    selectedItem = null;
    isEditing = false;
    _autoValidate = false;
  }

  void _openAdd() async {
    _resetForm();
    if (_donors.isEmpty || _units.isEmpty) {
      await Future.wait([
        ref.read(donorProvider.notifier).getDonors(),
        ref.read(unitProvider.notifier).getUnits(),
      ]);
    }
    setState(() {
      showAddEditModal = true;
      isEditing = false;
    });
  }

  void _openEdit(DonationModel item) async {
    await Future.wait([
      ref.read(donorProvider.notifier).getDonors(),
      ref.read(unitProvider.notifier).getUnits(),
    ]);

    await Future.delayed(const Duration(milliseconds: 100));

    final donors = ref.read(donorProvider).donors;
    final units = ref.read(unitProvider).units;

    _nameController.text = item.donationName;
    _amountController.text = FormatUtils.formatNumber(item.amount.toInt());
    _descriptionController.text = item.description ?? '';
    _dateController.text = _formatDateForApi(item.donationDate);

    final matchingDonor = donors.firstWhere(
      (d) => d.fullName == item.donorFullName,
      orElse: () => donors.first,
    );
    _selectedDonorId = matchingDonor.donorId;

    _selectedCategory = fixedDonationCategories.contains(item.donationCategory)
        ? item.donationCategory
        : inKindDonationCategory;

    final matchingUnit = units.firstWhere(
      (u) => u.unitName == item.unitName,
      orElse: () => units.first,
    );
    _selectedUnitId = matchingUnit.unitId;

    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    setState(() {
      _autoValidate = true;
    });

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDonorId == null ||
        _selectedCategory == null ||
        _selectedUnitId == null) {
      return;
    }

    final amountStr = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountStr);

    if (amount == null || amount <= 0) {
      return;
    }

    bool success;
    if (isEditing && selectedItem != null) {
      final request = DonationUpdateRequest(
        donorId: _selectedDonorId!,
        donationCategory: _selectedCategory!,
        donationName: _nameController.text.trim(),
        amount: amount,
        unitId: _selectedUnitId,
        description: _descriptionController.text.trim(),
        donationDate: _formatDateForApi(_dateController.text),
      );
      success = await ref
          .read(donationProvider.notifier)
          .updateDonation(selectedItem!.donationId, request);
    } else {
      final request = DonationRequest(
        donorId: _selectedDonorId!,
        donationCategory: _selectedCategory!,
        donationName: _nameController.text.trim(),
        amount: amount,
        unitId: _selectedUnitId,
        description: _descriptionController.text.trim(),
        donationDate: _formatDateForApi(_dateController.text),
      );
      success = await ref
          .read(donationProvider.notifier)
          .createDonation(request);
    }

    if (!mounted) {
      return;
    }

    if (success) {
      SuccessOverlay.show(
        context,
        message: isEditing
            ? 'ອັບເດດການບໍລິຈາກສຳເລັດ'
            : 'ບັນທຶກການບໍລິຈາກສຳເລັດ',
      );
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else {
      final errorMessage = ref.read(donationProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(DonationModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem != null) {
      final success = await ref
          .read(donationProvider.notifier)
          .deleteDonation(selectedItem!.donationId);

      if (mounted) {
        setState(() {
          showDeleteDialog = false;
        });
      }

      if (success && mounted) {
        SuccessOverlay.show(context, message: 'ລຶບການບໍລິຈາກສຳເລັດ');
        setState(() {
          selectedItem = null;
        });
      } else if (mounted) {
        final errorMessage = ref.read(donationProvider).error;
        ApiErrorHandler.handle(
          context,
          errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = [
      DataColumnDef<DonationModel>(
        key: 'donorFullName',
        label: 'ຜູ້ບໍລິຈາກ',
        flex: 2,
        render: (context, item) => Text(item.donorFullName),
      ),
      DataColumnDef<DonationModel>(
        key: 'donationName',
        label: 'ລາຍການການບໍລິຈາກ',
        flex: 2,
        render: (context, item) => Text(item.donationName),
      ),
      DataColumnDef<DonationModel>(
        key: 'amount',
        label: 'ຈຳນວນ',
        flex: 2,
        render: (context, item) =>
            Text(FormatUtils.formatNumber(item.amount.toInt())),
      ),
      DataColumnDef<DonationModel>(
        key: 'unit',
        label: 'ຫົວໜ່ວຍ',
        flex: 2,
        render: (context, item) => Text(item.unitName ?? '-'),
      ),
      DataColumnDef<DonationModel>(
        key: 'donationCategory',
        label: 'ປະເພດ',
        flex: 2,
        render: (context, item) => Text(item.donationCategory),
      ),
      DataColumnDef<DonationModel>(
        key: 'description',
        label: 'ລາຍະລະອຽດ',
        flex: 2,
        render: (context, item) => Text(item.description ?? '-'),
      ),
      DataColumnDef<DonationModel>(
        key: 'donationDate',
        label: 'ວັນທີ',
        flex: 2,
        render: (context, item) => Text(item.donationDate),
      ),
    ];

    final donationState = ref.watch(donationProvider);
    final isLoading = donationState.isLoading && _donations.isEmpty;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Skeletonizer(
            enabled: isLoading,
            child: AppDataTable<DonationModel>(
              columns: columns,
              onAdd: _openAdd,
              onEdit: _openEdit,
              onDelete: _confirmDelete,
              searchKeys: const [
                'donationName',
                'donorFullName',
                'donationCategory',
                'description',
              ],
              addLabel: 'ເພີ່ມການບໍລິຈາກ',
              data: _donations,
            ),
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  Widget _buildFormModal() {
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂການບໍລິຈາກ' : 'ເພີ່ມການບໍລິຈາກໃໝ່',
          size: AppDialogSize.large,
          onClose: () => setState(() {
            showAddEditModal = false;
            _resetForm();
          }),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() {
                  showAddEditModal = false;
                  _resetForm();
                }),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: isEditing ? 'ຢືນຢັນ' : 'ບັນທຶກ',
                icon: Icons.save_rounded,
                onPressed: _isFormValid ? _save : null,
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'ຜູ້ບໍລິຈາກ',
                        hint: 'ເລືອກຜູ້ບໍລິຈາກ',
                        value: _selectedDonorId,
                        items: _donors
                            .map(
                              (d) => DropdownMenuItem(
                                value: d.donorId,
                                child: Text(d.fullName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedDonorId = v;
                        }),
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'ປະເພດການບໍລິຈາກ',
                        hint: 'ເລືອກປະເພດ',
                        value: _selectedCategory,
                        items: fixedDonationCategories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedCategory = v;
                        }),
                        required: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'ລາຍການການບໍລິຈາກ',
                        hint: 'ກະລຸນາປ້ອນລາຍການ',
                        controller: _nameController,
                        required: true,
                        validator: (v) => v?.isNotEmpty == true
                            ? null
                            : 'ກະລຸນາປ້ອນລາຍການການບໍລິຈາກ',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        label: 'ຈຳນວນ',
                        hint: '0',
                        controller: _amountController,
                        required: true,
                        keyboardType: TextInputType.number,
                        thousandsSeparator: true,
                        digitOnly: DigitOnly.integer,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: AppDropdown<int>(
                        label: 'ຫົວໜ່ວຍ',
                        hint: 'ເລືອກຫົວໜ່ວຍ',
                        value: _selectedUnitId,
                        items: _units
                            .map(
                              (u) => DropdownMenuItem(
                                value: u.unitId,
                                child: Text(u.unitName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedUnitId = v;
                        }),
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppDateField(
                        label: 'ວັນທີ່ບໍລິຈາກ',
                        controller: _dateController,
                        required: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'ລາຍະລະອຽດ',
                  hint: 'ລາຍລະອຽດເພີ່ມເຕີມ (ບໍ່ຈຳເປັນ)',
                  controller: _descriptionController,
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    return Material(
      color: Colors.black54,
      child: Center(
        child: ConfirmDialog(
          title: 'ຢືນຢັນການລຶບ',
          message:
              'ທ່ານຕ້ອງການລຶບການບໍລິຈາກ "${selectedItem?.donationName}" ຫຼືບໍ່?',
          onConfirm: _delete,
          onCancel: () => setState(() {
            showDeleteDialog = false;
          }),
          type: ConfirmDialogType.danger,
        ),
      ),
    );
  }
}
