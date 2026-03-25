import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taskmanager/models/task.dart';
import 'package:taskmanager/providers/task_provider.dart';
import 'package:taskmanager/services/notification_service.dart';
import 'package:taskmanager/utils/app_theme.dart';
import 'package:taskmanager/widgets/app_button.dart';
import 'package:taskmanager/widgets/app_date_tile.dart';
import 'package:taskmanager/widgets/app_header.dart';
import 'package:taskmanager/widgets/app_label.dart';
import 'package:taskmanager/widgets/reminder_section.dart';

/// A screen that allows users to create a new task with custom titles,
/// descriptions, date ranges, and notification reminders.
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;

  // Reminder State
  ReminderMode _reminderMode = ReminderMode.none;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  int _customDays = 1;

  /// Determines if the task is defined for a single calendar day.
  bool get _isSingleDay =>
      _startDate.year == _endDate.year &&
      _startDate.month == _endDate.month &&
      _startDate.day == _endDate.day;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Formats a date for display (e.g., "11 Mar 2026").
  String _formatDate(DateTime date) => DateFormat('d MMM yyyy').format(date);

  /// Opens the native date picker and updates the start or end date.
  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Ensure end date is never before start date.
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  /// Saves the task to the provider and closes the screen.
  ///
  /// The flow includes:
  /// 1. Form validation.
  /// 2. Notification permission check (if a reminder is set).
  /// 3. Task persistence via [TaskProvider].
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifService = NotificationService();
    if (!notifService.permissionGranted && _reminderMode != ReminderMode.none) {
      // Show explanation dialog before triggering the OS prompt.
      final shouldRequest = await _showPermissionRationale();
      if (shouldRequest == true) {
        await notifService.requestPermission();
      }
    }

    try {
      if (!mounted) return;

      await context.read<TaskProvider>().addTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        reminderMode: _reminderMode,
        reminderHour: _reminderTime.hour,
        reminderMinute: _reminderTime.minute,
        customDaysBefore: _customDays,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save task. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Displays a custom dialog explaining why notification permissions are needed.
  Future<bool?> _showPermissionRationale() async {
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
              'Enable Reminders?',
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingM),
            Text(
              'Allow notifications so your task reminders arrive on time.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingS),
          ],
        ),
        actionsPadding: const EdgeInsets.all(AppSizes.spacingL),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          // "Skip" — task saves without notifications
          TextButton(
            child: Text(
              'Skip',
              style: TextStyle(color: theme.textTheme.labelSmall?.color),
            ),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          // "Allow" — triggers the OS permission prompt
          FilledButton(
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
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppHeader(
        title: "New Task",
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        showBackButton: false, // Using custom close button instead
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSizes.spacingXL,
            AppSizes.spacingXL,
            AppSizes.spacingXL,
            AppSizes.spacingXL + MediaQuery.of(context).padding.bottom + 16,
          ),
          children: [
            const AppLabel('TASK TITLE *'),
            const SizedBox(height: AppSizes.spacingS),
            TextFormField(
              controller: _titleController,
              autofocus: false,
              decoration: AppTheme.commonInputDecoration(context, 'Enter task title...'),
              style: theme.textTheme.titleMedium,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: AppSizes.spacingXL),
            const AppLabel("DESCRIPTION"),
            const SizedBox(height: AppSizes.spacingS),
            TextFormField(
              controller: _descriptionController,
              decoration: AppTheme.commonInputDecoration(context, 'Add a description...'),
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSizes.spacingXL),
            // --Date Pickers --
            const AppLabel('DURATION'),
            const SizedBox(height: AppSizes.spacingS),
            Row(
              children: [
                Expanded(
                  child: AppDateTile(
                    label: 'START DATE',
                    dateText: _formatDate(_startDate),
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: AppSizes.spacingXL),
                Expanded(
                  child: AppDateTile(
                    label: 'END DATE',
                    dateText: _formatDate(_endDate),
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingXL),
            // --Reminder --
            const AppLabel('REMINDER'),
            const SizedBox(height: AppSizes.spacingS),
            ReminderSection(
              isSingleDay: _isSingleDay,
              initialMode: _reminderMode,
              initialTime: _reminderTime,
              initialCustomDays: _customDays,
              onChanged: (config) {
                setState(() {
                  _reminderMode = config.mode;
                  _reminderTime = config.time;
                  _customDays = config.customDays;
                });
              },
            ),
            const SizedBox(height: AppSizes.spacingXL),
            AppButton(
              text: 'Save Task',
              isLoading: _isSaving,
              onPressed: _saveTask,
            ),
          ],
        ),
      ),
    );
  }
}
