import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_isInstalling,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                  blurRadius: 42,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FBFF), Color(0xFFEEF4FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isInstalling
                              ? Icons.downloading_rounded
                              : Icons.system_update_alt_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isInstalling
                                  ? 'ກຳລັງດາວໂຫຼດອັບເດດ'
                                  : 'ອັບເດດລະບົບ',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isInstalling
                                  ? 'ລໍຖ້າຈົນການດາວໂຫຼດສຳເລັດ ແລ້ວລະບົບຈະເປີດ installer ໃຫ້ອັດຕະໂນມັດ.'
                                  : 'ກວດສອບເວີຊັນປັດຈຸບັນ ແລະ ອັບເດດເວີຊັນໃໝ່ໄດ້ຈາກບ່ອນນີ້.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.mutedForeground,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildVersionRow(),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _isInstalling
                              ? _buildDownloadingPanel(context)
                              : _buildIdlePanel(context),
                        ),
                        if (_statusMessage != null) ...[
                          const SizedBox(height: 18),
                          _buildStatusBanner(context),
                        ],
                        if (_availableUpdate != null && !_isInstalling) ...[
                          const SizedBox(height: 18),
                          _buildUpdateCard(context, _availableUpdate!),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFDFF),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    runSpacing: 12,
                    spacing: 12,
                    children: [
                      TextButton(
                        onPressed: _isInstalling
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.mutedForeground,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                        child: Text(_isInstalling ? 'ກຳລັງດາວໂຫຼດ...' : 'ປິດ'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isChecking || _isInstalling
                            ? null
                            : _checkForUpdates,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.9),
                          ),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isChecking
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(_isChecking ? 'ກຳລັງກວດສອບ...' : 'ກວດສອບ'),
                      ),
                      FilledButton.icon(
                        onPressed: _isInstalling || _availableUpdate == null
                            ? null
                            : _installUpdate,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          disabledForegroundColor: const Color(0xFF94A3B8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isInstalling
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.system_update_alt_rounded),
                        label: Text(
                          _isInstalling ? 'ກຳລັງດາວໂຫຼດ...' : 'ອັບເດດດຽວນີ້',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionRow() {
    if (_isLoadingVersion) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('ກຳລັງອ່ານເວີຊັນປັດຈຸບັນ...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ເວີຊັນປັດຈຸບັນ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentVersion ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdlePanel(BuildContext context) {
    return Container(
      key: const ValueKey('idle-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ກວດສອບອັບເດດກ່ອນເພື່ອເບິ່ງວ່າມີເວີຊັນໃໝ່ພ້ອມໃຫ້ດາວໂຫຼດຫຼືບໍ່.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.foreground,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _InfoChip(
                icon: Icons.flash_on_rounded,
                label: 'ກວດສອບໄວ',
                tone: _InfoChipTone.info,
              ),
              _InfoChip(
                icon: Icons.security_rounded,
                label: 'ປອດໄພ',
                tone: _InfoChipTone.success,
              ),
              _InfoChip(
                icon: Icons.install_desktop_rounded,
                label: 'Installer ອັດຕະໂນມັດ',
                tone: _InfoChipTone.neutral,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingPanel(BuildContext context) {
    final rawProgress = _progress;
    final normalizedProgress = rawProgress?.clamp(0.0, 1.0);
    final percentLabel = normalizedProgress == null
        ? 'Preparing'
        : '${(normalizedProgress * 100).toStringAsFixed(0)}%';

    return Container(
      key: const ValueKey('downloading-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProgressRing(progress: normalizedProgress),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ກຳລັງດາວໂຫຼດໄຟລ໌ຕິດຕັ້ງ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _availableUpdate?.installerFileName ??
                          'PaleeEliteTrainingCenter-Setup.exe',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DownloadStageChip(
                          label: 'ກຽມ',
                          isActive: true,
                          isComplete:
                              normalizedProgress != null &&
                              normalizedProgress > 0,
                        ),
                        _DownloadStageChip(
                          label: 'ດາວໂຫຼດ',
                          isActive: true,
                          isComplete:
                              normalizedProgress != null &&
                              normalizedProgress >= 1,
                        ),
                        _DownloadStageChip(
                          label: 'ເປີດ installer',
                          isActive:
                              normalizedProgress != null &&
                              normalizedProgress >= 0.95,
                          isComplete: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalizedProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF93C5FD),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'ສະຖານະ: $percentLabel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'ຫ້າມປິດໜ້ານີ້ລະຫວ່າງດາວໂຫຼດ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = _statusMessage ?? '';
    final isError = message.contains('ບໍ່ສຳເລັດ') || message.contains('error');
    final isInstalling = _isInstalling;
    final hasUpdate = _availableUpdate != null;

    final backgroundColor = isError
        ? AppColors.destructiveLight
        : isInstalling
        ? const Color(0xFFE0F2FE)
        : hasUpdate
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final textColor = isError
        ? AppColors.destructive
        : isInstalling
        ? const Color(0xFF0369A1)
        : hasUpdate
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    final icon = isError
        ? Icons.error_outline_rounded
        : isInstalling
        ? Icons.downloading_rounded
        : hasUpdate
        ? Icons.new_releases_rounded
        : Icons.info_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(BuildContext context, UpdateInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'New release',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'v${info.version}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            info.releaseNotes.isEmpty
                ? 'ບໍ່ມີ release notes ສຳລັບ version ນີ້'
                : info.releaseNotes,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final label = progress == null
        ? '...'
        : '${(progress! * 100).toStringAsFixed(0)}%';

    return SizedBox(
      width: 94,
      height: 94,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 94,
            height: 94,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFBFDBFE),
              ),
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadStageChip extends StatelessWidget {
  const _DownloadStageChip({
    required this.label,
    required this.isActive,
    required this.isComplete,
  });

  final String label;
  final bool isActive;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isComplete
        ? Colors.white
        : isActive
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.08);
    final foregroundColor = isComplete
        ? const Color(0xFF1D4ED8)
        : Colors.white.withValues(alpha: isActive ? 0.96 : 0.68);
    final icon = isComplete ? Icons.check_rounded : Icons.more_horiz_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

enum _InfoChipTone { info, success, neutral }

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final _InfoChipTone tone;

  @override
  Widget build(BuildContext context) {
    late final Color backgroundColor;
    late final Color foregroundColor;

    switch (tone) {
      case _InfoChipTone.info:
        backgroundColor = AppColors.infoLight;
        foregroundColor = AppColors.primary;
      case _InfoChipTone.success:
        backgroundColor = AppColors.successLight;
        foregroundColor = AppColors.success;
      case _InfoChipTone.neutral:
        backgroundColor = const Color(0xFFF1F5F9);
        foregroundColor = const Color(0xFF334155);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
