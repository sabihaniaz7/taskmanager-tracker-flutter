import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// A stylized row for displaying information labels and values with an icon.
class AppInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? barColor;
  final Color? valueColor;

  const AppInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.barColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBarColor = barColor ?? theme.colorScheme.primary;
    final subtextColor = AppColors.infoLabelColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: effectiveBarColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: effectiveBarColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontCaption,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.fontCaption,
              fontWeight: FontWeight.w700,
              color: valueColor ?? theme.textTheme.titleMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
