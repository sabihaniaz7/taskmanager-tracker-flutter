import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskmanager/models/tracker.dart';
import 'package:taskmanager/providers/tracker_provider.dart';
import 'package:taskmanager/screens/tracker_detail_screen.dart';
import 'package:taskmanager/utils/app_theme.dart';

/// A card widget that displays a 7-day progress strip for a [Tracker].
///
/// Supported interactions:
/// - Tap: Navigates to the habit tracker details screen.
/// - Swipe Left: Deletes the tracker (with confirmation).
/// - Day Tap: Toggles completion status for a specific date in the 7-day strip.
class TrackerCard extends StatelessWidget {
  /// The tracker data to display.
  final Tracker trackerEntry;

  const TrackerCard({super.key, required this.trackerEntry});

  /// Calculates the background color for the card based on the tracker's [colorIndex].
  Color _cardColor(BuildContext context) {
    return Color(
      AppColors.cardPalette[trackerEntry.colorIndex %
          AppColors.cardPalette.length],
    );
  }

  /// Calculates a darker accent color for the left streak bar and status indicators.
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
    final entry = trackerEntry;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final barColor = _barColor(context);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: _swipeBg(isDelete: false),
      secondaryBackground: _swipeBg(isDelete: true),
      confirmDismiss: (dir) async {
        // Confirm before deletion on left swipe.
        return await _confirmDelete(context);
      },
      onDismissed: (dir) {
        if (dir == DismissDirection.endToStart) {
          context.read<TrackerProvider>().deleteEntry(entry.id);
        }
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrackerDetailScreen(trackerEntry: entry),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _cardColor(context),
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Stylized left bar displaying the start date of the habit.
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: _dateBar(context, entry),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 42),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.lightPrimary,
                                decoration: entry.isArchived
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (entry.currentStreak > 0) ...[
                            const SizedBox(width: 8),
                            _streakBadge(entry.currentStreak, barColor),
                          ],
                        ],
                      ),
                      if (entry.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          entry.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Interactive 7-day progress strip.
                      _sevenDayStrip(context, entry, barColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the background UI for swiping actions.
  Widget _swipeBg({required bool isDelete}) {
    return Container(
      decoration: BoxDecoration(
        color: isDelete ? AppColors.danger : AppColors.success,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      alignment: isDelete ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(
        isDelete ? Icons.delete_rounded : Icons.check_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  /// Builds the stylized left bar showing the start date of the habit.
  Widget _dateBar(BuildContext context, Tracker entry) {
    final barColor = _barColor(context);
    final showYear = entry.startDate.year != DateTime.now().year;

    return Container(
      width: 42,
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(AppSizes.radiusCard),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${entry.startDate.day}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            _monthAbbr(entry.startDate.month).toUpperCase(),
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
          if (showYear)
            Text(
              '${entry.startDate.year}',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }

  String _monthAbbr(int month) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return m[month - 1];
  }

  /// Builds an interactive row of circles representing the last 7 days of the habit.
  Widget _sevenDayStrip(BuildContext context, Tracker entry, Color barColor) {
    final days = entry.last7Days.reversed.toList();
    final doneColor = barColor;
    final missedBorderColor = barColor.withValues(alpha: 0.5);
    final missedBgColor = barColor.withValues(alpha: 0.12);

    return Row(
      children: days.map((d) {
        final date = d['date'] as DateTime;
        final done = d['done'] as bool;
        final isBeforeStart = d['isBeforeStart'] as bool;
        final isFuture = d['isFuture'] as bool;
        final isToday =
            Tracker.dateKey(date) == Tracker.dateKey(DateTime.now());

        const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        final dayLabel = dayNames[date.weekday - 1];

        return Expanded(
          child: Column(
            children: [
              Text(
                dayLabel,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w900,
                  color: isToday ? barColor : AppColors.subtextColor(context),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: isBeforeStart || isFuture
                    ? null
                    : () => context.read<TrackerProvider>().toggleDate(
                        entry.id,
                        date,
                      ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 26,
                  width: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isBeforeStart || isFuture
                        ? Colors.transparent
                        : done
                        ? doneColor
                        : missedBgColor,
                    border: isBeforeStart || isFuture
                        ? null
                        : Border.all(
                            color: done ? doneColor : missedBorderColor,
                            width: isToday ? 2 : 1.5,
                          ),
                  ),
                  child: isBeforeStart || isFuture
                      ? null
                      : Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: done ? Colors.white : doneColor,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Shows a confirmation dialog before deleting the tracker.
  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        title: const Text('Delete Tracker?'),
        content: Text(
          'Delete "${trackerEntry.title}"? All history will be lost.',
        ),
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

  Widget _streakBadge(int streak, Color barColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: barColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusChip + 2),
        border: Border.all(color: barColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: barColor,
            ),
          ),
          const SizedBox(width: 3),
          Text('🔥'),
        ],
      ),
    );
  }
}
