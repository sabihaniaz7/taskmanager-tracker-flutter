import 'package:flutter/material.dart';
import 'package:taskmanager/services/notification_service.dart';
import 'package:taskmanager/utils/app_theme.dart';

class NotificationPermissionHelper {
  static Future<bool> ensurePermission(
    BuildContext context, {
    required bool shouldRequest,
    required String message,
  }) async {
    // Always return true — saving should never be blocked by notification permission.
    // We just try to get permission silently in the background.
    if (!shouldRequest) return true;

    final notifService = NotificationService();
    if (notifService.permissionGranted) return true;

    final allow = await showRationale(context, message: message);
    if (allow != true) return true; // user skipped — still save
    if (!context.mounted) return true;

    final granted = await notifService.requestPermission();
    if (granted) return true;
    if (!context.mounted) return true;
    // Show settings prompt but don't block saving either way
    final openSettings = await showSettingsPrompt(context);
    if (openSettings == true) {
      await notifService.openNotificationSettings();
    }
    return true; // always let the save proceed
  }

  static Future<bool?> showRationale(
    BuildContext context, {
    required String message,
  }) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppSizes.spacingXL,
          AppSizes.spacingXL,
          AppSizes.spacingXL,
          0,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: theme.colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSizes.spacingL),
            Text(
              'Enable Reminders',
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingM),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingS),
          ],
        ),
        actionsPadding: const EdgeInsets.all(AppSizes.spacingL),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Skip',
              style: TextStyle(color: theme.textTheme.labelSmall?.color),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall + 2),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingXL,
                vertical: AppSizes.spacingM,
              ),
            ),
            child: Text(
              'Allow Notifications',
              style: TextStyle(
                color: theme.brightness == Brightness.dark
                    ? AppColors.darkBg
                    : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showSettingsPrompt(BuildContext context) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        title: Text(
          'Turn On Notifications',
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
        ),
        content: Text(
          'Android did not grant notification access. Open app settings and enable notifications, then save again.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
