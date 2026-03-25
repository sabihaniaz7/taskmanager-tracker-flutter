import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskmanager/providers/tracker_provider.dart';
import 'package:taskmanager/utils/app_theme.dart';
import 'package:taskmanager/widgets/app_button.dart';
import 'package:taskmanager/widgets/app_header.dart';
import 'package:taskmanager/widgets/app_label.dart';

/// A screen for creating a new [Tracker] (habit/goal).
///
/// Users can define a title, optional description, and configure
/// a recurring daily notification reminder for the habit.
class AddTrackerScreen extends StatefulWidget {
  const AddTrackerScreen({super.key});

  @override
  State<AddTrackerScreen> createState() => _AddTrackerScreenState();
}

class _AddTrackerScreenState extends State<AddTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Formats the [TimeOfDay] into a human-readable 12-hour format (e.g., "9:00 AM").
  String _formatTime(TimeOfDay time) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  /// Opens the system time picker to select a reminder time.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  /// Validates the form and saves the new tracker via [TrackerProvider].
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await context.read<TrackerProvider>().addEntry(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        reminderEnabled: _reminderEnabled,
        reminderHour: _reminderTime.hour,
        reminderMinute: _reminderTime.minute,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add goal. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppHeader(
        title: 'New Goal',
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        showBackButton: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.spacingXL),
          children: [
            const SizedBox(height: AppSizes.spacingS),
            const AppLabel('TITLE *'),
            const SizedBox(height: AppSizes.spacingXS),
            TextFormField(
              controller: _titleController,
              autofocus: false,
              style: theme.textTheme.titleMedium,
              textCapitalization: TextCapitalization.sentences,
              decoration: AppTheme.commonInputDecoration(
                context,
                'Drink water, Exercise...',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: AppSizes.spacingL),

            const AppLabel('DESCRIPTION'),
            const SizedBox(height: AppSizes.spacingS),
            TextFormField(
              controller: _descriptionController,
              style: theme.textTheme.bodyMedium,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: AppTheme.commonInputDecoration(
                context,
                'Optional Details...',
              ),
            ),
            const SizedBox(height: AppSizes.spacingL),

            // Reminder Configuration Section
            const AppLabel('DAILY REMINDER'),
            const SizedBox(height: AppSizes.spacingS),
            _reminderConfigCard(context, theme, isDark),

            const SizedBox(height: AppSizes.spacingXL),

            // Save Button
            AppButton(text: 'Save', isLoading: _isSaving, onPressed: _save),
          ],
        ),
      ),
    );
  }

  /// Builds the interactive card for enabling and configuring daily reminders.
  Widget _reminderConfigCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        border: Border.all(
          color: _reminderEnabled
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.dividerColor,
          width: _reminderEnabled ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingL,
              vertical: AppSizes.spacingM,
            ),
            child: Row(
              children: [
                _reminderIcon(theme),
                const SizedBox(width: AppSizes.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Reminder',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _reminderEnabled
                            ? 'Every day at ${_formatTime(_reminderTime)}'
                            : 'Tap to enable',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _reminderEnabled
                              ? theme.colorScheme.primary.withValues(alpha: 0.8)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() => _reminderEnabled = v),
                  activeThumbColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          if (_reminderEnabled) ...[
            Divider(height: 1, color: theme.dividerColor),
            GestureDetector(
              onTap: _pickTime,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingL,
                  vertical: AppSizes.spacingM,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSizes.spacingS),
                    Text(
                      _formatTime(_reminderTime),
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text('Tap to change', style: theme.textTheme.labelSmall),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: theme.textTheme.labelSmall?.color,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reminderIcon(ThemeData theme) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: _reminderEnabled
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.dividerColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Icon(
        Icons.notifications_rounded,
        size: 18,
        color: _reminderEnabled
            ? theme.colorScheme.primary
            : theme.textTheme.labelSmall?.color,
      ),
    );
  }
}
