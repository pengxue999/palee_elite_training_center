import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/responsive_utils.dart';
import '../../providers/salary_payment_provider.dart';
import 'widgets/salary_teacher_list.dart';
import 'widgets/salary_payment_detail.dart';

class SalaryPaymentScreen extends ConsumerStatefulWidget {
  const SalaryPaymentScreen({super.key});

  @override
  ConsumerState<SalaryPaymentScreen> createState() =>
      _SalaryPaymentScreenState();
}

class _SalaryPaymentScreenState extends ConsumerState<SalaryPaymentScreen> {
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salaryPaymentProvider.notifier).loadTeachingMonths();
      ref.read(salaryPaymentProvider.notifier).loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTeacherId = ref.watch(
      salaryPaymentProvider.select((s) => s.selectedTeacherId),
    );

    final isMobile = context.isMobile;

    final leftWidth = context.responsiveValue(
      mobile: double.infinity,
      tablet: 320.0,
      desktop: 500.0,
      wideDesktop: 720.0,
    );

    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            height: 340,
            child: SalaryTeacherList(
              onSelectTeacher: (id) =>
                  ref.read(salaryPaymentProvider.notifier).selectTeacher(id),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: PageStorage(
              bucket: _bucket,
              child: SalaryPaymentDetailWrapper(teacherId: selectedTeacherId),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: leftWidth,
          child: SalaryTeacherList(
            onSelectTeacher: (id) =>
                ref.read(salaryPaymentProvider.notifier).selectTeacher(id),
          ),
        ),
        Expanded(
          child: PageStorage(
            bucket: _bucket,
            child: SalaryPaymentDetailWrapper(teacherId: selectedTeacherId),
          ),
        ),
        SizedBox(width: 16),
      ],
    );
  }
}

class SalaryPaymentDetailWrapper extends StatelessWidget {
  final String? teacherId;
  const SalaryPaymentDetailWrapper({super.key, this.teacherId});

  @override
  Widget build(BuildContext context) {
    return SalaryPaymentDetail(
      key: const ValueKey('salary_payment_detail_fixed'),
      teacherId: teacherId,
    );
  }
}
