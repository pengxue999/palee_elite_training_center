import 'update_models.dart';
import 'update_download_stub.dart'
    if (dart.library.io) 'update_download_io.dart'
    as implementation;

Future<void> downloadAndInstallUpdate(
  UpdateInfo info,
  void Function(double progress) onProgress,
) {
  return implementation.downloadAndInstallUpdate(info, onProgress);
}
