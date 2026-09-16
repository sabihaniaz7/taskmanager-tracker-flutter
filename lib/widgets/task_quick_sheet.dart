import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helper.dart';
import '../screens/edit_task_screen.dart';

/// Returns true if [task] is simple enough to use the quick sheet instead
/// of the full [TaskDetailScreen] — single day, no notes, no reminder.
bool isQuickTask(Task task) {
  return task.isSingleDay &&
      task.description.isEmpty &&
      task.reminderMode == ReminderMode.none;
}

/// Shows a compact bottom sheet for a simple task: toggle complete, see the
/// date, edit or delete. Call this instead of pushing [TaskDetailScreen]
/// when [isQuickTask] returns true.
Future<void> showTaskQuickSheet(BuildContext context, Task task) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => TaskQuickSheet(task: task),
  );
}

class TaskQuickSheet extends StatelessWidget {
  final Task task;

  const TaskQuickSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (_, provider, _) {
        final t = provider.allTasks.firstWhere(
          (e) => e.id == task.id,
          orElse: () => task,
        );
        final accent = AppColors.accentFor(context, t.colorIndex).text;
        final surface = AppColors.cardSurface(context);

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.subtextColor(
                        context,
                      ).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 17,
                              decoration: t.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      color: accent,
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditTaskScreen(task: t),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateHelper.formatShort(t.startDate),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.subtextColor(context),
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => provider.toggleComplete(t.id),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: t.isCompleted
                          ? accent
                          : AppColors.accentFor(context, t.colorIndex).tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          t.isCompleted
                              ? Icons.check_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: t.isCompleted ? Colors.white : accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.isCompleted ? 'Completed' : 'Mark as complete',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: t.isCompleted ? Colors.white : accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
