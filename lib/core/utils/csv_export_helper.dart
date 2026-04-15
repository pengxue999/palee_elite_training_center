import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class CsvExportHelper {
  static Future<void> exportToCsv({
    required List<String> headers,
    required List<Map<String, dynamic>> data,
    required String filename,
    Map<String, String>? columnMapping,
  }) async {
    final headerRow = headers.join(',');

    final rows = data.map((row) {
      return headers.map((header) {
        final key = columnMapping?[header] ?? header;
        final value = row[key]?.toString() ?? '';
        if (value.contains(',') || value.contains('\n') || value.contains('"')) {
          return '"${value.replaceAll('"', '""')}"';
        }
        return value;
      }).join(',');
    }).toList();

    final csvContent = [headerRow, ...rows].join('\n');

    final bytes = utf8.encode(csvContent);
    final bom = [0xEF, 0xBB, 0xBF];
    final bytesWithBom = [...bom, ...bytes];

    await _downloadFile(bytesWithBom, filename);
  }

  static Future<void> _downloadFile(List<int> bytes, String filename) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      try {
        final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(bytes);
        print('CSV file saved to: ${file.path}');
      } catch (e) {
        print('Error saving CSV file: $e');
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$filename');
          await file.writeAsBytes(bytes);
          print('CSV file saved to: ${file.path}');
        } catch (e) {
          print('Error saving CSV file to documents: $e');
        }
      }
    }
  }

  static String formatNumber(num value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}
