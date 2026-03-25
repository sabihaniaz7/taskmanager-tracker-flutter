import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskmanager/models/tracker.dart';
import 'package:taskmanager/services/notification_service.dart';
import 'package:taskmanager/utils/app_theme.dart';
import 'package:uuid/uuid.dart';

/// Manages the state and business logic for habit trackers.
///
/// This provider handles:
/// *   **Persistence**: Storing habit data using [SharedPreferences].
/// *   **Notifications**: Scheduling recurring daily reminders via [NotificationService].
/// *   **Widgets**: Triggering refreshes for the dedicated habit tracking widget.
/// *   **Statistics**: Managing completion dates and streak calculations (via [Tracker] model).
class TrackerProvider extends ChangeNotifier {
  /// Key used for storing tracking entries in [SharedPreferences].
  static const _storageKey = 'tracking_entries';

  /// Platform channel for updating the native habit tracking widget on Android.
  static const _widgetChannel = MethodChannel('com.example.taskmanager/widget');

  final _uuid = const Uuid();
  final _notifications = NotificationService();

  /// Internal source of truth for all habit trackers (active and archived).
  List<Tracker> _entries = [];

  /// Private state to track if data is currently being fetched from storage.
  bool _isLoading = false;

  /// Returns a list of active (non-archived) habit trackers.
  List<Tracker> get entries => _entries.where((t) => !t.isArchived).toList();

  /// Returns a list of habit trackers that have been moved to the archive.
  List<Tracker> get archivedEntries =>
      _entries.where((t) => t.isArchived).toList();

  /// Whether the provider is currently fetching data from [SharedPreferences].
  bool get isLoading => _isLoading;

  /// Requests the native platform to refresh the habit tracking home screen widget.
  Future<void> _refreshWidget() async {
    try {
      await _widgetChannel.invokeMethod('refreshTrackerWidget');
    } catch (_) {
      // Ignore if platform channel is unavailable (e.g., on iOS).
    }
  }

  /// Loads the habit tracking data from local persistence.
  ///
  /// Should be called during app initialization.
  Future<void> loadTrackingData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey) ?? [];
      _entries = list.map((s) => Tracker.fromJsonString(s)).toList();
    } catch (e) {
      // Error handled by UI via isLoading state
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Serializes and persists the current list of trackers to [SharedPreferences].
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _storageKey,
        _entries.map((t) => t.toJsonString()).toList(),
      );
      await _refreshWidget();
    } catch (e) {
      rethrow;
    }
  }

  /// Determines the next available color index from the theme palette.
  ///
  /// Attempts to pick a color that is not currently in use by other trackers
  /// to ensure visual distinctness in the dashboard.
  int _nextColorIndex() {
    if (_entries.isEmpty) return 0;
    final paletteSize = AppColors.cardPalette.length;
    final usedIndices = _entries.map((t) => t.colorIndex).toSet();
    for (int i = 0; i < paletteSize; i++) {
      if (!usedIndices.contains(i)) return i;
    }
    return (_entries.last.colorIndex + 1) % paletteSize;
  }

  /// Creates and adds a new habit tracker.
  ///
  /// *   Generates a unique notification ID (offset to avoid Task collisions).
  /// *   Schedules an optional daily reminder.
  /// *   Persists the new tracker to storage.
  Future<void> addEntry({
    required String title,
    String description = '',
    bool reminderEnabled = false,
    int reminderHour = 9,
    int reminderMinute = 0,
  }) async {
    try {
      // Generate a unique notification ID (starting from 200,000 to avoid collision with Tasks)
      final notifId = DateTime.now().millisecondsSinceEpoch % 100000 + 200000;

      final entry = Tracker(
        id: _uuid.v4(),
        title: title,
        description: description,
        colorIndex: _nextColorIndex(),
        startDate: DateTime.now(),
        reminderEnabled: reminderEnabled,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        notificationId: notifId,
      );

      _entries.add(entry);
      await _save();
      await _notifications.scheduleTrackerNotifications(entry);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Updates an existing tracker's configuration.
  ///
  /// Automatically re-schedules notifications if reminder settings have changed.
  Future<void> updateEntry(Tracker entry) async {
    try {
      final i = _entries.indexWhere((t) => t.id == entry.id);
      if (i != -1) {
        _entries[i] = entry;
        await _save();

        // Reschedule notifications to reflect potential changes in time or status.
        await _notifications.cancelTrackerNotifications(entry);
        await _notifications.scheduleTrackerNotifications(entry);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Toggles the completion status for a specific [date] on the specified tracker.
  ///
  /// This is the primary method for recording daily habit success.
  Future<void> toggleDate(String id, DateTime date) async {
    try {
      final i = _entries.indexWhere((t) => t.id == id);
      if (i != -1) {
        _entries[i].toggleDate(date);
        await _save();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Permanently removes a tracker and cancels all associated notifications.
  Future<void> deleteEntry(String id) async {
    try {
      final entryIndex = _entries.indexWhere((t) => t.id == id);
      if (entryIndex == -1) return;

      final entry = _entries[entryIndex];
      await _notifications.cancelTrackerNotifications(entry);
      _entries.removeAt(entryIndex);

      await _save();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Moves a tracker to the archive and cancels its active notifications.
  ///
  /// Archived trackers are preserved in storage but not shown in the primary dashboard.
  Future<void> archiveEntry(String id) async {
    try {
      final i = _entries.indexWhere((t) => t.id == id);
      if (i != -1) {
        await _notifications.cancelTrackerNotifications(_entries[i]);
        _entries[i] = _entries[i].copyWith(isArchived: true);
        await _save();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
}

