import 'package:flutter/material.dart';

import '../services/update_models.dart';
import '../services/update_service.dart';

class UpdateSettingsDialog extends StatefulWidget {
  const UpdateSettingsDialog({super.key});

  @override
  State<UpdateSettingsDialog> createState() => _UpdateSettingsDialogState();
}

class _UpdateSettingsDialogState extends State<UpdateSettingsDialog> {
  String? _currentVersion;
  UpdateInfo? _availableUpdate;
  String? _statusMessage;
  bool _isLoadingVersion = true;
  bool _isChecking = false;
  bool _isInstalling = false;
  double? _progress;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final version = await UpdateService.getCurrentVersion();
      if (!mounted) {
        return;
      }

      setState(() {
        _currentVersion = version;
        _isLoadingVersion = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentVersion = 'Unknown';
        _isLoadingVersion = false;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _availableUpdate = null;
      _statusMessage = null;
      _progress = null;
    });

    try {
      final updateInfo = await UpdateService.checkForUpdate();
      if (!mounted) {
        return;
      }

      setState(() {
        _availableUpdate = updateInfo;
        _statusMessage = updateInfo == null
            ? 'ແອັບຂອງທ່ານເປັນເວີຊັນລ່າສຸດແລ້ວ'
            : 'ພົບເວີຊັນໃໝ່ ${updateInfo.version}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'ກວດສອບອັບເດດບໍ່ສຳເລັດ: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _installUpdate() async {
    final info = _availableUpdate;
    if (info == null || !info.hasDownloadUrl) {
      setState(() {
        _statusMessage = 'ບໍ່ພົບລິ້ງດາວໂຫຼດສຳລັບ release ນີ້';
      });
      return;
    }

    setState(() {
      _isInstalling = true;
      _statusMessage =
          'ກຳລັງດາວໂຫຼດ installer... ຫຼັງຈາກນີ້ app ຈະປິດ ແລະ Windows ຈະເປີດໜ້າຕິດຕັ້ງໃຫ້.';
      _progress = 0;
    });

    try {
      await UpdateService.downloadAndInstall(info, (progress) {
        if (!mounted) {
          return;
        }

        setState(() {
          _progress = progress;
        });
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInstalling = false;
        _statusMessage = 'ຕິດຕັ້ງອັບເດດບໍ່ສຳເລັດ: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ອັບເດດລະບົບ'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVersionRow(),
            const SizedBox(height: 16),
            Text(
              'ທ່ານສາມາດເພື່ອກວດສອບເວີຊັນ ແລະ ອັບເດດໃໝ່.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_statusMessage != null) _buildStatusBanner(context),
            if (_availableUpdate != null) ...[
              const SizedBox(height: 16),
              _buildUpdateCard(context, _availableUpdate!),
            ],
            if (_progress != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text('${(_progress! * 100).toStringAsFixed(0)}%'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isInstalling ? null : () => Navigator.of(context).pop(),
          child: const Text('ປິດ'),
        ),
        OutlinedButton.icon(
          onPressed: _isChecking || _isInstalling ? null : _checkForUpdates,
          icon: _isChecking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
          label: Text(_isChecking ? 'ກຳລັງກວດສອບ...' : 'ກວດສອບ'),
        ),
        FilledButton.icon(
          onPressed: _isInstalling || _availableUpdate == null
              ? null
              : _installUpdate,
          icon: _isInstalling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.system_update_alt_rounded),
          label: Text(_isInstalling ? 'ກຳລັງດາວໂຫຼດ...' : 'ອັບເດດດຽວນີ້'),
        ),
      ],
    );
  }

  Widget _buildVersionRow() {
    if (_isLoadingVersion) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('ກຳລັງອ່ານເວີຊັນປັດຈຸບັນ...'),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.verified_outlined, size: 18),
        const SizedBox(width: 8),
        Text('ເວີຊັນປັດຈຸບັນ: ${_currentVersion ?? 'Unknown'}'),
      ],
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    final hasUpdate = _availableUpdate != null;
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = hasUpdate
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final textColor = hasUpdate
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusMessage!,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildUpdateCard(BuildContext context, UpdateInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ເວີຊັນ ${info.version}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            info.releaseNotes.isEmpty
                ? 'ບໍ່ມີ release notes ສຳລັບ version ນີ້'
                : info.releaseNotes,
          ),
          const SizedBox(height: 12),
          Text(
            info.hasDownloadUrl
                ? info.downloadUrl
                : 'Release ນີ້ຍັງບໍ່ມີ installer URL',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Text(
            'ເມື່ອກົດອັບເດດ ແອັບຈະປິດ ແລະ installer ຈະເປີດຂຶ້ນ. ຖ້າ Windows ຖາມສິດ admin ໃຫ້ກົດອະນຸຍາດ.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
