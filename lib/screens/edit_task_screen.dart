import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:taskmanager/utils/app_theme.dart';
import 'package:taskmanager/widgets/app_button.dart';
import 'package:taskmanager/widgets/app_date_tile.dart';
import 'package:taskmanager/widgets/app_header.dart';
import 'package:taskmanager/widgets/app_label.dart';
import 'package:taskmanager/widgets/reminder_section.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

/// A screen that allows users to modify the details of an existing [Task].
///
/// Pre-populates fields with the task's current data and allows updating
/// title, description, duration, and reminder settings.
class EditTaskScreen extends StatefulWidget {
  /// The task to be edited.
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSaving = false;

  // Reminder State
  late ReminderMode _reminderMode;
  late TimeOfDay _reminderTime;
  late int _customDays;

  /// Determines if the updated task duration is a single calendar day.
  bool get _isSingleDay =>
      _startDate.year == _endDate.year &&
      _startDate.month == _endDate.month &&
      _startDate.day == _endDate.day;

  /// The maximum number of custom days allowed (distance from Start Date/Today to End Date).
  int get _maxCustomDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // The reminder cannot be before today, AND it must be within the task duration.
    final effectiveStart = _startDate.isBefore(today) ? today : _startDate;
    
    final start = DateTime(effectiveStart.year, effectiveStart.month, effectiveStart.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    
    final diff = end.difference(start).inDays;
    return diff > 0 ? diff : 0;
  }

  @override
  void initState() {
    super.initState();
    // Initialize state with current task properties.
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _startDate = widget.task.startDate;
    _endDate = widget.task.endDate;
    _reminderMode = widget.task.reminderMode;
    _reminderTime = TimeOfDay(
      hour: widget.task.reminderHour,
      minute: widget.task.reminderMinute,
    );
    _customDays = widget.task.customDaysBefore;
  }

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
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Ensure end date remains valid relative to start.
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  /// Persists the updated task details to the provider.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final normalizedReminderMode = _isSingleDay
        ? (_reminderMode == ReminderMode.none
              ? ReminderMode.none
              : ReminderMode.onDueDate)
        : (_reminderMode == ReminderMode.onDueDate
              ? ReminderMode.onceDayBefore
              : _reminderMode);

    final updated = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      reminderMode: normalizedReminderMode,
      reminderHour: _reminderTime.hour,
      reminderMinute: _reminderTime.minute,
      customDaysBefore: _customDays,
    );

    try {
      await context.read<TaskProvider>().updateTask(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update task. Please try again.'),
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
    return Scaffold(
      appBar: AppHeader(
        title: 'Edit Task',
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
              style: theme.textTheme.titleMedium,
              textCapitalization: TextCapitalization.sentences,
              decoration: AppTheme.commonInputDecoration(context, 'Task title...'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: AppSizes.spacingXL),
            const AppLabel('DESCRIPTION'),
            const SizedBox(height: AppSizes.spacingS),
            TextFormField(
              controller: _descriptionController,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: AppTheme.commonInputDecoration(context, 'Description...'),
            ),
            const SizedBox(height: AppSizes.spacingXL),
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
            // Reminder Section
            const AppLabel('REMINDER'),
            const SizedBox(height: AppSizes.spacingS),
            ReminderSection(
              isSingleDay: _isSingleDay,
              maxCustomDays: _maxCustomDays,
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
              text: 'Save Changes',
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
