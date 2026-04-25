import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/constants/constant.dart';
import 'package:palee_elite_training_center/core/utils/network_status.dart';

import 'app_button.dart';

enum _StartupConnectionStatus { checking, offline, online }

class StartupConnectionGuard extends StatefulWidget {
  const StartupConnectionGuard({super.key, required this.child});

  final Widget child;

  @override
  State<StartupConnectionGuard> createState() => _StartupConnectionGuardState();
}

class _StartupConnectionGuardState extends State<StartupConnectionGuard> {
  _StartupConnectionStatus _status = _StartupConnectionStatus.checking;

  @override
  void initState() {
    super.initState();
    NetworkStatusController.status.addListener(_handleNetworkStatusChanged);
    unawaited(_runStartupCheck());
  }

  @override
  void dispose() {
    NetworkStatusController.status.removeListener(_handleNetworkStatusChanged);
    super.dispose();
  }

  void _handleNetworkStatusChanged() {
    if (!mounted) return;

    final nextStatus =
        NetworkStatusController.status.value == NetworkStatus.offline
        ? _StartupConnectionStatus.offline
        : _StartupConnectionStatus.online;

    if (_status == nextStatus) return;

    setState(() {
      _status = nextStatus;
    });
  }

  Future<void> _runStartupCheck() async {
    final isConnected = await _canReachBackend();
    if (!mounted) return;

    setState(() {
      _status = isConnected
          ? _StartupConnectionStatus.online
          : _StartupConnectionStatus.offline;
    });

    if (isConnected) {
      NetworkStatusController.markOnline();
    } else {
      NetworkStatusController.markOffline();
    }
  }

  Future<bool> _canReachBackend() async {
    final client = http.Client();

    try {
      final response = await client
          .get(
            Uri.parse(AppConstants.baseUrl),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode >= 100 && response.statusCode < 600;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _StartupConnectionStatus.checking:
      case _StartupConnectionStatus.online:
        return widget.child;
      case _StartupConnectionStatus.offline:
        return _StartupBlockingView(
          title: 'ຍັງບໍ່ມີການເຊື່ອມຕໍ່ອິນເຕີເນັດ',
          message:
              'ກະລຸນາເຊື່ອມຕໍ່ອິນເຕີເນັດ ຫຼື ກວດສອບການເຂົ້າເຖິງ server ກ່ອນ.',
          icon: Icons.wifi_off_rounded,
          iconColor: AppColors.warning,
          action: AppButton(
            label: 'ລອງໃໝ່',
            variant: AppButtonVariant.primary,
            isFullWidth: true,
            onPressed: () {
              setState(() {
                _status = _StartupConnectionStatus.checking;
              });
              unawaited(_runStartupCheck());
            },
          ),
        );
    }
  }
}

class _StartupBlockingView extends StatelessWidget {
  const _StartupBlockingView({
    required this.title,
    required this.message,
    this.icon = Icons.cloud_off_rounded,
    this.iconColor = AppColors.primary,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0F1C3F),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _BackdropOrb(
              size: 400,
              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: -160,
            left: -100,
            child: _BackdropOrb(
              size: 500,
              color: const Color(0xFF0891B2).withValues(alpha: 0.09),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 32, color: iconColor),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                        fontFamily: 'NotoSansLao',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                        height: 1.5,
                        fontFamily: 'NotoSansLao',
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 24),
                      action!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
