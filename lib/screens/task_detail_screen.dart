import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskmanager/widgets/app_header.dart';
import 'package:taskmanager/widgets/app_info_row.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helper.dart';
import 'edit_task_screen.dart';

/// A screen that displays comprehensive details for a specific [Task].
///
/// Features:
/// - Visual progress tracking for multi-day tasks.
/// - Descriptive status indicators (e.g., "Overdue", "Due Today").
/// - Toggle for task completion.
/// - Quick access to editing and deletion.
class TaskDetailScreen extends StatelessWidget {
  /// The task to display.
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  /// Calculates a darker accent color for status indicators based on the task's palette.
  Color _barColor(BuildContext context, Task task) {
    final base = Color(
      AppColors.cardPalette[task.colorIndex % AppColors.cardPalette.length],
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness(isDark ? 0.46 : 0.50)
        .withSaturation(0.68)
        .toColor();
  }

  /// Returns a consistent subtext color for the current theme.
  Color _subtextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
  }

  /// Generates a human-friendly label describing the task's reminder settings.
  String _reminderModeLabel(Task task) {
    switch (task.reminderMode) {
      case ReminderMode.none:
        return 'No reminder';
      case ReminderMode.onDueDate:
        return 'At ${_fmtTime(task.reminderHour, task.reminderMinute)}';
      case ReminderMode.onceDayBefore:
        return '1 day before at ${_fmtTime(task.reminderHour, task.reminderMinute)}';
      case ReminderMode.daily:
        return 'Daily at ${_fmtTime(task.reminderHour, task.reminderMinute)}';
      case ReminderMode.customDays:
        return '${task.customDaysBefore} days before at ${_fmtTime(task.reminderHour, task.reminderMinute)}';
    }
  }

  /// Formats hours and minutes into a 12-hour string (e.g., "9:00 AM").
  String _fmtTime(int h, int m) {
    final period = h < 12 ? 'AM' : 'PM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    final min = m.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  /// Calculates the current status string (e.g., "Overdue by 2 days").
  String _daysStatus(Task task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(
      task.endDate.year,
      task.endDate.month,
      task.endDate.day,
    );
    final diff = end.difference(today).inDays;
    if (task.isCompleted) return 'Completed ✓';
    if (diff < 0) return 'Overdue by ${-diff} day${-diff == 1 ? '' : 's'}';
    if (diff == 0) return 'Due today';
    return '$diff day${diff == 1 ? '' : 's'} remaining';
  }

  /// Calculates the progress ratio (0.0 to 1.0) based on start and end dates.
  double _progressValue(Task task) {
    if (task.isSingleDay) return task.isCompleted ? 1.0 : 0.0;
    final now = DateTime.now();
    final start = task.startDate;
    final end = task.endDate;
    final total = end.difference(start).inDays;
    if (total <= 0) return task.isCompleted ? 1.0 : 0.0;
    final elapsed = now.difference(start).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (_, provider, _) {
        // Retrieve fresh data from the provider to react to toggles/edits.
        final t = provider.allTasks.firstWhere(
          (e) => e.id == task.id,
          orElse: () => task,
        );
        return _buildScreen(context, t, provider);
      },
    );
  }

  /// Main screen builder with customized theme tokens.
  Widget _buildScreen(BuildContext context, Task t, TaskProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final barColor = _barColor(context, t);
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final progress = _progressValue(t);
    final statusText = _daysStatus(t);
    final isOverdue = t.isOverdue;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            AppHeader(
              title: t.title,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _editButton(context, t, theme, surface),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Completion Toggle Card
                    _completionCard(
                      context,
                      t,
                      provider,
                      barColor,
                      surface,
                      isDark,
                      theme,
                    ),

                    const SizedBox(height: 14),

                    // Progress Visualization (Multi-day tasks only)
                    if (!t.isSingleDay) ...[
                      _progressCard(
                        context,
                        t,
                        barColor,
                        surface,
                        isDark,
                        progress,
                        statusText,
                        isOverdue,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Detailed Info Card (Dates, Reminders, etc.)
                    _infoCard(
                      context,
                      t,
                      theme,
                      surface,
                      isDark,
                      barColor,
                      statusText,
                      isOverdue,
                    ),

                    // Notes Section
                    if (t.description.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _notesCard(context, t, theme, surface, isDark),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editButton(
    BuildContext context,
    Task t,
    ThemeData theme,
    Color surface,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditTaskScreen(task: t)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusButton),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_rounded,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 5),
            Text(
              'Edit',
              style: TextStyle(
                fontSize: AppSizes.fontCaption,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _completionCard(
    BuildContext context,
    Task t,
    TaskProvider provider,
    Color barColor,
    Color surface,
    bool isDark,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () => provider.toggleComplete(t.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: t.isCompleted
              ? barColor.withValues(alpha: isDark ? 0.18 : 0.12)
              : surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(
            color: t.isCompleted
                ? barColor.withValues(alpha: 0.45)
                : theme.dividerColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (t.isCompleted ? barColor : Colors.black).withValues(
                alpha: isDark ? 0.2 : 0.06,
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.isCompleted ? barColor : Colors.transparent,
                border: Border.all(
                  color: t.isCompleted
                      ? barColor
                      : _subtextColor(context).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                t.isCompleted
                    ? Icons.check_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: t.isCompleted ? Colors.white : _subtextColor(context),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.isCompleted ? 'Completed!' : 'Mark as Complete',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: t.isCompleted
                          ? barColor
                          : theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.isCompleted
                        ? 'Tap to mark as incomplete'
                        : 'Tap to complete this task',
                    style: TextStyle(
                      fontSize: AppSizes.fontCaption,
                      color: _subtextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressCard(
    BuildContext context,
    Task t,
    Color barColor,
    Color surface,
    bool isDark,
    double progress,
    String statusText,
    bool isOverdue,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: AppSizes.fontCaption,
                  fontWeight: FontWeight.w700,
                  color: _subtextColor(context),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isOverdue ? AppColors.danger : barColor).withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isOverdue ? AppColors.danger : barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: t.isCompleted ? 1.0 : progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverdue ? AppColors.danger : barColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    BuildContext context,
    Task t,
    ThemeData theme,
    Color surface,
    bool isDark,
    Color barColor,
    String statusText,
    bool isOverdue,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          AppInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Start Date',
            value: DateHelper.formatShort(t.startDate),
            barColor: theme.colorScheme.primary,
          ),
          const Divider(height: 1),
          AppInfoRow(
            icon: Icons.event_rounded,
            label: 'Due Date',
            value: DateHelper.formatShort(t.endDate),
            barColor: theme.colorScheme.primary,
          ),
          if (t.reminderMode != ReminderMode.none) ...[
            const Divider(height: 1),
            AppInfoRow(
              icon: Icons.notifications_rounded,
              label: 'Reminder',
              value: _reminderModeLabel(t),
              barColor: theme.colorScheme.primary,
            ),
          ],
          if (t.isSingleDay) ...[
            const Divider(height: 1),
            AppInfoRow(
              icon: Icons.flag_rounded,
              label: 'Status',
              value: statusText,
              barColor: isOverdue ? AppColors.danger : theme.colorScheme.primary,
              valueColor: isOverdue
                  ? AppColors.danger
                  : t.isCompleted
                      ? barColor
                      : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _notesCard(
    BuildContext context,
    Task t,
    ThemeData theme,
    Color surface,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _subtextColor(context),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
