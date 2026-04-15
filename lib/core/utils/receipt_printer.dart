import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/fee_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_toast.dart';

Future<void> showRegistrationPrintDialog({
  required BuildContext context,
  required String registrationId,
  required String registrationDate,
  required String studentName,
  required List<FeeModel> selectedFees,
  required int totalFee,
  required int discountAmount,
  required int netFee,
}) async {
  final pdfBytes = await _buildPdf(
    registrationId: registrationId,
    registrationDate: registrationDate,
    studentName: studentName,
    selectedFees: selectedFees,
    totalFee: totalFee,
    discountAmount: discountAmount,
    netFee: netFee,
  );

  if (pdfBytes == null) return;

  if (context.mounted) {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) =>
          _PrintDialog(pdfBytes: pdfBytes, registrationId: registrationId),
    );
  }
}

Future<void> printRegistrationReceipt({
  required BuildContext context,
  required String registrationId,
  required String registrationDate,
  required String studentName,
  required List<FeeModel> selectedFees,
  required int totalFee,
  required int discountAmount,
  required int netFee,
}) => showRegistrationPrintDialog(
  context: context,
  registrationId: registrationId,
  registrationDate: registrationDate,
  studentName: studentName,
  selectedFees: selectedFees,
  totalFee: totalFee,
  discountAmount: discountAmount,
  netFee: netFee,
);

class _PrintDialog extends StatefulWidget {
  final Uint8List pdfBytes;
  final String registrationId;

  const _PrintDialog({required this.pdfBytes, required this.registrationId});

  @override
  State<_PrintDialog> createState() => _PrintDialogState();
}

class _PrintDialogState extends State<_PrintDialog>
    with SingleTickerProviderStateMixin {
  List<Printer> _printers = [];
  Printer? _selectedPrinter;
  bool _loadingPrinters = true;
  bool _printing = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool get _useSystemPrintDialog => kIsWeb;

  bool _isVirtualPdfPrinter(Printer printer) {
    final normalized = printer.name.toLowerCase();
    return normalized.contains('print to pdf') ||
        normalized.contains('pdf') ||
        normalized.contains('xps');
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _loadPrinters();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrinters() async {
    if (_useSystemPrintDialog) {
      if (mounted) {
        setState(() => _loadingPrinters = false);
      }
      return;
    }

    try {
      final list = await Printing.listPrinters();
      final availablePrinters = defaultTargetPlatform == TargetPlatform.windows
          ? list.where((printer) => !_isVirtualPdfPrinter(printer)).toList()
          : list;
      if (mounted) {
        final defaultPrinter = availablePrinters.where(
          (printer) => printer.isDefault,
        );
        setState(() {
          _printers = availablePrinters;
          _selectedPrinter = defaultPrinter.isNotEmpty
              ? defaultPrinter.first
              : (availablePrinters.isNotEmpty ? availablePrinters.first : null);
          _loadingPrinters = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPrinters = false);
    }
  }

  Future<void> _doPrint() async {
    if (!_useSystemPrintDialog && _selectedPrinter == null) {
      await _doSavePdf();
      return;
    }

    setState(() => _printing = true);
    try {
      if (_useSystemPrintDialog) {
        await _doSavePdf();
        return;
      }

      await Printing.directPrintPdf(
        printer: _selectedPrinter!,
        onLayout: (_) async => widget.pdfBytes,
        name: 'register_${widget.registrationId}',
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      _showSuccessSnackBar(
        _useSystemPrintDialog ? 'ເປີດໜ້າຕ່າງພິມແລ້ວ' : 'ພິມສຳເລັດ!',
      );
    } catch (e) {
      debugPrint('Print error: $e');
      if (mounted) {
        setState(() => _printing = false);
        _showErrorSnackBar('ພິມບໍ່ສຳເລັດ: $e');
      }
    }
  }

  Future<void> _doSavePdf() async {
    setState(() => _printing = true);
    try {
      final fileName =
          'register_${widget.registrationId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (kIsWeb) {
        await XFile.fromData(
          widget.pdfBytes,
          mimeType: 'application/pdf',
          name: fileName,
        ).saveTo(fileName);
      } else {
        final location = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: const [
            XTypeGroup(label: 'PDF', extensions: ['pdf']),
          ],
        );

        if (location == null) {
          if (mounted) {
            setState(() => _printing = false);
          }
          return;
        }

        await XFile.fromData(
          widget.pdfBytes,
          mimeType: 'application/pdf',
          name: fileName,
        ).saveTo(location.path);
      }

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackBar('PDF ບັນທຶກສຳເລັດ: $fileName');
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        setState(() => _printing = false);
        _showErrorSnackBar('ບັນທຶກບໍ່ສຳເລັດ: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    AppToast.success(context, message);
  }

  void _showErrorSnackBar(String message) {
    AppToast.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          child: Container(
            width: 860,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 48,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildBody()),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.print_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ພິມໃບລົງທະບຽນ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ເລືອກເຄື່ອງປິ້ນເຕີ',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPreviewSidePanel(),

        Expanded(
          child: Container(
            color: const Color(0xFFE2E8F0),
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SfPdfViewer.memory(
                widget.pdfBytes,
                canShowPaginationDialog: true,
                canShowScrollHead: true,
                pageSpacing: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSidePanel() {
    if (_useSystemPrintDialog) {
      final isWeb = kIsWeb;
      return Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isWeb
                      ? Icons.language_rounded
                      : Icons.desktop_windows_rounded,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  isWeb ? 'Web Printing' : 'Windows Printing',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.print_outlined,
                    color: AppColors.primary,
                    size: 26,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isWeb
                        ? 'ໃນ Web ລະບົບຈະເປີດໜ້າຕ່າງພິມຂອງ browser ໂດຍກົງ'
                        : 'ໃນ Windows ລະບົບຈະເປີດ system print dialog ເພື່ອຫຼີກບັນຫາ crash ຈາກ direct print',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isWeb
                        ? 'ການບັນທຶກ PDF ຈະເລີ່ມ download ຫຼືໃຫ້ເລືອກບ່ອນບັນທຶກຕາມ browser ທີ່ໃຊ້'
                        : 'ເຄື່ອງປິ້ນ ແລະ ຄ່າການພິມຈະເລືອກໃນໜ້າຕ່າງພິມຂອງ Windows',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(
                  Icons.devices_rounded,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  'ເຄື່ອງປິ່ນເຕີທີ່ມີ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingPrinters
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'ກຳລັງໂຫຼດ...',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  )
                : _printers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.print_disabled_rounded,
                            size: 40,
                            color: AppColors.mutedForeground.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ບໍ່ພົບເຄື່ອງປິ່ນເຕີ\nກະລຸນາເຊື່ອມຕໍ່ກ່ອນ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: _printers.length,
                    itemBuilder: (_, i) {
                      final printer = _printers[i];
                      final selected = _selectedPrinter?.name == printer.name;
                      return _PrinterTile(
                        printer: printer,
                        selected: selected,
                        onTap: () => setState(() => _selectedPrinter = printer),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final canPrint = !_printing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (_useSystemPrintDialog) ...[
                Icon(
                  kIsWeb ? Icons.public_rounded : Icons.print_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kIsWeb
                        ? 'Web ຈະໃຊ້ໜ້າຕ່າງພິມຂອງ browser'
                        : 'ລະບົບຈະເປີດໜ້າຕ່າງພິມ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else if (_selectedPrinter != null) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedPrinter!.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                Expanded(
                  child: Text(
                    'ຖ້າບໍ່ມີ ຫຼື ຍັງບໍ່ໄດ້ເລືອກເຄື່ອງປິ່ນເຕີ, ລະບົບຈະບັນທຶກ PDF ແທນ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                onPressed: () => Navigator.of(context).pop(),
                label: 'ຍົກເລີກ',
                icon: Icons.close_rounded,
                variant: AppButtonVariant.danger,
              ),
              const SizedBox(width: 12),
              AppButton(
                onPressed: _printing ? null : _doSavePdf,
                label: 'ບັນທຶກ PDF',
                icon: Icons.download_rounded,
                variant: AppButtonVariant.success,
              ),
              const SizedBox(width: 12),
              AppButton(
                onPressed: canPrint ? _doPrint : null,
                label: _printing ? 'ກຳລັງພິມ...' : 'ພິມ',
                icon: Icons.print_rounded,
                variant: AppButtonVariant.primary,
                isLoading: _printing,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrinterTile extends StatelessWidget {
  final Printer printer;
  final bool selected;
  final VoidCallback onTap;

  const _PrinterTile({
    required this.printer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.muted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    printer.isDefault
                        ? Icons.print_rounded
                        : Icons.print_outlined,
                    size: 18,
                    color: selected
                        ? AppColors.primary
                        : AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? AppColors.primary
                              : AppColors.foreground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (printer.isDefault) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<Uint8List?> _buildPdf({
  required String registrationId,
  required String registrationDate,
  required String studentName,
  required List<FeeModel> selectedFees,
  required int totalFee,
  required int discountAmount,
  required int netFee,
}) async {
  try {
    final receiptImageBytes = await _buildReceiptImage(
      registrationId: registrationId,
      registrationDate: registrationDate,
      studentName: studentName,
      selectedFees: selectedFees,
      totalFee: totalFee,
      discountAmount: discountAmount,
      netFee: netFee,
    );

    final doc = pw.Document();
    final receiptImage = pw.MemoryImage(receiptImageBytes);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.SizedBox.expand(
            child: pw.Image(receiptImage, fit: pw.BoxFit.fill),
          );
        },
      ),
    );

    return doc.save();
  } catch (e) {
    debugPrint('✗ PDF build failed: $e');
    return null;
  }
}

Future<Uint8List> _buildReceiptImage({
  required String registrationId,
  required String registrationDate,
  required String studentName,
  required List<FeeModel> selectedFees,
  required int totalFee,
  required int discountAmount,
  required int netFee,
}) async {
  const pageWidth = 1240.0;
  const pageHeight = 1754.0;
  const fontScale = 1.4;
  const horizontalPadding = 72.0;
  const topPadding = 74.0;
  const blockGap = 24.0;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    const Rect.fromLTWH(0, 0, pageWidth, pageHeight),
  );

  canvas.drawRect(
    const Rect.fromLTWH(0, 0, pageWidth, pageHeight),
    Paint()..color = Colors.white,
  );

  final textColor = const Color(0xFF252525);
  final mutedColor = const Color(0xFF8A8A8A);
  final borderColor = const Color(0xFFE4E4E4);
  final strongBorderColor = const Color(0xFFBDBDBD);
  final successColor = const Color(0xFF15803D);

  void drawRule({
    required Offset start,
    required Offset end,
    required Color color,
    double strokeWidth = 1,
  }) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth,
    );
  }

  String fmt(int n) => NumberFormat('#,###').format(n);

  String fmtDate(String value) {
    try {
      final parsed = DateTime.parse(value);
      final hasTime =
          parsed.hour != 0 || parsed.minute != 0 || parsed.second != 0;
      return hasTime
          ? DateFormat('dd-MM-yyyy HH:mm:ss').format(parsed)
          : DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return value;
    }
  }

  TextStyle style({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = Colors.black,
    double height = 1.3,
  }) {
    return TextStyle(
      fontFamily: 'NotoSansLao',
      fontSize: fontSize * fontScale,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  TextPainter layoutText(
    String text,
    TextStyle textStyle, {
    double? maxWidth,
    TextAlign textAlign = TextAlign.left,
    int? maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: textAlign,
      textDirection: ui.TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '...',
    );
    painter.layout(maxWidth: maxWidth ?? pageWidth);
    return painter;
  }

  Size paintText(
    String text,
    TextStyle textStyle,
    Offset offset, {
    double? maxWidth,
    TextAlign textAlign = TextAlign.left,
    int? maxLines,
  }) {
    final painter = layoutText(
      text,
      textStyle,
      maxWidth: maxWidth,
      textAlign: textAlign,
      maxLines: maxLines,
    );

    final dx = switch (textAlign) {
      TextAlign.right || TextAlign.end => offset.dx - painter.width,
      TextAlign.center => offset.dx - (painter.width / 2),
      _ => offset.dx,
    };

    painter.paint(canvas, Offset(dx, offset.dy));
    return painter.size;
  }

  void drawDashedLine({
    required Offset start,
    required double width,
    required Color color,
    double dashWidth = 10,
    double gapWidth = 7,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    var currentX = start.dx;
    final endX = start.dx + width;
    while (currentX < endX) {
      final nextX = math.min(currentX + dashWidth, endX);
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(nextX, start.dy),
        paint,
      );
      currentX = nextX + gapWidth;
    }
  }

  final orgLaoStyle = style(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textColor,
    height: 1.15,
  );
  final orgEnStyle = style(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: mutedColor,
    height: 1.1,
  );
  final smallLabelStyle = style(fontSize: 12, color: mutedColor);
  final dateStyle = style(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textColor,
    height: 1.2,
  );
  final titleStyle = style(
    fontSize: 38,
    fontWeight: FontWeight.w800,
    color: textColor,
  );
  final infoLabelStyle = style(fontSize: 13, color: mutedColor, height: 1.2);
  final infoValueStyle = style(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textColor,
    height: 1.2,
  );
  final tableHeaderStyle = style(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: mutedColor,
  );
  final tableCellStyle = style(fontSize: 15, color: textColor, height: 1.25);
  final summaryLabelStyle = style(fontSize: 15, color: mutedColor, height: 1.2);
  final summaryValueStyle = style(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textColor,
  );
  final amountDueLabelStyle = style(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: textColor,
  );
  final amountDueValueStyle = style(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: textColor,
  );
  final footerLaoStyle = style(fontSize: 14, color: mutedColor, height: 1.15);
  final footerEnStyle = style(fontSize: 12, color: mutedColor, height: 1.1);

  var y = topPadding;

  paintText(
    'ສູນປາລີ ບຳລຸງນັກຮຽນເກັ່ງ',
    orgLaoStyle,
    Offset(horizontalPadding, y),
  );
  y += 46;
  paintText(
    'Palee Elite Training Center',
    orgEnStyle,
    Offset(horizontalPadding, y),
  );

  final headerRuleY = topPadding + 92;
  drawRule(
    start: Offset(0, headerRuleY),
    end: Offset(pageWidth, headerRuleY),
    color: borderColor,
    strokeWidth: 1.5,
  );

  paintText(
    'ວັນທີ',
    smallLabelStyle,
    Offset(pageWidth - horizontalPadding, topPadding),
    textAlign: TextAlign.right,
  );
  paintText(
    fmtDate(registrationDate),
    dateStyle,
    Offset(pageWidth - horizontalPadding, topPadding + 24),
    textAlign: TextAlign.right,
  );

  paintText(
    'ໃບລົງທະບຽນ',
    titleStyle,
    Offset(pageWidth / 2, headerRuleY + 92),
    textAlign: TextAlign.center,
  );

  var infoY = headerRuleY + 182;
  final infoLabelWidth = 228.0;
  final infoColumnGap = 8.0;
  final infoValueX = horizontalPadding + infoLabelWidth + infoColumnGap;
  final infoValueWidth = pageWidth - infoValueX - horizontalPadding;

  final registrationLabelPainter = layoutText(
    'ລະຫັດໃບລົງທະບຽນ:',
    infoLabelStyle,
    maxWidth: infoLabelWidth,
    maxLines: 1,
  );
  final registrationValuePainter = layoutText(
    registrationId,
    infoValueStyle,
    maxWidth: infoValueWidth,
    maxLines: 1,
  );
  registrationLabelPainter.paint(canvas, Offset(horizontalPadding, infoY));
  registrationValuePainter.paint(canvas, Offset(infoValueX, infoY));

  infoY +=
      math.max(
        registrationLabelPainter.height,
        registrationValuePainter.height,
      ) +
      14;

  final studentLabelPainter = layoutText(
    'ຊື່ ແລະ ນາມສະກຸນ:',
    infoLabelStyle,
    maxWidth: infoLabelWidth,
    maxLines: 1,
  );
  final studentValuePainter = layoutText(
    studentName,
    infoValueStyle,
    maxWidth: infoValueWidth,
    maxLines: 2,
  );
  studentLabelPainter.paint(canvas, Offset(horizontalPadding, infoY));
  studentValuePainter.paint(canvas, Offset(infoValueX, infoY));

  var tableY =
      infoY +
      math.max(studentLabelPainter.height, studentValuePainter.height) +
      44;

  drawRule(
    start: Offset(0, tableY - 34),
    end: Offset(pageWidth, tableY - 34),
    color: borderColor,
    strokeWidth: 1.3,
  );

  final tableLeft = horizontalPadding;
  final tableRight = pageWidth - horizontalPadding;
  final tableWidth = tableRight - tableLeft;
  final subjectWidth = tableWidth * 0.46;
  final levelWidth = tableWidth * 0.18;
  final amountWidth = tableWidth - subjectWidth - levelWidth;

  paintText('ລາຍວິຊາ', tableHeaderStyle, Offset(tableLeft, tableY));
  paintText(
    'ຊັ້ນຮຽນ/ລະດັບ',
    tableHeaderStyle,
    Offset(tableLeft + subjectWidth + (levelWidth / 2), tableY),
    textAlign: TextAlign.center,
    maxWidth: levelWidth,
  );
  paintText(
    'ຄ່າຮຽນ',
    tableHeaderStyle,
    Offset(tableRight, tableY),
    textAlign: TextAlign.right,
    maxWidth: amountWidth,
  );

  tableY += 34;
  drawRule(
    start: Offset(tableLeft, tableY),
    end: Offset(tableRight, tableY),
    color: borderColor,
    strokeWidth: 1.5,
  );

  tableY += blockGap;
  for (final fee in selectedFees) {
    final subjectPainter = layoutText(
      fee.subjectName,
      tableCellStyle,
      maxWidth: subjectWidth - 12,
    );
    final levelPainter = layoutText(
      fee.levelName,
      tableCellStyle,
      maxWidth: levelWidth - 12,
      textAlign: TextAlign.center,
    );
    final amountPainter = layoutText(
      '${fmt(fee.fee.toInt())} ກີບ',
      tableCellStyle,
      maxWidth: amountWidth - 12,
      textAlign: TextAlign.right,
    );

    final rowHeight = math.max(
      36.0,
      math.max(
            subjectPainter.height,
            math.max(levelPainter.height, amountPainter.height),
          ) +
          22,
    );

    subjectPainter.paint(canvas, Offset(tableLeft, tableY));
    levelPainter.paint(
      canvas,
      Offset(
        tableLeft + subjectWidth + ((levelWidth - levelPainter.width) / 2),
        tableY,
      ),
    );
    amountPainter.paint(
      canvas,
      Offset(tableRight - amountPainter.width, tableY),
    );

    tableY += rowHeight;
    drawRule(
      start: Offset(tableLeft, tableY),
      end: Offset(tableRight, tableY),
      color: borderColor,
      strokeWidth: 1.2,
    );
    tableY += 18;
  }

  var summaryY = tableY + 56;
  final summaryRight = tableRight;
  final summaryValueWidth = 220.0;
  final summaryGap = 26.0;
  final summaryLabelRight = summaryRight - summaryValueWidth - summaryGap;

  paintText(
    'ລວມທັງໝົດ:',
    summaryLabelStyle,
    Offset(summaryLabelRight, summaryY),
    textAlign: TextAlign.right,
    maxWidth: 240,
  );
  paintText(
    '${fmt(totalFee)} ກີບ',
    summaryValueStyle,
    Offset(summaryRight, summaryY),
    textAlign: TextAlign.right,
    maxWidth: summaryValueWidth,
  );

  summaryY += 42;
  if (discountAmount > 0) {
    paintText(
      'ສ່ວນຫຼຸດ:',
      style(fontSize: 15, color: successColor),
      Offset(summaryLabelRight, summaryY),
      textAlign: TextAlign.right,
      maxWidth: 240,
    );
    paintText(
      '- ${fmt(discountAmount)} ກີບ',
      style(fontSize: 15, color: successColor, fontWeight: FontWeight.w600),
      Offset(summaryRight, summaryY),
      textAlign: TextAlign.right,
      maxWidth: summaryValueWidth,
    );
    summaryY += 40;
  } else {
    summaryY += 8;
  }

  drawDashedLine(
    start: Offset(summaryRight - 320, summaryY),
    width: 320,
    color: strongBorderColor,
    dashWidth: 9,
    gapWidth: 5,
  );

  summaryY += 26;
  paintText(
    'ຕ້ອງຈ່າຍ:',
    amountDueLabelStyle,
    Offset(summaryLabelRight, summaryY),
    textAlign: TextAlign.right,
    maxWidth: 260,
  );
  paintText(
    '${fmt(netFee)} ກີບ',
    amountDueValueStyle,
    Offset(summaryRight, summaryY - 6),
    textAlign: TextAlign.right,
    maxWidth: summaryValueWidth,
  );

  final footerLineY = math.min(summaryY + 108, pageHeight - 170);
  drawDashedLine(
    start: Offset(horizontalPadding, footerLineY),
    width: pageWidth - (horizontalPadding * 2),
    color: borderColor,
    dashWidth: 7,
    gapWidth: 4,
  );
  canvas.drawCircle(
    Offset(horizontalPadding, footerLineY),
    14,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill,
  );
  canvas.drawCircle(
    Offset(horizontalPadding, footerLineY),
    14,
    Paint()
      ..color = strongBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );
  canvas.drawCircle(
    Offset(pageWidth - horizontalPadding, footerLineY),
    14,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill,
  );
  canvas.drawCircle(
    Offset(pageWidth - horizontalPadding, footerLineY),
    14,
    Paint()
      ..color = strongBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );
  paintText(
    'ຂໍໃຫ້ທ່ານ ຈົ່ງໂຊກດີ',
    footerLaoStyle,
    Offset(horizontalPadding, footerLineY + 48),
    maxWidth: 380,
  );
  paintText(
    'Good luck with your studies!',
    footerEnStyle,
    Offset(horizontalPadding, footerLineY + 78),
    maxWidth: 420,
  );
  paintText(
    '#$registrationId',
    footerEnStyle,
    Offset(pageWidth - horizontalPadding, footerLineY + 62),
    textAlign: TextAlign.right,
    maxWidth: 180,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(pageWidth.toInt(), pageHeight.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Unable to encode receipt image.');
  }

  return byteData.buffer.asUint8List();
}
