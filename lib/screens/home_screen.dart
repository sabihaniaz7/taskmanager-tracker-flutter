import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskmanager/providers/task_provider.dart';
import 'package:taskmanager/utils/app_theme.dart';
import 'package:taskmanager/widgets/task_card.dart';

/// The primary dashboard of the application, displaying categorized task lists.
///
/// Uses a [DefaultTabController] to switch between 'All', 'Active', and 'Completed' tasks.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabBar(context),
          Expanded(child: _buildTabViews()),
        ],
      ),
    );
  }

  /// Builds the top navigation bar with tab labels and indicators.
  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingXL),
      child: TabBar(
        tabs: const [
          Tab(text: 'All Tasks'),
          Tab(text: 'Active'),
          Tab(text: 'Completed'),
        ],
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 2.5, color: theme.colorScheme.primary),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
    );
  }

  /// Builds the scrollable views for each tab.
  Widget _buildTabViews() {
    return const TabBarView(
      physics: NeverScrollableScrollPhysics(),
      children: [
        _TaskList(type: _TaskListType.all),
        _TaskList(type: _TaskListType.active),
        _TaskList(type: _TaskListType.completed),
      ],
    );
  }
}

/// Categories for filtering the task list.
enum _TaskListType { all, active, completed }

/// An internal widget that renders a list of tasks for a specific [_TaskListType].
class _TaskList extends StatelessWidget {
  final _TaskListType type;
  const _TaskList({required this.type});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (_, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Select the appropriate list from the provider.
        final tasks = switch (type) {
          _TaskListType.all => provider.allTasks,
          _TaskListType.active => provider.activeTasks,
          _TaskListType.completed => provider.completedTasks,
        };

        if (tasks.isEmpty) {
          return _buildEmptyState(context, type);
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spacingXL,
            AppSizes.spacingL,
            AppSizes.spacingXL,
            100, // Extra padding at bottom for FAB.
          ),
          itemCount: tasks.length,
          itemBuilder: (ctx, i) => TaskCard(task: tasks[i]),
          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.spacingM),
        );
      },
    );
  }

  /// Renders a placeholder UI when the current task category is empty.
  Widget _buildEmptyState(BuildContext context, _TaskListType type) {
    final theme = Theme.of(context);
    final (icon, message) = switch (type) {
      _TaskListType.all => (Icons.add_task, 'No tasks yet.\nTap + to add one!'),
      _TaskListType.active => (
        Icons.check_circle_outline_rounded,
        'No active tasks.\nAll done!',
      ),
      _TaskListType.completed => (Icons.task, 'No completed tasks yet.'),
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: theme.textTheme.labelSmall?.color,
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
