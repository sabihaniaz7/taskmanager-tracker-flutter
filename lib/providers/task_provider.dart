import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskmanager/models/task.dart';
import 'package:taskmanager/services/notification_service.dart';
import 'package:taskmanager/services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Available options for sorting the task list in the UI.
enum SortOptions {
  /// Sort by scheduled start date (chronological).
  startDate,

  /// Sort by scheduled end (due) date (chronological).
  endDate,

  /// Sort by the date the task was created (newest first).
  createdDate,

  /// Sort overdue tasks to the top, then by end date.
  overdueFirst,
}

/// Manages the state and business logic for tasks.
///
/// This provider acts as the central hub for task management, coordinating:
/// *   **Persistence**: Saving/loading tasks using [StorageService].
/// *   **Notifications**: Scheduling/canceling alerts via [NotificationService].
/// *   **Widgets**: Triggering refreshes for the Android home screen widget.
/// *   **State**: Exposing filtered and sorted task lists to the UI.
class TaskProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();
  final _uuid = const Uuid();

  /// Platform channel for communicating with the native Android widget provider.
  static const _widgetChannel = MethodChannel('com.example.taskmanager/widget');

  /// Requests the native platform to refresh all active home screen widgets.
  ///
  /// This ensures that changes made within the app are immediately reflected
  /// on the user's home screen.
  Future<void> _refreshWidget() async {
    try {
      await _widgetChannel.invokeMethod('refreshWidget');
    } catch (_) {
      // Ignore errors if the platform channel is not available (e.g., on iOS).
    }
  }

  /// The internal source of truth for all tasks.
  List<Task> _tasks = [];

  /// Current sorting strategy for the task list.
  SortOptions _sortOption = SortOptions.createdDate;

  /// Private state to track if a long-running operation is in progress.
  bool _isLoading = false;

  /// Returns all tasks, sorted according to the current [_sortOption].
  List<Task> get allTasks => _sortedTasks(_tasks);

  /// Returns only tasks that are not yet marked as completed, sorted.
  List<Task> get activeTasks =>
      _sortedTasks(_tasks.where((t) => !t.isCompleted).toList());

  /// Returns only tasks that have been marked as completed, sorted.
  List<Task> get completedTasks =>
      _sortedTasks(_tasks.where((t) => t.isCompleted).toList());

  /// Exposes the current sorting strategy.
  SortOptions get sortOption => _sortOption;

  /// Whether the provider is currently fetching data from storage.
  bool get isLoading => _isLoading;

  /// Loads the initial task list from local persistence.
  ///
  /// Should be called during app initialization or when storage needs to be re-synced.
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tasks = await _storage.loadTasks();
    } catch (e) {
      // Error handled by UI via isLoading state or explicit feedback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns a new list containing the provided [tasks] sorted according to [_sortOption].
  List<Task> _sortedTasks(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
    switch (_sortOption) {
      case SortOptions.startDate:
        sorted.sort((a, b) => a.startDate.compareTo(b.startDate));
      case SortOptions.endDate:
        sorted.sort((a, b) => a.endDate.compareTo(b.endDate));
      case SortOptions.createdDate:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOptions.overdueFirst:
        sorted.sort((a, b) {
          if (a.isOverdue && !b.isOverdue) return -1;
          if (!a.isOverdue && b.isOverdue) return 1;
          return a.endDate.compareTo(b.endDate);
        });
    }
    return sorted;
  }

  /// Determines the next color index to use for a new task.
  ///
  /// Attempts to pick a color that is not currently in use by active tasks
  /// to provide visual variety in the list.
  int _nextColorIndex() {
    if (_tasks.isEmpty) return 0;
    const paletteSize = 8;
    final usedIndices = _tasks.map((t) => t.colorIndex).toSet();
    for (int i = 0; i < paletteSize; i++) {
      if (!usedIndices.contains(i)) {
        return i;
      }
    }
    final lastColor = _tasks.last.colorIndex;
    return (lastColor + 1) % paletteSize;
  }

  /// Creates and persists a new task.
  ///
  /// *   Generates a unique ID and notification IDs.
  /// *   Saves the task to storage.
  /// *   Schedules local notifications based on the provided [reminderMode].
  /// *   Refreshes the home screen widget.
  Future<void> addTask({
    required String title,
    String description = '',
    required DateTime startDate,
    required DateTime endDate,
    ReminderMode reminderMode = ReminderMode.none,
    int reminderHour = 9,
    int reminderMinute = 0,
    int customDaysBefore = 1,
  }) async {
    try {
      final id = _uuid.v4();
      final notifStartId = DateTime.now().millisecondsSinceEpoch % 100000;

      // Leave a gap of 50 between tasks so daily reminders (up to 31 IDs)
      // never collide with the next task's IDs.
      final notifRemindId = notifStartId + 50;

      final task = Task(
        id: id,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
        colorIndex: _nextColorIndex(),
        notificationStartId: notifStartId,
        notificationReminderId: notifRemindId,
        reminderMode: reminderMode,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        customDaysBefore: customDaysBefore,
      );

      _tasks.add(task);
      await _storage.saveTasks(_tasks);
      await _notifications.scheduleTaskNotifications(task);
      await _refreshWidget();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Updates an existing [task]'s details.
  ///
  /// Re-calculates and re-schedules notifications if the task is still active.
  /// If marked complete, all associated notifications are canceled.
  Future<void> updateTask(Task task) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        await _storage.saveTasks(_tasks);

        if (!task.isCompleted) {
          await _notifications.scheduleTaskNotifications(task);
        } else {
          await _notifications.cancelTaskNotifications(task);
        }

        await _refreshWidget();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Toggles the [Task.isCompleted] status of a task by its [id].
  ///
  /// Automatically handles notification cancellation/re-scheduling as needed.
  Future<void> toggleComplete(String id) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          isCompleted: !_tasks[index].isCompleted,
        );
        await _storage.saveTasks(_tasks);

        if (_tasks[index].isCompleted) {
          await _notifications.cancelTaskNotifications(_tasks[index]);
        } else {
          await _notifications.scheduleTaskNotifications(_tasks[index]);
        }

        await _refreshWidget();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Permanently deletes a task by its [id] and cancels all pending notifications.
  Future<void> deleteTask(String id) async {
    try {
      final taskIndex = _tasks.indexWhere((t) => t.id == id);
      if (taskIndex == -1) return;

      final task = _tasks[taskIndex];
      await _notifications.cancelTaskNotifications(task);
      _tasks.removeAt(taskIndex);

      await _storage.saveTasks(_tasks);
      await _refreshWidget();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Changes the [sortOption] and triggers a UI rebuild with the new ordering.
  void setSortOption(SortOptions option) {
    _sortOption = option;
    notifyListeners();
  }
}
