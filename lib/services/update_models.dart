class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  final String version;
  final String downloadUrl;
  final String releaseNotes;

  bool get hasDownloadUrl => downloadUrl.trim().isNotEmpty;

  String get installerFileName {
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null || uri.pathSegments.isEmpty) {
      return 'PaleeEliteTrainingCenter-Setup.exe';
    }

    return uri.pathSegments.last;
  }

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: (json['version'] ?? '').toString().trim(),
      downloadUrl: (json['url'] ?? json['downloadUrl'] ?? '').toString(),
      releaseNotes: (json['notes'] ?? json['releaseNotes'] ?? '').toString(),
    );
  }
}
