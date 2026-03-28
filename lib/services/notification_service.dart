import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';

/// Service responsible for managing all local notifications in the application.
///
/// Handles initialization, permission requests, and complex scheduling logic for
/// both tasks and habit trackers.
class NotificationService {
  /// Singleton instance of the NotificationService.
  static final NotificationService _instance = NotificationService._internal();

  /// Factory constructor to return the singleton instance.
  factory NotificationService() => _instance;

  NotificationService._internal();

  /// Plugin instance for interacting with native notification systems.
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const MethodChannel _platformChannel = MethodChannel(
    'com.example.taskmanager/widget',
  );

  /// Key for persisting notification permission status.
  static const _permKey = 'notif_permission_granted';

  /// Internal state tracking whether notification permissions have been granted.
  bool _permissionGranted = false;

  /// Public getter for the permission status.
  bool get permissionGranted => _permissionGranted;

  /// Tracks whether the native notification plugin initialized successfully.
  bool _initialized = false;

  /// Ensures the timezone database has a safe local fallback.
  bool _timezoneConfigured = false;

  /// Initializes the notification service.
  ///
  /// Should be called exactly once from the `main()` function. Sets up timezones,
  /// plugin settings, and restores previously saved permission states.
  Future<void> init() async {
    await _configureTimezone();
    await _initializePlugin();
  }

  Future<void> _configureTimezone() async {
    tz.initializeTimeZones();
    try {
      final deviceTimeZone = await FlutterTimezone.getLocalTimezone();
      final identifier = deviceTimeZone.identifier;
      final resolved = identifier.isEmpty || identifier == 'Etc/Unknown'
          ? 'UTC'
          : identifier;
      tz.setLocalLocation(tz.getLocation(resolved));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _timezoneConfigured = true;
  }

  Future<void> _initializePlugin() async {
    try {
      const android = AndroidInitializationSettings(
        '@drawable/ic_notification',
      );
      const ios = DarwinInitializationSettings(
        requestAlertPermission:
            false, // We ask for permission contextually later.
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );
      _initialized = true;
    } catch (_) {
      _initialized = false;
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _permissionGranted = prefs.getBool(_permKey) ?? false;

      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        final granted = await androidImpl.areNotificationsEnabled() ?? false;
        _permissionGranted = granted;
        await prefs.setBool(_permKey, granted);
      }
    } catch (_) {
      // Leave the plugin usable even if restoring permission state fails.
    }
  }

  Future<bool> _ensureReady() async {
    if (!_timezoneConfigured) {
      await _configureTimezone();
    }
    if (!_initialized) {
      await _initializePlugin();
    }
    return _initialized;
  }

  /// Explicitly requests notification permissions from the user.
  ///
  /// Should be called at a contextual moment, like when creating a task.
  /// Returns `true` if permission was granted.
  Future<bool> requestPermission() async {
    if (!await _ensureReady()) return false;
    bool granted = false;

    // Request permissions on Android.
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final result = await androidImplementation
          .requestNotificationsPermission();
      granted = result ?? false;

      // Request exact alarm permission (Android 12+) for precise notification timing.
      try {
        await androidImplementation.requestExactAlarmsPermission();
      } catch (_) {
        // Ignore if permission is already granted or not applicable.
      }
    }

    // Request permissions on iOS.
    final iosImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImplementation != null) {
      final result = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = result ?? false;
    }

    _permissionGranted = granted;

    // Persist permission state to avoid re-asking unnecessarily.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permKey, granted);

    return granted;
  }

  Future<void> openNotificationSettings() async {
    try {
      await _platformChannel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  /// Schedules all relevant notifications for a specific [task].
  ///
  /// Includes an immediate creation confirmation and various reminders
  /// based on the task's [ReminderMode].
  Future<void> scheduleTaskNotifications(Task task) async {
    if (!await _ensureReady()) return;
    // Clear existing notifications for this task before rescheduling.
    await cancelTaskNotifications(task);

    if (!_permissionGranted) return;
    final now = DateTime.now();

    // ── Immediate Feedback Notification ──
    // Fires ~3 seconds after saving to confirm successful creation.
    final creationNotifyTime = now.add(const Duration(seconds: 3));

    await _scheduleNotification(
      id: task.notificationStartId,
      title: task.title,
      body: 'Due ${_formatDate(task.endDate)}',
      scheduledDate: creationNotifyTime,
    );

    if (task.reminderMode == ReminderMode.none) return;

    final h = task.reminderHour;
    final m = task.reminderMinute;

    switch (task.reminderMode) {
      case ReminderMode.onDueDate:
        // Single reminder at the specified time on the due date.
        final remind = DateTime(
          task.endDate.year,
          task.endDate.month,
          task.endDate.day,
          h,
          m,
        );
        if (remind.isAfter(now)) {
          await _scheduleNotification(
            id: task.notificationReminderId,
            title: task.title,
            body: 'Due Today!',
            scheduledDate: remind,
          );
        }
        break;

      case ReminderMode.onceDayBefore:
        // Single reminder 24 hours before the due date.
        final dayBefore = task.endDate.subtract(const Duration(days: 1));
        final remind = DateTime(
          dayBefore.year,
          dayBefore.month,
          dayBefore.day,
          h,
          m,
        );
        if (remind.isAfter(now)) {
          await _scheduleNotification(
            id: task.notificationReminderId,
            title: task.title,
            body: 'Due Tomorrow!',
            scheduledDate: remind,
          );
        }
        break;

      case ReminderMode.daily:
        // Repeating daily reminders from start until the due date.
        // Capped at 30 days to prevent ID exhaustion.
        final duration = task.endDate.difference(task.startDate).inDays;
        final days = duration.clamp(0, 30);
        for (int i = 0; i < days; i++) {
          final day = task.startDate.add(Duration(days: i));
          final remind = DateTime(day.year, day.month, day.day, h, m);
          if (remind.isAfter(now)) {
            await _scheduleNotification(
              id: task.notificationReminderId + i,
              title: task.title,
              body: i == days
                  ? 'Due today!'
                  : 'Due ${_formatDate(task.endDate)}.',
              scheduledDate: remind,
            );
          }
        }
        break;

      case ReminderMode.customDays:
        // Single reminder a custom number of days before the due date.
        final daysBefore = task.customDaysBefore.clamp(1, 365);
        final targetDay = task.endDate.subtract(Duration(days: daysBefore));
        final remind = DateTime(
          targetDay.year,
          targetDay.month,
          targetDay.day,
          h,
          m,
        );
        if (remind.isAfter(now)) {
          await _scheduleNotification(
            id: task.notificationReminderId,
            title: task.title,
            body:
                'Due in $daysBefore day${daysBefore > 1 ? "s" : ""} on ${_formatDate(task.endDate)}.',
            scheduledDate: remind,
          );
        }
        break;

      case ReminderMode.none:
        break;
    }
  }

  /// Helper to format dates for notification body text (e.g., "15 Mar").
  String _formatDate(DateTime d) {
    const months = [
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
    return '${d.day} ${months[d.month - 1]}';
  }

  /// Low-level method to queue a notification in the native system.
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        // TZDateTime handles timezones and DST transitions automatically.
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_manager_channel',
            'Trak',
            channelDescription: 'Task & Goals reminders and notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // Catching scheduling failures (e.g., if permission revoked).
    }
  }

  /// Cancels all notifications scheduled for a specific [task].
  Future<void> cancelTaskNotifications(Task task) async {
    if (!_initialized) return;
    await _plugin.cancel(id: task.notificationStartId);
    // Cancel any daily reminder IDs that might have been queued.
    for (int i = 0; i <= 30; i++) {
      await _plugin.cancel(id: task.notificationReminderId + i);
    }
  }

  // ═══════════════════════════════════════════════════════
  // TRACKER NOTIFICATIONS
  // ═══════════════════════════════════════════════════════

  /// Schedules daily notifications for a habit [tracker].
  ///
  /// Includes a 3-second creation confirmation and up to 30 upcoming
  /// daily reminders at the user's preferred time.
  Future<void> scheduleTrackerNotifications(dynamic tracker) async {
    if (!await _ensureReady()) return;
    await cancelTrackerNotifications(tracker);
    if (!_permissionGranted) return;

    final now = DateTime.now();
    final id = tracker.notificationId as int;

    // ── Immediate Creation Confirmation ──
    await _scheduleNotification(
      id: id,
      title: tracker.title,
      body: 'Tracking starts today!',
      scheduledDate: now.add(const Duration(seconds: 3)),
    );

    if (!(tracker.reminderEnabled as bool)) return;

    final h = tracker.reminderHour as int;
    final m = tracker.reminderMinute as int;

    // ── Queue next 30 daily reminders ──
    const messages = [
      'Time to get started!',
      "Don't forget to track your goal!",
      'Time to log your progress!',
      'Stay consistent!',
      "Let's do it now!",
      'Keep building your progress!',
      'Stay on track!',
      'Consistency is key!',
      'Ready to record your achievement today?',
      'Check in with your goal!',
    ];
    final random = Random();
    int scheduledCount = 0;
    for (int i = 0; scheduledCount < 30; i++) {
      final day = now.add(Duration(days: i));
      final remind = DateTime(day.year, day.month, day.day, h, m);
      if (remind.isAfter(now)) {
        await _scheduleNotification(
          id: id + 1 + scheduledCount,
          title: tracker.title,
          body: messages.isNotEmpty
              ? messages[random.nextInt(messages.length)]
              : 'Time to work on your goal!',
          scheduledDate: remind,
        );
        scheduledCount++;
      }
    }
  }

  /// Cancels all scheduled notifications for a specific [tracker].
  Future<void> cancelTrackerNotifications(dynamic tracker) async {
    if (!_initialized) return;
    final id = tracker.notificationId as int;
    await _plugin.cancel(id: id);
    for (int i = 1; i <= 30; i++) {
      await _plugin.cancel(id: id + i);
    }
  }
}
