import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:palee_elite_training_center/widgets/mode_tab.dart';
import 'package:palee_elite_training_center/widgets/section_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/fee_model.dart';
import '../../models/student_model.dart';
import '../../models/registration_model.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/registration_provider.dart';
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
  final _steps = const [
    'ກວດສອບນັກຮຽນ',
    'ເລືອກວິຊາ',
    'ເລືອກສ່ວນຫຼຸດ',
    'ຢືນຢັນລົງທະບຽນ',
    'ພິມໃບລົງທະບຽນ',
  ];

  bool _isNewStudent = false;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Student? _selectedStudent;

  final _newStudentFormKey = GlobalKey<FormState>();
  final _newFirstNameCtrl = TextEditingController();
  final _newLastNameCtrl = TextEditingController();
  final _newPhoneCtrl = TextEditingController();
  final _newParentPhoneCtrl = TextEditingController();
  final _newSchoolCtrl = TextEditingController();
  String _newGender = 'ຊາຍ';

  int? _selectedProvinceId;
  int? _selectedDistrictId;

  String _selectedCategory = '';
  final Set<String> _selectedFeeIds = {};

  String? _selectedDiscountId;
  Map<String, String> _scholarshipStatusByFee = {};
  String _newDormitoryType = 'ຫໍພັກນອກ';
  bool _autoRenew = false;

  List<FeeModel> get _fees => ref.watch(feeProvider).fees;
  bool get _isLoadingFees => ref.watch(feeProvider).isLoading;
  List<DiscountModel> get _discounts => ref.watch(discountProvider).discounts;

  List<String> get _categories {
    final cats = _fees.map((f) => f.subjectCategory).toSet().toList()..sort();
    return cats;
  }

  List<FeeModel> get _filteredFees {
    if (_selectedCategory.isEmpty) return _fees;
    return _fees.where((f) => f.subjectCategory == _selectedCategory).toList();
  }

  List<StudentModel> get _apiStudents => ref.watch(studentProvider).students;
  List<ProvinceModel> get _provinces => ref.watch(provinceProvider).provinces;
  List<DistrictModel> get _filteredDistricts =>
      ref.watch(districtProvider).filteredDistricts;

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

  int get _totalFee => _selectedFeeIds.fold(0, (sum, feeId) {
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
    return ((_totalFee * discountPercentage) / 100).round();
  }

  int get _netFee => _totalFee - _selectedDiscountAmount;

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

  List<DistrictModel> get _availableDistricts {
    if (_selectedProvinceId == null) return [];
    return _filteredDistricts;
  }

  bool get _isNewStudentFormValid {
    return _newFirstNameCtrl.text.trim().isNotEmpty &&
        _newLastNameCtrl.text.trim().isNotEmpty &&
        _newPhoneCtrl.text.trim().isNotEmpty &&
        _newSchoolCtrl.text.trim().isNotEmpty &&
        _selectedProvinceId != null &&
        _selectedDistrictId != null;
  }

  void _pickStudent(Student s) {
    setState(() {
      _selectedStudent = s;
      _currentStep = 2;
      _selectedCategory = '';
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

  void _confirmNewStudent() async {
    if (!(_newStudentFormKey.currentState?.validate() ?? false)) return;
    if (_selectedProvinceId == null || _selectedDistrictId == null) {
      AppToast.warning(context, 'ກະລຸນາເລືອກແຂວງ ແລະ ເມືອງ');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    final request = StudentRequest(
      studentName: _newFirstNameCtrl.text.trim(),
      studentLastname: _newLastNameCtrl.text.trim(),
      gender: _newGender,
      studentContact: _newPhoneCtrl.text.trim(),
      parentsContact: _newParentPhoneCtrl.text.trim(),
      school: _newSchoolCtrl.text.trim(),
      districtId: _selectedDistrictId!,
      dormitoryType: _newDormitoryType,
    );

    final success = await ref
        .read(studentProvider.notifier)
        .createStudent(request);

    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    if (success && mounted) {
      final newStudent = ref.read(studentProvider).selectedStudent;
      if (newStudent != null) {
        final student = Student(
          id: newStudent.studentId ?? '',
          name: newStudent.studentName,
          lastname: newStudent.studentLastname,
          gender: newStudent.gender,
          phone: newStudent.studentContact,
          parentsContact: newStudent.parentsContact,
          school: newStudent.school,
          districtId: _selectedDistrictId.toString(),
          districtName: newStudent.districtName,
          provinceName: newStudent.provinceName,
          dormitoryId: newStudent.dormitoryName,
          dormitoryName: newStudent.dormitoryName,
          academicYear: _currentAcademicYear,
        );
        //await SuccessOverlay.show(context, message: 'ບັນທຶກຂໍ້ມູນນັກຮຽນສຳເລັດ');
        if (mounted) _pickStudent(student);
      } else {
        await ref.read(studentProvider.notifier).getStudents();
        final students = ref.read(studentProvider).students;
        if (students.isNotEmpty && mounted) {
          final last = students.last;
          final student = Student(
            id: last.studentId ?? '',
            name: last.studentName,
            lastname: last.studentLastname,
            gender: last.gender,
            phone: last.studentContact,
            parentsContact: last.parentsContact,
            school: last.school,
            districtId: _selectedDistrictId.toString(),
            districtName: last.districtName,
            provinceName: last.provinceName,
            dormitoryId: last.dormitoryName,
            dormitoryName: last.dormitoryName,
            academicYear: _currentAcademicYear,
          );
          await SuccessOverlay.show(
            context,
            message: 'ບັນທຶກຂໍ້ມູນນັກຮຽນສຳເລັດ',
          );
          if (mounted) _pickStudent(student);
        }
      }
    } else if (mounted) {
      AppToast.error(context, 'ບັນທຶກຂໍ້ມູນບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່');
    }
  }

  void _handleClear() {
    setState(() {
      _selectedStudent = null;
      _selectedFeeIds.clear();
      _searchQuery = '';
      _searchCtrl.clear();
      _selectedCategory = '';
      _autoRenew = false;
      _currentStep = 1;
      _isNewStudent = false;
      _newFirstNameCtrl.clear();
      _newLastNameCtrl.clear();
      _newPhoneCtrl.clear();
      _newParentPhoneCtrl.clear();
      _newSchoolCtrl.clear();
      _newGender = 'ຊາຍ';
      _newDormitoryType = 'ຫໍພັກນອກ';
      _selectedProvinceId = null;
      _selectedDistrictId = null;
      _selectedDiscountId = null;
      _scholarshipStatusByFee = {};
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
      final total = _totalFee;
      final discount = _selectedDiscountAmount;
      final net = _netFee;

      //await SuccessOverlay.show(context, message: 'ບັນທຶກການລົງທະບຽນສຳເລັດ');
      if (mounted) {
        _handleClear();
        await showRegistrationPrintDialog(
          context: context,
          registrationId: lastReg.registrationId,
          registrationDate: lastReg.registrationDate,
          studentName: studentFullName,
          selectedFees: selectedFeesList,
          totalFee: total,
          discountAmount: discount,
          netFee: net,
        );
        ref.read(registrationProvider.notifier).getRegistrations();
      }
    } else if (mounted) {
      final error =
          ref.read(registrationProvider).error ??
          'ບັນທຶກບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່';
      AppToast.error(context, error);
    }
  }

  void _onNewStudentFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _newFirstNameCtrl.addListener(_onNewStudentFormChanged);
    _newLastNameCtrl.addListener(_onNewStudentFormChanged);
    _newPhoneCtrl.addListener(_onNewStudentFormChanged);
    _newSchoolCtrl.addListener(_onNewStudentFormChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentProvider.notifier).getStudents();
      ref.read(feeProvider.notifier).getFees();
      ref.read(discountProvider.notifier).getDiscounts();
      ref.read(provinceProvider.notifier).getProvinces();
    });
  }

  @override
  void dispose() {
    _newFirstNameCtrl.removeListener(_onNewStudentFormChanged);
    _newLastNameCtrl.removeListener(_onNewStudentFormChanged);
    _newPhoneCtrl.removeListener(_onNewStudentFormChanged);
    _newSchoolCtrl.removeListener(_onNewStudentFormChanged);
    _searchCtrl.dispose();
    _newFirstNameCtrl.dispose();
    _newLastNameCtrl.dispose();
    _newPhoneCtrl.dispose();
    _newParentPhoneCtrl.dispose();
    _newSchoolCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
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
                  studentName: _selectedStudent?.name,
                  totalFee: _totalFee,
                  discount: _selectedDiscountAmount,
                  netFee: _netFee,
                  discounts: _discounts,
                  selectedDiscountId: _selectedDiscountId,
                  onDiscountChanged: (v) =>
                      setState(() => _selectedDiscountId = v),
                  scholarshipStatusByFee: _scholarshipStatusByFee,
                  onScholarshipChanged: (feeId, status) =>
                      _setScholarshipStatus(feeId, status),
                  autoRenew: _autoRenew,
                  onAutoRenewChanged: (v) => setState(() => _autoRenew = v),
                  canSave:
                      _selectedStudent != null && _selectedFeeIds.isNotEmpty,
                  discountEnabled:
                      _selectedStudent != null && _selectedFeeIds.isNotEmpty,
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
                        isNewStudent: _isNewStudent,
                        onModeChanged: (v) => setState(() {
                          _isNewStudent = v;
                          _searchQuery = '';
                          _searchCtrl.clear();
                          _newFirstNameCtrl.clear();
                          _newLastNameCtrl.clear();
                          _newPhoneCtrl.clear();
                          _newParentPhoneCtrl.clear();
                          _newSchoolCtrl.clear();
                          _newGender = 'ຊາຍ';
                          _newDormitoryType = 'ຫໍພັກນອກ';
                          _selectedProvinceId = null;
                          _selectedDistrictId = null;
                        }),
                        currentStep: _currentStep,
                        searchQuery: _searchQuery,
                        searchCtrl: _searchCtrl,
                        students: _searchResults,
                        selectedStudent: _selectedStudent,
                        onQueryChanged: (v) => setState(() => _searchQuery = v),
                        onPickStudent: _pickStudent,
                        onClearStudent: _handleClear,
                        formKey: _newStudentFormKey,
                        firstNameCtrl: _newFirstNameCtrl,
                        lastNameCtrl: _newLastNameCtrl,
                        phoneCtrl: _newPhoneCtrl,
                        parentPhoneCtrl: _newParentPhoneCtrl,
                        schoolCtrl: _newSchoolCtrl,
                        gender: _newGender,
                        onGenderChanged: (v) => setState(() => _newGender = v!),
                        onConfirmNewStudent: _confirmNewStudent,
                        isNewStudentFormValid: _isNewStudentFormValid,
                        provinces: _provinces,
                        selectedProvinceId: _selectedProvinceId,
                        selectedDistrictId: _selectedDistrictId,
                        availableDistricts: _availableDistricts,
                        onProvinceChanged: (v) async {
                          setState(() {
                            _selectedProvinceId = v;
                            _selectedDistrictId = null;
                          });
                          if (v != null) {
                            await ref
                                .read(districtProvider.notifier)
                                .getDistrictsByProvince(v);
                          }
                        },
                        onDistrictChanged: (v) =>
                            setState(() => _selectedDistrictId = v),
                        isLoadingProvinces: ref
                            .watch(provinceProvider)
                            .isLoading,
                        isLoadingDistricts: ref
                            .watch(districtProvider)
                            .isLoading,
                        dormitoryType: _newDormitoryType,
                        onDormitoryChanged: (v) =>
                            setState(() => _newDormitoryType = v ?? 'ຫໍພັກນອກ'),
                      ),
                      const SizedBox(height: 16),
                      SelectSubjectSection(
                        categories: _categories,
                        selectedCategory: _selectedCategory,
                        allFees: _fees,
                        filteredFees: _filteredFees,
                        selectedFeeIds: _selectedFeeIds,
                        isLoading: _isLoadingFees,
                        enabled: _selectedStudent != null,
                        onCategoryChanged: (c) =>
                            setState(() => _selectedCategory = c),
                        onToggleFee: _toggleFee,
                      ),
                      if (!wide) ...[const SizedBox(height: 20), rightPanel],
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
    );
  }

  String _fmtDate(DateTime dt) {
    const m = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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

          // Container(
          //   width: 1,
          //   height: 32,
          //   margin: const EdgeInsets.symmetric(horizontal: 20),
          //   color: const Color(0xFFE2E8F0),
          // ),

          // Expanded(
          //   child: SingleChildScrollView(
          //     scrollDirection: Axis.horizontal,
          //     child: Row(
          //       children: List.generate(steps.length, (i) {
          //         final n = i + 1;
          //         final active = n == currentStep;
          //         final done = n < currentStep;
          //         return Row(
          //           mainAxisSize: MainAxisSize.min,
          //           children: [
          //             if (i > 0)
          //               Container(
          //                 width: 28,
          //                 height: 2,
          //                 margin: const EdgeInsets.symmetric(horizontal: 4),
          //                 decoration: BoxDecoration(
          //                   borderRadius: BorderRadius.circular(2),
          //                   color: done
          //                       ? AppColors.primary
          //                       : const Color(0xFFE2E8F0),
          //                 ),
          //               ),
          //             AnimatedContainer(
          //               duration: const Duration(milliseconds: 200),
          //               padding: EdgeInsets.symmetric(
          //                 horizontal: active ? 12 : 8,
          //                 vertical: 6,
          //               ),
          //               decoration: BoxDecoration(
          //                 color: active
          //                     ? AppColors.primary
          //                     : done
          //                     ? AppColors.primaryLight
          //                     : Colors.transparent,
          //                 borderRadius: BorderRadius.circular(22),
          //                 boxShadow: active
          //                     ? [
          //                         BoxShadow(
          //                           color: AppColors.primary.withValues(
          //                             alpha: 0.28,
          //                           ),
          //                           blurRadius: 10,
          //                           offset: const Offset(0, 3),
          //                         ),
          //                       ]
          //                     : null,
          //               ),
          //               child: Row(
          //                 mainAxisSize: MainAxisSize.min,
          //                 children: [
          //                   Container(
          //                     width: 22,
          //                     height: 22,
          //                     decoration: BoxDecoration(
          //                       color: active
          //                           ? Colors.white
          //                           : done
          //                           ? AppColors.primary
          //                           : const Color(0xFFE2E8F0),
          //                       shape: BoxShape.circle,
          //                     ),
          //                     child: Center(
          //                       child: done
          //                           ? const Icon(
          //                               Icons.check_rounded,
          //                               size: 13,
          //                               color: Colors.white,
          //                             )
          //                           : Text(
          //                               '$n',
          //                               style: TextStyle(
          //                                 fontSize: 11,
          //                                 fontWeight: FontWeight.w700,
          //                                 color: active
          //                                     ? AppColors.primary
          //                                     : const Color(0xFF94A3B8),
          //                               ),
          //                             ),
          //                     ),
          //                   ),
          //                   const SizedBox(width: 7),
          //                   Text(
          //                     steps[i],
          //                     style: TextStyle(
          //                       fontSize: 13,
          //                       fontWeight: active
          //                           ? FontWeight.w700
          //                           : FontWeight.w500,
          //                       color: active
          //                           ? Colors.white
          //                           : done
          //                           ? AppColors.primary
          //                           : const Color(0xFF94A3B8),
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ],
          //         );
          //       }),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _Step1Section extends StatelessWidget {
  final bool isNewStudent;
  final ValueChanged<bool> onModeChanged;
  final int currentStep;
  final String searchQuery;
  final TextEditingController searchCtrl;
  final List<Student> students;
  final Student? selectedStudent;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Student> onPickStudent;
  final VoidCallback onClearStudent;
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController parentPhoneCtrl;
  final TextEditingController schoolCtrl;
  final String gender;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onConfirmNewStudent;
  final bool isNewStudentFormValid;
  final List<ProvinceModel> provinces;
  final int? selectedProvinceId;
  final int? selectedDistrictId;
  final List<DistrictModel> availableDistricts;
  final ValueChanged<int?> onProvinceChanged;
  final ValueChanged<int?> onDistrictChanged;
  final bool isLoadingProvinces;
  final bool isLoadingDistricts;
  final String dormitoryType;
  final ValueChanged<String?> onDormitoryChanged;

  const _Step1Section({
    required this.isNewStudent,
    required this.onModeChanged,
    required this.currentStep,
    required this.searchQuery,
    required this.searchCtrl,
    required this.students,
    required this.selectedStudent,
    required this.onQueryChanged,
    required this.onPickStudent,
    required this.onClearStudent,
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
    required this.parentPhoneCtrl,
    required this.schoolCtrl,
    required this.gender,
    required this.onGenderChanged,
    required this.onConfirmNewStudent,
    required this.isNewStudentFormValid,
    required this.provinces,
    required this.selectedProvinceId,
    required this.selectedDistrictId,
    required this.availableDistricts,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
    required this.isLoadingProvinces,
    required this.isLoadingDistricts,
    required this.dormitoryType,
    required this.onDormitoryChanged,
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
          Container(
            decoration: BoxDecoration(
              color: AppColors.muted, // surface/muted background
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                ModeTab(
                  label: 'ນັກຮຽນເກົ່າ',
                  icon: Icons.search_sharp,
                  active: !isNewStudent,
                  activeColor: AppColors.primary,
                  onTap: () => onModeChanged(false),
                ),
                ModeTab(
                  label: 'ນັກຮຽນໃໝ່',
                  icon: Icons.person_add_rounded,
                  active: isNewStudent,
                  activeColor: AppColors.primary,
                  onTap: () => onModeChanged(true),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          isNewStudent
              ? NewStudentForm(
                  key: const ValueKey('new'),
                  formKey: formKey,
                  firstNameCtrl: firstNameCtrl,
                  lastNameCtrl: lastNameCtrl,
                  phoneCtrl: phoneCtrl,
                  parentPhoneCtrl: parentPhoneCtrl,
                  schoolCtrl: schoolCtrl,
                  gender: gender,
                  onGenderChanged: onGenderChanged,
                  onConfirm: onConfirmNewStudent,
                  isFormValid: isNewStudentFormValid,
                  selectedStudent: selectedStudent,
                  onClear: onClearStudent,
                  provinces: provinces,
                  selectedProvinceId: selectedProvinceId,
                  selectedDistrictId: selectedDistrictId,
                  availableDistricts: availableDistricts,
                  onProvinceChanged: onProvinceChanged,
                  onDistrictChanged: onDistrictChanged,
                  isLoadingProvinces: isLoadingProvinces,
                  isLoadingDistricts: isLoadingDistricts,
                  dormitoryType: dormitoryType,
                  onDormitoryChanged: onDormitoryChanged,
                )
              : _ExistingStudentSearch(
                  key: const ValueKey('existing'),
                  searchQuery: searchQuery,
                  searchCtrl: searchCtrl,
                  students: students,
                  selectedStudent: selectedStudent,
                  onQueryChanged: onQueryChanged,
                  onPickStudent: onPickStudent,
                  onClearStudent: onClearStudent,
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

  const _ExistingStudentSearch({
    super.key,
    required this.searchQuery,
    required this.searchCtrl,
    required this.students,
    required this.selectedStudent,
    required this.onQueryChanged,
    required this.onPickStudent,
    required this.onClearStudent,
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
