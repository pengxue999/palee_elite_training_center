import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'update_models.dart';

Future<void> downloadAndInstallUpdate(
  UpdateInfo info,
  void Function(double progress) onProgress,
) async {
  if (!info.hasDownloadUrl) {
    throw StateError('Release metadata does not contain a download URL.');
  }

  final tempDir = await getTemporaryDirectory();
  final installerPath = '${tempDir.path}\\${info.installerFileName}';
  final installerFile = File(installerPath);
  final request = http.Request('GET', Uri.parse(info.downloadUrl));
  final streamedResponse = await request.send();

  if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
    throw HttpException(
      'Unable to download update (${streamedResponse.statusCode}).',
    );
  }

  final sink = installerFile.openWrite();
  final totalBytes = streamedResponse.contentLength ?? 0;
  var receivedBytes = 0;

  try {
    await for (final chunk in streamedResponse.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        onProgress(receivedBytes / totalBytes);
      }
    }
  } finally {
    await sink.flush();
    await sink.close();
  }

  final launcherScript = File('${tempDir.path}\\palee-update-launcher.bat');
  final escapedInstallerPath = installerFile.path.replaceAll('"', '""');
  final scriptContent = [
    '@echo off',
    'setlocal',
    'ping 127.0.0.1 -n 3 > nul',
    'powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '
        '$escapedInstallerPath'
        ' -ArgumentList '
        '/SP-'
        ' -Verb RunAs"',
    'exit /b 0',
  ].join('\r\n');

  await launcherScript.writeAsString(scriptContent, flush: true);
  await Process.start(
    'cmd',
    ['/c', launcherScript.path],
    mode: ProcessStartMode.detached,
    runInShell: true,
  );

  exit(0);
}
