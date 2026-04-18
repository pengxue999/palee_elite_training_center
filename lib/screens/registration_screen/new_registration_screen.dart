import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palee_elite_training_center/core/utils/receipt_printer.dart';
import 'package:palee_elite_training_center/models/discount_model.dart';
import 'package:palee_elite_training_center/models/province_model.dart';
import 'package:palee_elite_training_center/models/district_model.dart';
import 'package:palee_elite_training_center/providers/discount_provider.dart';
import 'package:palee_elite_training_center/providers/province_provider.dart';
import 'package:palee_elite_training_center/providers/district_provider.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/new_student_form.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/select_student_banner.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/select_subject_section.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/right_panel.dart';
import 'package:palee_elite_training_center/screens/registration_screen/widgets/student_selection_list.dart';
import 'package:palee_elite_training_center/widgets/app_toast.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_dialog.dart';
import 'package:palee_elite_training_center/widgets/section_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/fee_model.dart';
import '../../models/student_model.dart';
import '../../models/registration_model.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/registration_provider.dart';
import '../../widgets/print_preparation_overlay.dart';
import '../../widgets/success_overlay.dart';

class Student {
  final String id;
  final String name;
  final String lastname;
  final String gender;
  final String phone;
  final String parentsContact;
  final String school;
  final String districtId;
  final String? districtName;
  final String? provinceName;
  final String? dormitoryId;
  final String? dormitoryName;
  final String academicYear;

  Student({
    required this.id,
    required this.name,
    required this.lastname,
    required this.gender,
    required this.phone,
    required this.parentsContact,
    required this.school,
    required this.districtId,
    this.districtName,
    this.provinceName,
    this.dormitoryId,
    this.dormitoryName,
    required this.academicYear,
  });

  String get fullName => '$name $lastname';
}

class NewRegistrationScreen extends ConsumerStatefulWidget {
  const NewRegistrationScreen({super.key});

  @override
  ConsumerState<NewRegistrationScreen> createState() =>
      _NewRegistrationScreenState();
}

class _NewRegistrationScreenState extends ConsumerState<NewRegistrationScreen> {
  int _currentStep = 1;
  bool _isPreparingPrint = false;
  final _steps = const [
    'ກວດສອບນັກຮຽນ',
    'ເລືອກວິຊາ',
    'ເລືອກສ່ວນຫຼຸດ',
    'ກຳນົດສ່ວນຫຼຸດ ແລະ ຄ່າອື່ນໆ',
    'ພິມໃບລົງທະບຽນ',
  ];

  final _searchCtrl = TextEditingController();
  final _otherFeeCtrl = TextEditingController();
  String _searchQuery = '';
  Student? _selectedStudent;

  final Set<String> _selectedFeeIds = {};

  String? _selectedDiscountId;
  Map<String, String> _scholarshipStatusByFee = {};
  int _otherFeeAmount = 0;
  bool _autoRenew = false;

  static const Map<String, int> _dormitoryFees = <String, int>{
    'ຫໍພັກໃນ': 200000,
    'ຫໍພັກນອກ': 100000,
  };

  List<FeeModel> get _fees => ref.watch(feeProvider).fees;
  bool get _isLoadingFees => ref.watch(feeProvider).isLoading;
  List<DiscountModel> get _discounts => ref.watch(discountProvider).discounts;

  List<StudentModel> get _apiStudents => ref.watch(studentProvider).students;
  List<Student> get _studentsFromApi {
    return _apiStudents
        .map(
          (s) => Student(
            id: s.studentId ?? '',
            name: s.studentName,
            lastname: s.studentLastname,
            gender: s.gender,
            phone: s.studentContact,
            parentsContact: s.parentsContact,
            school: s.school,
            districtId: s.districtName,
            districtName: s.districtName,
            provinceName: s.provinceName,
            dormitoryId: s.dormitoryName,
            dormitoryName: s.dormitoryName,
            academicYear: _currentAcademicYear,
          ),
        )
        .toList();
  }

  List<Student> get _unregisteredStudents {
    final regIds = ref
        .read(registrationProvider)
        .registrations
        .map((r) => r.studentId)
        .toSet();
    return _studentsFromApi
        .where((s) => !regIds.contains(s.id) && s.id.isNotEmpty)
        .toList();
  }

  List<Student> get _searchResults {
    if (_searchQuery.isEmpty) return _unregisteredStudents;
    final q = _searchQuery.toLowerCase();
    return _unregisteredStudents
        .where(
          (s) =>
              s.id.toLowerCase().contains(q) ||
              s.name.toLowerCase().contains(q) ||
              s.school.toLowerCase().contains(q),
        )
        .toList();
  }

  int get _tuitionFee => _selectedFeeIds.fold(0, (sum, feeId) {
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

  int get _totalFee => _tuitionFee + _otherFeeAmount;

  int get _selectedDiscountAmount {
    if (_selectedDiscountId == null) return 0;

    final discount = _discounts.firstWhere(
      (d) => d.discountId == _selectedDiscountId,
      orElse: () => const DiscountModel(
        discountId: '',
        discountAmount: 0,
        discountDescription: '',
        academicYear: '',
      ),
    );
    final discountPercentage = discount.discountAmount.toInt();
    return ((_tuitionFee * discountPercentage) / 100).round();
  }

  int get _netFee {
    final amount = _totalFee - _selectedDiscountAmount;
    return amount < 0 ? 0 : amount;
  }

  String get _academicYearFromFees {
    if (_selectedFeeIds.isEmpty) return _currentAcademicYear;

    final selectedFees = _fees
        .where((f) => _selectedFeeIds.contains(f.feeId))
        .toList();
    if (selectedFees.isEmpty) return _currentAcademicYear;

    return selectedFees.first.academicYear;
  }

  String get _currentAcademicYear {
    if (_fees.isNotEmpty) {
      return _fees.first.academicYear;
    }
    return '';
  }

  int _defaultOtherFeeForStudent(Student? student) {
    final dormitory = student?.dormitoryName?.trim() ?? '';
    if (dormitory.contains('ຫໍພັກໃນ')) {
      return _dormitoryFees['ຫໍພັກໃນ']!;
    }
    if (dormitory.contains('ຫໍພັກນອກ')) {
      return _dormitoryFees['ຫໍພັກນອກ']!;
    }
    return 0;
  }

  String get _otherFeeLabel {
    final dormitory = _selectedStudent?.dormitoryName?.trim() ?? '';
    if (dormitory.contains('ຫໍພັກໃນ')) {
      return 'ຄ່າອື່ນໆ(ຄ່ານ້ຳ, ໄຟ, ຂີ້ເຫຍື້ອ)';
    }
    if (dormitory.contains('ຫໍພັກນອກ')) {
      return 'ຄ່າອື່ນໆ(ຄ່າໄຟ)';
    }
    return 'ຄ່າອື່ນໆ';
  }

  void _applyDefaultOtherFee(Student? student) {
    final defaultAmount = _defaultOtherFeeForStudent(student);
    _otherFeeAmount = defaultAmount;
    _otherFeeCtrl.text = defaultAmount > 0 ? defaultAmount.toString() : '';
  }

  int _parseAmount(String raw) {
    return int.tryParse(raw.replaceAll(',', '').trim()) ?? 0;
  }

  void _pickStudent(Student s) {
    setState(() {
      _selectedStudent = s;
      _currentStep = 2;
      _applyDefaultOtherFee(s);
    });
  }

  void _toggleFee(String feeId) {
    if (_selectedStudent == null) return;
    setState(() {
      if (_selectedFeeIds.contains(feeId)) {
        _selectedFeeIds.remove(feeId);
        _scholarshipStatusByFee.remove(feeId);
      } else {
        if (_selectedFeeIds.length >= 3) {
          AppToast.warning(
            context,
            'ນັກຮຽນສາມາດລົງທະບຽນໄດ້ສູງສຸດ 3 ວິຊາເທົ່ານັ້ນ',
          );
          return;
        }
        _selectedFeeIds.add(feeId);
        _scholarshipStatusByFee[feeId] = 'ບໍ່ໄດ້ຮັບທຶນ';
      }
      if (_selectedFeeIds.isNotEmpty && _currentStep < 3) {
        _currentStep = 3;
      } else if (_selectedFeeIds.isEmpty && _currentStep > 2) {
        _currentStep = 2;
      }
    });
  }

  void _setScholarshipStatus(String feeId, String status) {
    setState(() {
      _scholarshipStatusByFee[feeId] = status;
    });
  }

  void _handleClear() {
    setState(() {
      _selectedStudent = null;
      _selectedFeeIds.clear();
      _searchQuery = '';
      _searchCtrl.clear();
      _autoRenew = false;
      _currentStep = 1;
      _selectedDiscountId = null;
      _scholarshipStatusByFee = {};
      _otherFeeAmount = 0;
      _otherFeeCtrl.clear();
    });
  }

  void _handleSave() async {
    if (_selectedStudent == null || _selectedFeeIds.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    final request = RegistrationRequest(
      studentId: _selectedStudent!.id,
      discountId: _selectedDiscountId,
      totalAmount: _totalFee.toDouble(),
      finalAmount: _netFee.toDouble(),
      status: 'ຍັງບໍ່ທັນຈ່າຍ',
      registrationDate: DateTime.now(),
    );

    final details = _selectedFeeIds.map((feeId) {
      final scholarship = _scholarshipStatusByFee[feeId] ?? 'ບໍ່ໄດ້ຮັບທຶນ';
      return {
        'fee_id': feeId,
        'scholarship': scholarship == 'ໄດ້ຮັບທຶນ'
            ? 'ໄດ້ຮັບທຶນ'
            : 'ບໍ່ໄດ້ຮັບທຶນ',
      };
    }).toList();

    final success = await ref
        .read(registrationProvider.notifier)
        .createRegistrationAndDetails(request, details);

    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    if (success && mounted) {
      final lastReg = ref.read(registrationProvider).registrations.last;
      final selectedFeesList = _fees
          .where((f) => _selectedFeeIds.contains(f.feeId))
          .toList();
      final studentFullName =
          _selectedStudent?.fullName ?? lastReg.studentFullName;
      final tuition = _tuitionFee;
      final otherFeeLabel = _otherFeeLabel;
      final otherFeeAmount = _otherFeeAmount;
      final total = _totalFee;
      final discount = _selectedDiscountAmount;
      final net = _netFee;

      if (mounted) {
        setState(() => _isPreparingPrint = true);
        try {
          await showRegistrationPrintDialog(
            context: context,
            registrationId: lastReg.registrationId,
            registrationDate: lastReg.registrationDate,
            studentName: studentFullName,
            selectedFees: selectedFeesList,
            tuitionFee: tuition,
            dormitoryLabel: otherFeeLabel,
            dormitoryFee: otherFeeAmount,
            totalFee: total,
            discountAmount: discount,
            netFee: net,
            onPreviewReady: () {
              if (mounted && _isPreparingPrint) {
                setState(() => _isPreparingPrint = false);
              }
            },
          );
        } finally {
          if (mounted && _isPreparingPrint) {
            setState(() => _isPreparingPrint = false);
          }
        }
        _handleClear();
        ref.read(registrationProvider.notifier).getRegistrations();
      }
    } else if (mounted) {
      final error =
          ref.read(registrationProvider).error ??
          'ບັນທຶກບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່';
      AppToast.error(context, error);
    }
  }

  Future<void> _openAddStudentDialog() async {
    final createdStudent = await showDialog<Student>(
      context: context,
      builder: (dialogContext) =>
          _AddStudentDialog(academicYear: _currentAcademicYear),
    );

    if (createdStudent != null && mounted) {
      _pickStudent(createdStudent);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentProvider.notifier).getStudents();
      ref.read(feeProvider.notifier).getFees();
      ref.read(discountProvider.notifier).getDiscounts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _otherFeeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          Column(
            children: [
              _TopBar(
                steps: _steps,
                currentStep: _currentStep,
                onBack: () => context.pop(),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final wide = constraints.maxWidth >= Breakpoints.desktop;

                    final rightPanel = RightPanel(
                      step3num: 3,
                      step4num: 4,
                      step5num: 5,
                      selectedFees: _fees
                          .where((f) => _selectedFeeIds.contains(f.feeId))
                          .toList(),
                      onRemove: _toggleFee,
                      academicYear: _academicYearFromFees,
                      registrationDate: _fmtDate(DateTime.now()),
                      studentName: _selectedStudent?.fullName,
                      tuitionFee: _tuitionFee,
                      totalFee: _totalFee,
                      discount: _selectedDiscountAmount,
                      netFee: _netFee,
                      discounts: _discounts,
                      selectedDiscountId: _selectedDiscountId,
                      onDiscountChanged: (v) =>
                          setState(() => _selectedDiscountId = v),
                      otherFee: _otherFeeAmount,
                      otherFeeLabel: _otherFeeLabel,
                      otherFeeController: _otherFeeCtrl,
                      onOtherFeeChanged: (value) => setState(() {
                        _otherFeeAmount = _parseAmount(value);
                      }),
                      scholarshipStatusByFee: _scholarshipStatusByFee,
                      onScholarshipChanged: (feeId, status) =>
                          _setScholarshipStatus(feeId, status),
                      autoRenew: _autoRenew,
                      onAutoRenewChanged: (v) => setState(() => _autoRenew = v),
                      canSave:
                          _selectedStudent != null &&
                          _selectedFeeIds.isNotEmpty,
                      discountEnabled:
                          _selectedStudent != null &&
                          _selectedFeeIds.isNotEmpty,
                      onSave: _handleSave,
                      onPrint: () {},
                      onCancel: _handleClear,
                    );

                    final mainContent = SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 20, wide ? 12 : 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Step1Section(
                            currentStep: _currentStep,
                            searchQuery: _searchQuery,
                            searchCtrl: _searchCtrl,
                            students: _searchResults,
                            selectedStudent: _selectedStudent,
                            onQueryChanged: (v) =>
                                setState(() => _searchQuery = v),
                            onPickStudent: _pickStudent,
                            onClearStudent: _handleClear,
                            onAddStudent: _openAddStudentDialog,
                          ),
                          const SizedBox(height: 16),
                          SelectSubjectSection(
                            allFees: _fees,
                            selectedFeeIds: _selectedFeeIds,
                            isLoading: _isLoadingFees,
                            enabled: _selectedStudent != null,
                            onToggleFee: _toggleFee,
                          ),
                          if (!wide) ...[
                            const SizedBox(height: 20),
                            rightPanel,
                          ],
                        ],
                      ),
                    );

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: mainContent),
                          Container(
                            width: 620,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEF2FF),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                              child: rightPanel,
                            ),
                          ),
                        ],
                      );
                    }
                    return mainContent;
                  },
                ),
              ),
            ],
          ),
          if (_isPreparingPrint)
            const PrintPreparationOverlay(
              icon: Icons.print_rounded,
              title: 'ກຳລັງໂຫຼດ....',
              message:
                  'ລະບົບກຳລັງດຶງຂໍ້ມູນການລົງທະບຽນ ແລະ ສ້າງ preview ໃຫ້ພ້ອມສຳລັບການພິມ',
              hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
            ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const m = [
      'ມັງກອນ',
      'ກຸມພາ',
      'ມີນາ',
      'ເມສາ',
      'ພຶດສະພາ',
      'ມິຖຸນາ',
      'ກໍລະກົດ',
      'ສິງຫາ',
      'ກັນຍາ',
      'ຕຸລາ',
      'ພະຈິກ',
      'ທັນວາ',
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _TopBar extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final VoidCallback onBack;

  const _TopBar({
    required this.steps,
    required this.currentStep,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ກັບຄືນ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step1Section extends StatelessWidget {
  final int currentStep;
  final String searchQuery;
  final TextEditingController searchCtrl;
  final List<Student> students;
  final Student? selectedStudent;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Student> onPickStudent;
  final VoidCallback onClearStudent;
  final VoidCallback onAddStudent;

  const _Step1Section({
    required this.currentStep,
    required this.searchQuery,
    required this.searchCtrl,
    required this.students,
    required this.selectedStudent,
    required this.onQueryChanged,
    required this.onPickStudent,
    required this.onClearStudent,
    required this.onAddStudent,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      stepNum: 1,
      stepColor: AppColors.primary,
      icon: Icons.person_search_rounded,
      title: 'ກວດສອບຂໍ້ມູນນັກຮຽນ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExistingStudentSearch(
            key: const ValueKey('existing'),
            searchQuery: searchQuery,
            searchCtrl: searchCtrl,
            students: students,
            selectedStudent: selectedStudent,
            onQueryChanged: onQueryChanged,
            onPickStudent: onPickStudent,
            onClearStudent: onClearStudent,
            onAddStudent: onAddStudent,
          ),
        ],
      ),
    );
  }
}

class _ExistingStudentSearch extends StatelessWidget {
  final String searchQuery;
  final TextEditingController searchCtrl;
  final List<Student> students;
  final Student? selectedStudent;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Student> onPickStudent;
  final VoidCallback onClearStudent;
  final VoidCallback onAddStudent;

  const _ExistingStudentSearch({
    super.key,
    required this.searchQuery,
    required this.searchCtrl,
    required this.students,
    required this.selectedStudent,
    required this.onQueryChanged,
    required this.onPickStudent,
    required this.onClearStudent,
    required this.onAddStudent,
  });

  @override
  Widget build(BuildContext context) {
    final selectionItems = students
        .map(
          (s) => StudentSelectionItem(
            id: s.id,
            fullName: s.fullName,
            school: s.school,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentSelectionList(
          students: selectionItems,
          selectedStudentId: selectedStudent?.id,
          searchQuery: searchQuery,
          searchController: searchCtrl,
          onSearchChanged: onQueryChanged,
          action: AppButton(
            label: 'ເພີ່ມນັກຮຽນ',
            icon: Icons.person_add_rounded,
            onPressed: onAddStudent,
          ),
          onSelect: (item) {
            final student = students.firstWhere((s) => s.id == item.id);
            onPickStudent(student);
          },
          onClearSearch: () {
            searchCtrl.clear();
            onQueryChanged('');
          },
        ),
        if (selectedStudent != null) ...[
          const SizedBox(height: 16),
          SelectedStudentBanner(
            student: selectedStudent!,
            onClear: onClearStudent,
          ),
        ],
      ],
    );
  }
}

class _AddStudentDialog extends ConsumerStatefulWidget {
  final String academicYear;

  const _AddStudentDialog({required this.academicYear});

  @override
  ConsumerState<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends ConsumerState<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _parentPhoneFocusNode = FocusNode();
  final _schoolFocusNode = FocusNode();

  String _gender = 'ຊາຍ';
  int? _selectedProvinceId;
  int? _selectedDistrictId;
  String _dormitoryType = 'ຫໍພັກນອກ';
  bool _autoValidate = false;
  bool _isSaving = false;

  List<ProvinceModel> get _provinces => ref.watch(provinceProvider).provinces;
  List<DistrictModel> get _districts =>
      ref.watch(districtProvider).filteredDistricts;
  bool get _isLoadingProvinces => ref.watch(provinceProvider).isLoading;
  bool get _isLoadingDistricts => ref.watch(districtProvider).isLoading;

  bool get _isFormValid {
    return _firstNameCtrl.text.trim().isNotEmpty &&
        _lastNameCtrl.text.trim().isNotEmpty &&
        _phoneCtrl.text.trim().isNotEmpty &&
        _schoolCtrl.text.trim().isNotEmpty &&
        _selectedProvinceId != null &&
        _selectedDistrictId != null;
  }

  @override
  void initState() {
    super.initState();
    _firstNameCtrl.addListener(_onFormChanged);
    _lastNameCtrl.addListener(_onFormChanged);
    _phoneCtrl.addListener(_onFormChanged);
    _parentPhoneCtrl.addListener(_onFormChanged);
    _schoolCtrl.addListener(_onFormChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(provinceProvider.notifier).getProvinces();
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.removeListener(_onFormChanged);
    _lastNameCtrl.removeListener(_onFormChanged);
    _phoneCtrl.removeListener(_onFormChanged);
    _parentPhoneCtrl.removeListener(_onFormChanged);
    _schoolCtrl.removeListener(_onFormChanged);
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _parentPhoneCtrl.dispose();
    _schoolCtrl.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _parentPhoneFocusNode.dispose();
    _schoolFocusNode.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() {
      _autoValidate = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedProvinceId == null || _selectedDistrictId == null) {
      AppToast.warning(context, 'ກະລຸນາເລືອກແຂວງ ແລະ ເມືອງ');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final request = StudentRequest(
      studentName: _firstNameCtrl.text.trim(),
      studentLastname: _lastNameCtrl.text.trim(),
      gender: _gender,
      studentContact: _phoneCtrl.text.trim(),
      parentsContact: _parentPhoneCtrl.text.trim(),
      school: _schoolCtrl.text.trim(),
      districtId: _selectedDistrictId!,
      dormitoryType: _dormitoryType,
    );

    final success = await ref
        .read(studentProvider.notifier)
        .createStudent(request);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (!success) {
      final error =
          ref.read(studentProvider).error ??
          'ບັນທຶກຂໍ້ມູນບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່';
      AppToast.error(context, error);
      return;
    }

    StudentModel? created = ref.read(studentProvider).selectedStudent;
    created ??= ref.read(studentProvider).students.lastOrNull;
    if (created == null) {
      await ref.read(studentProvider.notifier).getStudents();
      if (!mounted) return;
      created = ref.read(studentProvider).students.lastOrNull;
    }

    if (created == null || !mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດດຶງຂໍ້ມູນນັກຮຽນໃໝ່ໄດ້');
      return;
    }

    await SuccessOverlay.show(context, message: 'ບັນທຶກຂໍ້ມູນນັກຮຽນສຳເລັດ');
    if (!mounted) return;

    Navigator.of(context).pop(
      Student(
        id: created.studentId ?? '',
        name: created.studentName,
        lastname: created.studentLastname,
        gender: created.gender,
        phone: created.studentContact,
        parentsContact: created.parentsContact,
        school: created.school,
        districtId: _selectedDistrictId.toString(),
        districtName: created.districtName,
        provinceName: created.provinceName,
        dormitoryId: created.dormitoryName,
        dormitoryName: created.dormitoryName,
        academicYear: widget.academicYear,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'ເພີ່ມນັກຮຽນໃໝ່',
      size: AppDialogSize.large,
      onClose: () => Navigator.of(context).pop(),
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
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: NewStudentForm(
          formKey: _formKey,
          firstNameCtrl: _firstNameCtrl,
          lastNameCtrl: _lastNameCtrl,
          phoneCtrl: _phoneCtrl,
          parentPhoneCtrl: _parentPhoneCtrl,
          schoolCtrl: _schoolCtrl,
          firstNameFocusNode: _firstNameFocusNode,
          lastNameFocusNode: _lastNameFocusNode,
          phoneFocusNode: _phoneFocusNode,
          parentPhoneFocusNode: _parentPhoneFocusNode,
          schoolFocusNode: _schoolFocusNode,
          gender: _gender,
          onGenderChanged: (value) => setState(() => _gender = value ?? 'ຊາຍ'),
          onConfirm: _save,
          isFormValid: _isFormValid,
          selectedStudent: null,
          onClear: () {},
          provinces: _provinces,
          selectedProvinceId: _selectedProvinceId,
          selectedDistrictId: _selectedDistrictId,
          availableDistricts: _districts,
          onProvinceChanged: (value) async {
            setState(() {
              _selectedProvinceId = value;
              _selectedDistrictId = null;
            });
            if (value != null) {
              await ref
                  .read(districtProvider.notifier)
                  .getDistrictsByProvince(value);
            }
          },
          onDistrictChanged: (value) =>
              setState(() => _selectedDistrictId = value),
          isLoadingProvinces: _isLoadingProvinces,
          isLoadingDistricts: _isLoadingDistricts,
          dormitoryType: _dormitoryType,
          onDormitoryChanged: (value) =>
              setState(() => _dormitoryType = value ?? 'ຫໍພັກນອກ'),
          showSubmitButton: false,
          wrapInForm: false,
        ),
      ),
    );
  }
}
