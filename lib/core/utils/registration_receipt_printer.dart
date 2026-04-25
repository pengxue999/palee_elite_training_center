import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/fee_model.dart';
import '../../services/registration_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final RegistrationService _registrationService = RegistrationService();

Future<void> showRegistrationPrintDialog({
  required BuildContext context,
  required String registrationId,
  required String registrationDate,
  required String studentName,
  required List<FeeModel> selectedFees,
  required int tuitionFee,
  required String? dormitoryLabel,
  required int dormitoryFee,
  required int totalFee,
  required int discountAmount,
  required int netFee,
  VoidCallback? onPreviewReady,
}) async {
  final pdfBytes = await _buildPdf(
    registrationId: registrationId,
    registrationDate: registrationDate,
    studentName: studentName,
    selectedFees: selectedFees,
    tuitionFee: tuitionFee,
    dormitoryLabel: dormitoryLabel,
    dormitoryFee: dormitoryFee,
    totalFee: totalFee,
    discountAmount: discountAmount,
    netFee: netFee,
  );

  if (pdfBytes == null) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງໃບລົງທະບຽນໄດ້');
    }
    return;
  }

  if (context.mounted) {
    onPreviewReady?.call();
    await showPdfPreviewDialog(
      context: context,
      pdfBytes: pdfBytes,
      documentId: registrationId,
      title: 'ພິມໃບລົງທະບຽນ',
      fileNamePrefix: 'register',
    );
  }
}

Future<void> printRegistrationReceipt({
  required BuildContext context,
  required String registrationId,
  required String registrationDate,
  required String studentName,
  required List<FeeModel> selectedFees,
  required int tuitionFee,
  required String? dormitoryLabel,
  required int dormitoryFee,
  required int totalFee,
  required int discountAmount,
  required int netFee,
  VoidCallback? onPreviewReady,
}) => showRegistrationPrintDialog(
  context: context,
  registrationId: registrationId,
  registrationDate: registrationDate,
  studentName: studentName,
  selectedFees: selectedFees,
  tuitionFee: tuitionFee,
  dormitoryLabel: dormitoryLabel,
  dormitoryFee: dormitoryFee,
  totalFee: totalFee,
  discountAmount: discountAmount,
  netFee: netFee,
  onPreviewReady: onPreviewReady,
);

Future<Uint8List?> _buildPdf({
  required String registrationId,
  required String registrationDate,
  required String studentName,
  required List<FeeModel> selectedFees,
  required int tuitionFee,
  required String? dormitoryLabel,
  required int dormitoryFee,
  required int totalFee,
  required int discountAmount,
  required int netFee,
}) async {
  try {
    return await _registrationService.createRegistrationReceiptPdf(
      registrationId: registrationId,
      registrationDate: _normalizeReceiptDateForApi(registrationDate),
      studentName: studentName,
      selectedFees: selectedFees
          .map(
            (fee) => {
              'subject_name': fee.subjectName,
              'level_name': fee.levelName,
              'fee': fee.fee.toInt(),
            },
          )
          .toList(growable: false),
      tuitionFee: tuitionFee,
      dormitoryLabel: dormitoryLabel,
      dormitoryFee: dormitoryFee,
      totalFee: totalFee,
      discountAmount: discountAmount,
      netFee: netFee,
    );
  } catch (_) {
    return null;
  }
}

String _normalizeReceiptDateForApi(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  final direct = DateTime.tryParse(trimmed);
  if (direct != null) {
    return direct.toIso8601String();
  }

  final knownFormats = [
    DateFormat('dd/MM/yyyy'),
    DateFormat('dd-MM-yyyy HH:mm:ss'),
    DateFormat('dd-MM-yyyy'),
  ];

  for (final format in knownFormats) {
    try {
      return format.parseStrict(trimmed).toIso8601String();
    } catch (_) {
      // Try the next supported display format.
    }
  }

  return trimmed;
}
