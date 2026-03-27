import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskmanager/screens/task_detail_screen.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helper.dart';

/// A card widget that displays a summary of a [Task].
///
/// Supported interactions:
/// - Tap: Navigates to the task details screen.
/// - Swipe Right: Toggles the task's completion status.
/// - Swipe Left: Deletes the task (with confirmation).
class TaskCard extends StatelessWidget {
  /// The task data to display.
  final Task task;

  const TaskCard({super.key, required this.task});

  /// Calculates the background color for the card based on the task's [colorIndex].
  Color _cardColor(BuildContext context) {
    return Color(
      AppColors.cardPalette[task.colorIndex % AppColors.cardPalette.length],
    );
  }

  /// Calculates a darker accent color for the left duration bar.
  Color _barColor(BuildContext context) {
    final base = _cardColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness(isDark ? 0.46 : 0.50)
        .withSaturation(0.68)
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(task.id),
      background: _swipeBg(isComplete: true),
      secondaryBackground: _swipeBg(isComplete: false),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          // Toggle completion status on right swipe.
          context.read<TaskProvider>().toggleComplete(task.id);
          return false; // Don't dismiss the widget.
        }
        // Show confirmation dialog before deleting on left swipe.
        return await _confirmDelete(context);
      },
      onDismissed: (dir) {
        if (dir == DismissDirection.endToStart) {
          context.read<TaskProvider>().deleteTask(task.id);
        }
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _cardColor(context),
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _durationBar(context, task),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.lightPrimary,
                                      fontSize: 15,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: AppColors.lightPrimary,
                                      decorationThickness: 2,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status chips for Done or Overdue states.
                            if (task.isCompleted)
                              _chip('Done', _barColor(context))
                            else if (task.isOverdue)
                              _chip('Overdue', AppColors.danger),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            task.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the stylized left bar displaying task dates.
  Widget _durationBar(BuildContext context, Task task) {
    final barColor = _barColor(context);
    final sameDay = task.isSingleDay;

    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(AppSizes.radiusCard),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.spacingL - 2,
          horizontal: AppSizes.spacingS,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _barDate(
              DateHelper.formatDay(task.startDate),
              DateHelper.formatMonth(task.startDate),
            ),
            if (!sameDay) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Container(width: 16, height: 1.5, color: Colors.white30),
              ),
              _barDate(
                DateHelper.formatDay(task.endDate),
                DateHelper.formatMonth(task.endDate),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Internal helper to format dates for the duration bar.
  Widget _barDate(String day, String month) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: day,
            style: const TextStyle(
              fontSize: AppSizes.fontBody - 1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: month.toUpperCase(),
            style: const TextStyle(
              fontSize: AppSizes.fontLabel - 1,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Builds a small status chip with the given [label] and [color].
  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  /// Builds the background UI shown when swiping the card.
  Widget _swipeBg({required bool isComplete}) {
    return Container(
      decoration: BoxDecoration(
        color: isComplete ? AppColors.success : AppColors.danger,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      alignment: isComplete ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingXXL),
      child: Icon(
        isComplete ? Icons.check_rounded : Icons.delete_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  /// Shows a confirmation dialog when the user attempts to delete a task.
  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        title: const Text('Delete Task?'),
        content: Text('Delete "${task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
