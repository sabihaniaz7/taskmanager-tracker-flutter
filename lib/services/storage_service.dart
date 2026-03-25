import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskmanager/models/task.dart';

/// Service responsible for persistent storage of task data.
///
/// Uses [SharedPreferences] to store and retrieve task lists in JSON format.
class StorageService {
  /// Storage key for the task list.
  static const String _tasksKey = 'tasks';

  /// Loads the list of tasks from local storage.
  ///
  /// Returns an empty list if no tasks are found.
  Future<List<Task>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> tasksStrings = prefs.getStringList(_tasksKey) ?? [];
      return tasksStrings
          .map((taskString) => Task.fromJsonString(taskString))
          .toList();
    } catch (e) {
      // Return empty list to prevent crash; error handled by consumer if needed
      return [];
    }
  }

  /// Saves the provided list of [tasks] to local storage.
  Future<void> saveTasks(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskStrings = tasks.map((task) => task.toJsonString()).toList();
      await prefs.setStringList(_tasksKey, taskStrings);
    } catch (e) {
      rethrow; // Rethrow to let provider handle UI feedback
    }
  }
}
