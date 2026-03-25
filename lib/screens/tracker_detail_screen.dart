import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskmanager/widgets/app_header.dart';
import '../models/tracker.dart';
import '../providers/tracker_provider.dart';
import '../utils/app_theme.dart';
import 'edit_tracker_screen.dart';

/// A screen providing a detailed view of a habit [Tracker], including
/// streak statistics and a full calendar visualization of completion history.
class TrackerDetailScreen extends StatefulWidget {
  /// The tracker entry to display.
  final Tracker trackerEntry;

  const TrackerDetailScreen({super.key, required this.trackerEntry});

  @override
  State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
}

class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
  late DateTime _displayMonth;
  late PageController _pageController;
  late int _pageIndex;

  /// A list of months representing the scrollable history from the tracker's
  /// start date up to the current month.
  late List<DateTime> _months;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = DateTime(
      widget.trackerEntry.startDate.year,
      widget.trackerEntry.startDate.month,
    );
    final current = DateTime(now.year, now.month);

    // Populate the list of months for the swipable calendar.
    _months = [];
    DateTime m = start;
    while (!m.isAfter(current)) {
      _months.add(m);
      m = DateTime(m.year, m.month + 1);
    }
    if (_months.isEmpty) _months = [current];

    _pageIndex = _months.length - 1; // Start viewer at the current month.
    _displayMonth = _months[_pageIndex];
    _pageController = PageController(initialPage: _pageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Calculates a darker accent color for the tracker based on its color index.
  Color _barColor(BuildContext context) {
    final base = Color(
      AppColors.cardPalette[widget.trackerEntry.colorIndex %
          AppColors.cardPalette.length],
    );
    final hsl = HSLColor.fromColor(base);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return hsl
        .withLightness(isDark ? 0.46 : 0.50)
        .withSaturation(0.68)
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final barColor = _barColor(context);
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Consumer<TrackerProvider>(
      builder: (_, provider, _) {
        // Fetch fresh entry data from the provider to ensure persistence across toggles.
        final entry = provider.entries.firstWhere(
          (e) => e.id == widget.trackerEntry.id,
          orElse: () => widget.trackerEntry,
        );

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                AppHeader(
                  title: entry.title,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _editButton(context, entry, theme, surface),
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
                        // General Info
                        // Container(
                        //   width: double.infinity,
                        //   padding: const EdgeInsets.all(16),
                        //   decoration: BoxDecoration(
                        //     color: surface,
                        //     borderRadius: BorderRadius.circular(
                        //       AppSizes.radiusCard,
                        //     ),
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: Colors.black.withValues(
                        //           alpha: isDark ? 0.3 : 0.06,
                        //         ),
                        //         blurRadius: 16,
                        //         offset: const Offset(0, 4),
                        //       ),
                        //     ],
                        //   ),
                        //   child: Column(
                        //     children: [
                        //       AppInfoRow(
                        //         icon: Icons.calendar_today_rounded,
                        //         label: 'Created On',
                        //         value: _formatDate(entry.startDate),
                        //         barColor: theme.colorScheme.primary,
                        //       ),
                        //       if (entry.reminderEnabled) ...[
                        //         const Divider(height: 1),
                        //         AppInfoRow(
                        //           icon: Icons.notifications_rounded,
                        //           label: 'Reminder',
                        //           value: _formatTime(
                        //             entry.reminderHour,
                        //             entry.reminderMinute,
                        //           ),
                        //           barColor: theme.colorScheme.primary,
                        //         ),
                        //       ],
                        //       const Divider(height: 1),
                        //       AppInfoRow(
                        //         icon: Icons.trending_up_rounded,
                        //         label: 'Success Rate',
                        //         value:
                        //             '${((entry.doneDays / entry.totalDays) * 100).toStringAsFixed(0)}%',
                        //         barColor: theme.colorScheme.primary,
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        // const SizedBox(height: 20),

                        // Statistics Row (Streak and Total Completion)
                        Row(
                          children: [
                            _statCard(
                              context,
                              label: 'Current Streak',
                              value: '${entry.currentStreak}',
                              color: AppColors.warning,
                              surface: surface,
                            ),
                            const SizedBox(width: 10),
                            _statCard(
                              context,
                              label: 'Total Done',
                              value: '${entry.doneDays} / ${entry.totalDays}',
                              color: AppColors.success,
                              surface: surface,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Interactive Month-by-Month Calendar
                        _calendarCard(
                          context,
                          entry,
                          barColor,
                          surface,
                          theme,
                          isDark,
                        ),

                        // Optional Notes Section
                        if (entry.description.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _notesSection(entry, theme, surface),
                        ],
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

  Widget _editButton(
    BuildContext context,
    Tracker entry,
    ThemeData theme,
    Color surface,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditTrackerScreen(trackerEntry: entry),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: theme.dividerColor, width: 1),
          borderRadius: BorderRadius.circular(AppSizes.radiusButton),
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

  Widget _calendarCard(
    BuildContext context,
    Tracker entry,
    Color barColor,
    Color surface,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month/Year Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _monthNavButton(direction: -1, theme: theme, surface: surface),
                Column(
                  children: [
                    Text(
                      _monthName(_displayMonth.month),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '${_displayMonth.year}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                _monthNavButton(direction: 1, theme: theme, surface: surface),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Weekday Labels (Mon-Sun)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _subtextColor(context),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Calendar Grid
          SizedBox(
            height: _calendarHeight(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _months.length,
              onPageChanged: (i) => setState(() {
                _pageIndex = i;
                _displayMonth = _months[i];
              }),
              itemBuilder: (_, i) =>
                  _buildCalendarPage(context, entry, barColor, _months[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthNavButton({
    required int direction,
    required ThemeData theme,
    required Color surface,
  }) {
    final bool canNav = direction == -1
        ? _pageIndex > 0
        : _pageIndex < _months.length - 1;
    return GestureDetector(
      onTap: canNav
          ? () {
              if (direction == -1) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          : null,
      child: AnimatedOpacity(
        opacity: canNav ? 1.0 : 0.25,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Icon(
            direction == -1
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _notesSection(Tracker entry, ThemeData theme, Color surface) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes', style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(entry.description, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// Calculates a fixed height for the calendar grid based on the maximum 6 rows.
  double _calendarHeight() => 6 * 48.0;

  /// Builds a single month's grid for the swipable calendar.
  Widget _buildCalendarPage(
    BuildContext context,
    Tracker entry,
    Color barColor,
    DateTime monthDate,
  ) {
    final year = monthDate.year;
    final month = monthDate.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDay = DateTime(year, month, 1);

    // ISO weekday adjustment (Monday = 1).
    final leadingEmpties = firstDay.weekday - 1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(
      entry.startDate.year,
      entry.startDate.month,
      entry.startDate.day,
    );

    final totalCells = leadingEmpties + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: List.generate(rows, (rowIndex) {
          // Pre-calculate cell data for the row to determine continuity (connectors).
          final cells = List.generate(7, (colIndex) {
            final cellIndex = rowIndex * 7 + colIndex;
            if (cellIndex < leadingEmpties ||
                cellIndex >= leadingEmpties + daysInMonth) {
              return null;
            }
            final dayNum = cellIndex - leadingEmpties + 1;
            final date = DateTime(year, month, dayNum);
            return {
              'dayNum': dayNum,
              'date': date,
              'isToday': date == today,
              'isFuture': date.isAfter(today),
              'isBeforeStart': date.isBefore(startDate),
              'done': entry.isDayOn(date),
            };
          });

          return SizedBox(
            height: 48,
            child: Row(
              children: List.generate(7, (colIndex) {
                final cell = cells[colIndex];
                if (cell == null) return const Expanded(child: SizedBox());

                final dayNum = cell['dayNum'] as int;
                final date = cell['date'] as DateTime;
                final isToday = cell['isToday'] as bool;
                final done = cell['done'] as bool;
                final inactive =
                    (cell['isBeforeStart'] as bool) ||
                    (cell['isFuture'] as bool);

                // Continuity logic: check if neighbors are also completed.
                final prevCell = colIndex > 0 ? cells[colIndex - 1] : null;
                final nextCell = colIndex < 6 ? cells[colIndex + 1] : null;

                final isPrevDone =
                    prevCell != null &&
                    (prevCell['done'] as bool) &&
                    !(prevCell['isBeforeStart'] as bool) &&
                    !(prevCell['isFuture'] as bool);
                final isNextDone =
                    nextCell != null &&
                    (nextCell['done'] as bool) &&
                    !(nextCell['isBeforeStart'] as bool) &&
                    !(nextCell['isFuture'] as bool);

                return Expanded(
                  child: GestureDetector(
                    onTap: inactive
                        ? null
                        : () async {
                            try {
                              await context.read<TrackerProvider>().toggleDate(
                                entry.id,
                                date,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      entry.isDayOn(date)
                                          ? 'Goal accomplished for today!'
                                          : 'Entry removed',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to update goal'),
                                  ),
                                );
                              }
                            }
                          },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Left & Right visual connectors for completed streaks.
                        if (done && isPrevDone && !inactive)
                          _connector(Alignment.centerLeft, barColor),
                        if (done && isNextDone && !inactive)
                          _connector(Alignment.centerRight, barColor),

                        // The individual date circle.
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: inactive
                                ? Colors.transparent
                                : (done ? barColor : Colors.transparent),
                            border: isToday && !done
                                ? Border.all(
                                    color: barColor.withValues(alpha: 0.8),
                                    width: 1.8,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '$dayNum',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isToday
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                color: inactive
                                    ? _subtextColor(
                                        context,
                                      ).withValues(alpha: 0.3)
                                    : (done
                                          ? Colors.white
                                          : (isToday
                                                ? barColor
                                                : _subtextColor(context))),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  /// Specialized connector bar used to link consecutive completed days.
  Widget _connector(Alignment alignment, Color color) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: 0.5,
        child: Container(height: 34, color: color.withValues(alpha: 0.25)),
      ),
    );
  }

  /// Reusable stat card for streak and completion data.
  Widget _statCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required Color surface,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05,
              ),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _subtextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
