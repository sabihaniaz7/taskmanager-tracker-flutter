import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// A reusable header/app bar component for screens.
/// 
/// Provides a consistent back button and title layout.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.brightness == Brightness.dark
        ? AppColors.darkSurface
        : AppColors.lightSurface;

    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
      ),
      leadingWidth: showBackButton ? 64 : null,
      leading: showBackButton
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Center(
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall + 2),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
