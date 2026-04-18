import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'update_download.dart';
import 'update_models.dart';

class UpdateService {
  UpdateService._();

  static const String versionUrl = String.fromEnvironment(
    'UPDATE_VERSION_URL',
    defaultValue:
        'https://raw.githubusercontent.com/pengxue999/palee_elite_training_center/main/version.json',
  );

  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return _normalizeVersion(packageInfo.version);
  }

  static Future<UpdateInfo?> checkForUpdate() async {
    final client = http.Client();

    try {
      final response = await client
          .get(Uri.parse(versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw StateError('Version endpoint returned ${response.statusCode}.');
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid update metadata.');
      }

      final updateInfo = UpdateInfo.fromJson(decoded);
      if (updateInfo.version.isEmpty) {
        return null;
      }

      final currentVersion = await getCurrentVersion();

      if (_isNewerVersion(updateInfo.version, currentVersion)) {
        return updateInfo;
      }

      return null;
    } finally {
      client.close();
    }
  }

  static Future<void> downloadAndInstall(
    UpdateInfo info,
    void Function(double progress) onProgress,
  ) {
    return downloadAndInstallUpdate(info, onProgress);
  }

  static bool _isNewerVersion(String latest, String current) {
    final latestParts = _parseVersion(latest);
    final currentParts = _parseVersion(current);
    final maxLength = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;

    for (var index = 0; index < maxLength; index++) {
      final latestPart = index < latestParts.length ? latestParts[index] : 0;
      final currentPart = index < currentParts.length ? currentParts[index] : 0;

      if (latestPart > currentPart) {
        return true;
      }

      if (latestPart < currentPart) {
        return false;
      }
    }

    return false;
  }

  static List<int> _parseVersion(String version) {
    return _normalizeVersion(version)
        .split('.')
        .where((part) => part.isNotEmpty)
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }

  static String _normalizeVersion(String version) {
    final normalized = version.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final match = RegExp(r'\d+(?:\.\d+)*').firstMatch(normalized);
    return match?.group(0) ?? normalized;
  }
}
