import 'update_models.dart';

Future<void> downloadAndInstallUpdate(
  UpdateInfo info,
  void Function(double progress) onProgress,
) async {
  throw UnsupportedError(
    'Auto update is only available on the Windows desktop build.',
  );
}
