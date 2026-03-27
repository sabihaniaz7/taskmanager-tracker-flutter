import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/app_theme.dart';

/// A self-contained, collapsible widget for configuring task reminders.
///
/// Used in both creation and editing screens to allow users to select
/// [ReminderMode], time, and optional custom lead times.
class ReminderSection extends StatefulWidget {
  /// Whether the task is constrained to a single day.
  ///
  /// Affects available modes (e.g., 'Daily' is hidden for single-day tasks).
  final bool isSingleDay;

  /// The initial [ReminderMode] to display.
  final ReminderMode initialMode;

  /// The initial time of day for the reminder.
  final TimeOfDay initialTime;

  /// The initial value for custom lead days (e.g., "X days before").
  final int initialCustomDays;

  /// Callback triggered whenever any part of the configuration changes.
  final ValueChanged<ReminderConfig> onChanged;

  const ReminderSection({
    super.key,
    required this.isSingleDay,
    required this.onChanged,
    this.initialMode = ReminderMode.none,
    this.initialTime = const TimeOfDay(hour: 9, minute: 0),
    this.initialCustomDays = 1,
  });

  @override
  State<ReminderSection> createState() => _ReminderSectionState();
}

/// A data class representing the current state of the reminder configuration.
class ReminderConfig {
  final ReminderMode mode;
  final TimeOfDay time;
  final int customDays;
  ReminderConfig({
    required this.mode,
    required this.time,
    required this.customDays,
  });
}

class _ReminderSectionState extends State<ReminderSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnim;

  bool _enabled = false;
  late ReminderMode _mode;
  late TimeOfDay _time;
  late int _customDays;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _time = widget.initialTime;
    _customDays = widget.initialCustomDays;
    _enabled = _mode != ReminderMode.none;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _expandAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    // If initially enabled, skip the animation and show expanded.
    if (_enabled) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(ReminderSection old) {
    super.didUpdateWidget(old);
    // Reset to a compatible mode if the task duration type changes.
    if (old.isSingleDay != widget.isSingleDay) {
      final changed = _resetModeForDuration();
      if (changed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _emit();
        });
      }
    }
  }

  /// Ensures the selected mode remains valid for the current task duration.
  bool _resetModeForDuration() {
    if (widget.isSingleDay &&
        (_mode == ReminderMode.onceDayBefore ||
            _mode == ReminderMode.daily ||
            _mode == ReminderMode.customDays)) {
      _mode = ReminderMode.onDueDate;
      return true;
    } else if (!widget.isSingleDay && _mode == ReminderMode.onDueDate) {
      _mode = ReminderMode.onceDayBefore;
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Toggles the entire reminder feature on or off.
  void _toggle(bool val) {
    setState(() {
      _enabled = val;
      if (_enabled) {
        // Set a sensible default mode when enabling.
        _mode = widget.isSingleDay
            ? ReminderMode.onDueDate
            : ReminderMode.onceDayBefore;
        _controller.forward();
      } else {
        _mode = ReminderMode.none;
        _controller.reverse();
      }
    });
    _emit();
  }

  /// Notifies the parent widget of the current configuration.
  void _emit() {
    widget.onChanged(
      ReminderConfig(
        mode: _enabled ? _mode : ReminderMode.none,
        time: _time,
        customDays: _customDays,
      ),
    );
  }

  /// Displays the native time picker and updates the state.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _time = picked);
      _emit();
    }
  }

  /// Helper to format [TimeOfDay] into a localized string (e.g., "9:00 AM").
  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        border: Border.all(
          color: _enabled
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.dividerColor,
          width: _enabled ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Toggle and basic summary.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingL,
              vertical: AppSizes.spacingM + 2,
            ),
            child: Row(
              children: [
                _headerIcon(theme),
                const SizedBox(width: AppSizes.spacingM),
                Expanded(child: _headerText(theme)),
                Switch.adaptive(
                  value: _enabled,
                  onChanged: _toggle,
                  activeThumbColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),

          // Expandable settings body.
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(height: 1, color: theme.dividerColor),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'WHEN TO REMIND',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: AppSizes.spacingS),
                      _modeSelector(theme),
                      if (_mode == ReminderMode.customDays) ...[
                        const SizedBox(height: AppSizes.spacingM),
                        _customDaysRow(theme),
                      ],
                      const SizedBox(height: AppSizes.spacingL),
                      Text('AT WHAT TIME', style: theme.textTheme.labelMedium),
                      const SizedBox(height: AppSizes.spacingS),
                      _timeTile(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(ThemeData theme) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: _enabled
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.dividerColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Icon(
        Icons.notifications_rounded,
        size: 18,
        color: _enabled
            ? theme.colorScheme.primary
            : theme.textTheme.labelSmall?.color,
      ),
    );
  }

  Widget _headerText(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: AppSizes.fontBody + 1,
          ),
        ),
        if (!_enabled)
          Text('Tap to set a reminder', style: theme.textTheme.labelSmall),
        if (_enabled)
          Text(
            _summaryText(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
      ],
    );
  }

  /// Builds a selection of chips for different reminder schedules.
  Widget _modeSelector(ThemeData theme) {
    final modes = widget.isSingleDay
        ? [
            _ModeOption(
              mode: ReminderMode.onDueDate,
              label: 'On due day',
              icon: Icons.today_rounded,
            ),
          ]
        : [
            _ModeOption(
              mode: ReminderMode.onceDayBefore,
              label: 'Day before',
              icon: Icons.event_rounded,
            ),
            _ModeOption(
              mode: ReminderMode.daily,
              label: 'Daily',
              icon: Icons.repeat_rounded,
            ),
            _ModeOption(
              mode: ReminderMode.customDays,
              label: 'Custom',
              icon: Icons.tune_rounded,
            ),
          ];

    return Wrap(
      spacing: AppSizes.spacingS,
      runSpacing: AppSizes.spacingS,
      children: modes.map((opt) => _modeChip(theme, opt)).toList(),
    );
  }

  /// Internal helper to build an individual mode selection chip.
  Widget _modeChip(ThemeData theme, _ModeOption opt) {
    final isSelected = _mode == opt.mode;
    return GestureDetector(
      onTap: () {
        setState(() => _mode = opt.mode);
        _emit();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingM,
          vertical: AppSizes.spacingS + 1,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.dividerColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              opt.icon,
              size: 14,
              color: isSelected
                  ? (theme.brightness == Brightness.dark
                        ? AppColors.darkBg
                        : Colors.white)
                  : theme.textTheme.labelSmall?.color,
            ),
            const SizedBox(width: 5),
            Text(
              opt.label,
              style: TextStyle(
                fontSize: AppSizes.fontLabel,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? (theme.brightness == Brightness.dark
                          ? AppColors.darkBg
                          : Colors.white)
                    : theme.textTheme.labelSmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the numeric stepper for selecting custom lead days.
  Widget _customDaysRow(ThemeData theme) {
    return Row(
      children: [
        Text('Days before due:', style: theme.textTheme.bodyMedium),
        const Spacer(),
        _stepperButton(
          icon: Icons.remove_rounded,
          onTap: () {
            if (_customDays > 1) {
              setState(() => _customDays--);
              _emit();
            }
          },
          theme: theme,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
          child: Text(
            '$_customDays',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _stepperButton(
          icon: Icons.add_rounded,
          onTap: () {
            if (_customDays < 30) {
              setState(() => _customDays++);
              _emit();
            }
          },
          theme: theme,
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
    );
  }

  /// Builds the interactive tile that opens the time picker.
  Widget _timeTile(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingL,
          vertical: AppSizes.spacingM,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall + 2),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: AppSizes.iconS,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSizes.spacingS),
            Text(_formatTime(_time), style: theme.textTheme.titleMedium),
            const Spacer(),
            Text('Tap to change', style: theme.textTheme.labelSmall),
            const SizedBox(width: AppSizes.spacingXS),
            Icon(
              Icons.chevron_right_rounded,
              size: AppSizes.iconM,
              color: theme.textTheme.labelSmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  /// Generates a human-friendly summary of the current settings for the header.
  String _summaryText() {
    final timeStr = _formatTime(_time);
    switch (_mode) {
      case ReminderMode.onDueDate:
        return 'On due day at $timeStr';
      case ReminderMode.onceDayBefore:
        return '1 day before at $timeStr';
      case ReminderMode.daily:
        return 'Daily at $timeStr';
      case ReminderMode.customDays:
        return '$_customDays day${_customDays > 1 ? "s" : ""} before at $timeStr';
      case ReminderMode.none:
        return 'Off';
    }
  }
}

/// Metadata for a specific reminder mode option.
class _ModeOption {
  final ReminderMode mode;
  final String label;
  final IconData icon;
  const _ModeOption({
    required this.mode,
    required this.label,
    required this.icon,
  });
}
