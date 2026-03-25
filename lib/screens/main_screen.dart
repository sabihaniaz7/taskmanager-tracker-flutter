import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskmanager/providers/task_provider.dart';
import 'package:taskmanager/screens/add_task_screen.dart';
import 'package:taskmanager/screens/add_tracker_screen.dart';
import 'package:taskmanager/screens/home_screen.dart';
import 'package:taskmanager/screens/tracker_screen.dart';
import 'package:taskmanager/utils/app_theme.dart';

/// The root-level screen that manages the application shell.
///
/// It handles top-level navigation between [HomeScreen] and [TrackerScreen]
/// via a [PageView] and a custom bottom navigation bar. It also provides
/// a shared header with theme toggling and sorting capabilities.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  /// Global key to access the state of [TrackerScreen] for triggering its sort sheet.
  final _trackerKey = GlobalKey<TrackerScreenState>();

  // Configuration for the shared header.
  static const _titles = ['Plan Your Tasks', 'Track Your Goals'];
  static const _subtitles = ['Stay Organized.', 'Build Consistent Habits.'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  /// Switches the active tab and animates the [PageView] to the corresponding screen.
  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Navigates to the appropriate creation screen based on the current tab.
  void _onAddPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _currentIndex == 0
            ? const AddTaskScreen()
            : const AddTrackerScreen(),
      ),
    );
  }

  /// Displays the task sorting bottom sheet.
  void _showSortSheet(BuildContext context) {
    final provider = context.read<TaskProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer<TaskProvider>(
        builder: (_, p, _) {
          final theme = Theme.of(ctx);
          final isDark = theme.brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusSheet),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              AppSizes.spacingXL,
              AppSizes.spacingM,
              AppSizes.spacingXL,
              AppSizes.spacingXXL + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Visual drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXL),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sort Tasks',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingM),
                ..._sortOptions.map((opt) {
                  final isSelected = p.sortOption == opt['value'];
                  return GestureDetector(
                    onTap: () {
                      provider.setSortOption(opt['value'] as SortOptions);
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacingL,
                        vertical: AppSizes.spacingM + 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                            : theme.dividerColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusButton,
                        ),
                        border: isSelected
                            ? Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            opt['icon'] as IconData,
                            size: AppSizes.iconM,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.textTheme.labelSmall?.color,
                          ),
                          const SizedBox(width: AppSizes.spacingM),
                          Expanded(
                            child: Text(
                              opt['label'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.textTheme.titleMedium?.color,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              size: AppSizes.iconM,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  static const _sortOptions = [
    {
      'label': 'By Start Date',
      'value': SortOptions.startDate,
      'icon': Icons.event,
    },
    {
      'label': 'By End Date',
      'value': SortOptions.endDate,
      'icon': Icons.event_available,
    },
    {
      'label': 'By Created Date',
      'value': SortOptions.createdDate,
      'icon': Icons.edit_calendar,
    },
    {
      'label': 'Overdue First',
      'value': SortOptions.overdueFirst,
      'icon': Icons.warning_amber_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final inactiveColor = isDark
        ? AppColors.darkSubtext
        : AppColors.lightSubtext;
    final activeColor = theme.colorScheme.primary;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            // Shared header row (Title, Subtitle, Theme Toggle, Sort)
            _SharedHeader(
              currentIndex: _currentIndex,
              titles: _titles,
              subtitles: _subtitles,
              isDark: isDark,
              onToggleTheme: () => context.read<ThemeModeNotifier>().toggle(),
              onSort: _currentIndex == 0
                  ? () => _showSortSheet(context)
                  : () => _trackerKey.currentState?.showSortSheet(context),
            ),

            // Swipeable content pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentIndex = i),
                children: [
                  const HomeScreen(),
                  TrackerScreen(key: _trackerKey),
                ],
              ),
            ),
          ],
        ),
      ),

      // Custom floating bottom navigation bar
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
        onAddPressed: _onAddPressed,
        bgColor: bgColor,
        inactiveColor: inactiveColor,
        activeColor: activeColor,
        isDark: isDark,
      ),
    );
  }
}

/// A shared header component used across all main screens.
///
/// Features internal animations for title and subtitle transitions.
class _SharedHeader extends StatelessWidget {
  final int currentIndex;
  final List<String> titles;
  final List<String> subtitles;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback? onSort;

  const _SharedHeader({
    required this.currentIndex,
    required this.titles,
    required this.subtitles,
    required this.isDark,
    required this.onToggleTheme,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spacingXL,
        AppSizes.spacingXL,
        AppSizes.spacingM,
        AppSizes.spacingS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animated text identity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    titles[currentIndex],
                    key: ValueKey(titles[currentIndex]),
                    style: theme.textTheme.displaySmall,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXS),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    subtitles[currentIndex],
                    key: ValueKey(subtitles[currentIndex]),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),

          // Utility buttons (Theme and Sort)
          _HeaderIconButton(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            onTap: onToggleTheme,
          ),
          const SizedBox(width: AppSizes.spacingXS),

          AnimatedOpacity(
            opacity: onSort != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: onSort == null,
              child: _HeaderIconButton(
                icon: Icons.tune_rounded,
                onTap: onSort ?? () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable square icon button used in the shared header.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall + 2),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Icon(
          icon,
          size: AppSizes.iconM,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// A custom bottom navigation bar with a floating action button in the center.
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onAddPressed;
  final Color bgColor;
  final Color inactiveColor;
  final Color activeColor;
  final bool isDark;

  const _BottomNav({
    required this.currentIndex,
    required this.onTabChanged,
    required this.onAddPressed,
    required this.bgColor,
    required this.inactiveColor,
    required this.activeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 12),
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Background container with tabs
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusSheet),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.task_alt_rounded,
                    label: 'Tasks',
                    inactiveColor: inactiveColor,
                    activeColor: activeColor,
                    onTap: () => onTabChanged(0),
                    isActive: currentIndex == 0,
                  ),
                ),
                const SizedBox(width: 72), // Space for floating center button
                Expanded(
                  child: _NavItem(
                    icon: Icons.show_chart_rounded,
                    label: 'Tracker',
                    inactiveColor: inactiveColor,
                    activeColor: activeColor,
                    onTap: () => onTabChanged(1),
                    isActive: currentIndex == 1,
                  ),
                ),
              ],
            ),
          ),

          // Floating Action Button
          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: onAddPressed,
              child: Consumer<ThemeModeNotifier>(
                builder: (_, notifier, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: isDark ? AppColors.darkBg : AppColors.lightBg,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual navigation item for the custom bottom bar.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.inactiveColor,
    required this.activeColor,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusButton),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
