import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// A reusable tile for picking dates, with a consistent icon and layout.
class AppDateTile extends StatelessWidget {
  final String label;
  final String dateText;
  final VoidCallback onTap;

  const AppDateTile({
    super.key,
    required this.label,
    required this.dateText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacingM + 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusButton),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSizes.spacingS),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: AppSizes.iconS,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSizes.spacingXS + 2),
                Text(dateText, style: theme.textTheme.titleMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
