import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({super.key, required this.status, this.padding});

  @override
  Widget build(BuildContext context) {
    final colorTuple = AppColors.statusBackgroundColors[status];
    final bgColor = colorTuple?.$1 ?? AppColors.warning;
    final textColor = colorTuple?.$2 ?? AppColors.primaryLight;

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
