import 'dart:convert';

/// Represents a habit or recurring activity that the user wants to track daily.
/// Handles logic for completion tracking, streak calculations, and data serialization.
/// A [Tracker] maintains a list of dates on which the habit was successfully completed.
class Tracker {
  /// Unique identifier for the tracker.
  final String id;

  /// The name or title of the habit/task.
  String title;

  /// An optional detailed description of the habit.
  String description;

  /// Index to map to a specific theme color from the [AppTheme].
  int colorIndex;

  /// The date when tracking for this habit first began.
  DateTime startDate;

  /// Whether local notifications are enabled for this habit.
  bool reminderEnabled;

  /// Hour (0-23) at which the daily reminder notification should be triggered.
  int reminderHour;

  /// Minute (0-59) at which the daily reminder notification should be triggered.
  int reminderMinute;

  /// Whether the tracker is archived (hidden from the active view).
  bool isArchived;

  /// List of completed dates stored as strings in 'yyyy-MM-dd' format.
  List<String> completedDates;

  /// Unique notification ID used for scheduling local notifications for this tracker.
  int notificationId;

  Tracker({
    required this.id,
    required this.title,
    this.description = '',
    required this.colorIndex,
    required this.startDate,
    this.reminderEnabled = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.isArchived = false,
    List<String>? completedDates,
    this.notificationId = 0,
  }) : completedDates = completedDates ?? [];

  // -----------Date Key Helpers-----------

  /// Formats a [DateTime] into a standard key string ('yyyy-MM-dd') used for storage.
  ///
  /// This ensures consistent date comparison regardless of time components.
  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Checks if the habit was marked as completed on a specific [date].
  bool isDayOn(DateTime date) => completedDates.contains(dateKey(date));

  /// Checks if the habit is already marked as completed for today.
  bool get isDoneToday => isDayOn(DateTime.now());

  // ── Streak: done / total days since start ────────────
  // total = days elapsed since startDate (including today)
  // done  = how many of those days are marked complete
  int get totalDays {
    final now = DateTime.now();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(start).inDays + 1;
  }

  /// The total count of unique days the habit was successfully completed.
  int get doneDays => completedDates.length;

  /// Calculates the current consecutive completion streak ending today or yesterday.
  ///
  /// A streak is active if today is completed, or if yesterday was completed and today is not yet over.
  int get currentStreak {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < totalDays; i++) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      if (isDayOn(day)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ── UI Data Helpers ───────────────────────────────────

  /// Generates data for the last 7 days for condensed card previews.
  ///
  /// Returns a list of maps, each containing:
  /// - 'date': the [DateTime] for that day.
  /// - 'done': whether it's marked as complete.
  /// - 'isBeforeStart': whether the date is before the tracking [startDate].
  /// - 'isFuture': whether the date is after the current time.
  List<Map<String, dynamic>> get last7Days {
    final now = DateTime.now();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return List.generate(7, (i) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final isBeforeStart = day.isBefore(start);
      return {
        'date': day,
        'done': isDayOn(day),
        'isBeforeStart': isBeforeStart,
        'isFuture': day.isAfter(DateTime.now()),
      };
    });
  }

  /// Generates a full list of all days from the [startDate] up to today.
  ///
  /// Used for detailed calendar views. Clamped to a maximum of 365 days.
  List<Map<String, dynamic>> get calendarDays {
    final now = DateTime.now();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(start).inDays + 1;
    return List.generate(days.clamp(0, 365), (i) {
      final day = start.add(Duration(days: i));
      return {'date': day, 'done': isDayOn(day), 'isToday': day == today};
    });
  }

  /// Toggles the completion status for a specific [date].
  ///
  /// Adds the date if missing, or removes it if already present.
  void toggleDate(DateTime date) {
    final key = dateKey(date);
    if (completedDates.contains(key)) {
      completedDates.remove(key);
    } else {
      completedDates.add(key);
    }
  }

  /// Returns a new [Tracker] instance with updated fields.
  Tracker copyWith({
    String? id,
    String? title,
    String? description,
    int? colorIndex,
    DateTime? startDate,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? isArchived,
    List<String>? completedDates,
    int? notificationId,
  }) {
    return Tracker(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      colorIndex: colorIndex ?? this.colorIndex,
      startDate: startDate ?? this.startDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isArchived: isArchived ?? this.isArchived,
      completedDates: completedDates ?? List.from(this.completedDates),
      notificationId: notificationId ?? this.notificationId,
    );
  }

  // ── Serialization ──────────────────────────────────────

  /// Converts the [Tracker] instance into a JSON-compatible map for persistence.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'colorIndex': colorIndex,
    'startDate': startDate.toIso8601String(),
    'reminderEnabled': reminderEnabled,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'isArchived': isArchived,
    'completedDates': completedDates,
    'notificationId': notificationId,
  };

  /// Creates a [Tracker] instance from a JSON map.
  factory Tracker.fromJson(Map<String, dynamic> json) => Tracker(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    colorIndex: json['colorIndex'] ?? 0,
    startDate: DateTime.parse(json['startDate']),
    reminderEnabled: json['reminderEnabled'] ?? false,
    reminderHour: json['reminderHour'] ?? 9,
    reminderMinute: json['reminderMinute'] ?? 0,
    isArchived: json['isArchived'] ?? false,
    completedDates: List<String>.from(json['completedDates'] ?? []),
    notificationId: json['notificationId'] ?? 0,
  );

  /// Encodes the [Tracker] instance into a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Decodes a JSON string into a [Tracker] object.
  factory Tracker.fromJsonString(String s) => Tracker.fromJson(jsonDecode(s));
}
