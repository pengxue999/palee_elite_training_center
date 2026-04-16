import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/tuition_payment_service.dart';
import '../../widgets/app_toast.dart';
import 'receipt_printer.dart';

final TuitionPaymentService _tuitionPaymentService = TuitionPaymentService();

Future<void> showTuitionPaymentPrintDialog({
  required BuildContext context,
  required String paymentId,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final pdfBytes = await _tuitionPaymentService
        .createTuitionPaymentReceiptPdf(paymentId);

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPrintDialog(
      context: context,
      pdfBytes: Uint8List.fromList(pdfBytes),
      documentId: paymentId,
      title: 'ພິມໃບບິນຄ່າຮຽນ',
      fileNamePrefix: 'tuition_payment',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງໃບບິນໄດ້: $e');
    }
  }
}
