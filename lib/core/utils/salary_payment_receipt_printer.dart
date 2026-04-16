import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/salary_payment_service.dart';
import '../../widgets/app_toast.dart';
import 'receipt_printer.dart';

final SalaryPaymentService _salaryPaymentService = SalaryPaymentService();

Future<void> showSalaryPaymentPrintDialog({
  required BuildContext context,
  required String paymentId,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final pdfBytes = await _salaryPaymentService.createSalaryPaymentReceiptPdf(
      paymentId,
    );

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPrintDialog(
      context: context,
      pdfBytes: Uint8List.fromList(pdfBytes),
      documentId: paymentId,
      title: 'ພິມໃບບິນເບີກຈ່າຍເງິນສອນ',
      fileNamePrefix: 'salary_payment',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງໃບບິນໄດ້: $e');
    }
  }
}
