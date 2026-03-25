import 'dart:convert';

import 'package:flutter/material.dart';

/// Defines the scheduling behavior for task reminders.
enum ReminderMode {
  /// No reminder will be set for the task.
  none,

  /// A one-time reminder scheduled for the day before the due date.
  onceDayBefore,

  /// A reminder scheduled for the exact due date.
  onDueDate,

  /// Reminders scheduled daily from the start date until the end date.
  daily,

  /// A reminder scheduled a specific number of days before the due date.
  customDays,
}

/// Represents a task in the application.
///
/// Contains information about the task's title, duration, completion status,
/// and reminder settings.
class Task {
  /// Unique identifier for the task.
  final String id;

  /// The title or name of the task.
  String title;

  /// An optional detailed description of the task.
  String description;

  /// The date when the task is scheduled to start.
  DateTime startDate;

  /// The date when the task is scheduled to be completed.
  DateTime endDate;

  /// The timestamp when the task was first created.
  DateTime createdAt;

  /// Whether the task has been marked as completed.
  bool isCompleted;

  /// Index for identifying the color associated with this task in the UI.
  int colorIndex;

  /// Notification ID used for the start date notification.
  int notificationStartId;

  /// Notification ID used for the reminder notification.
  int notificationReminderId;

  // Reminder fields--------------------------------

  /// The mode determining how and when reminders are sent.
  ReminderMode reminderMode;

  /// The hour (0-23) at which the reminder should be triggered.
  int reminderHour;

  /// The minute (0-59) at which the reminder should be triggered.
  int reminderMinute;

  /// Number of days before the due date for [ReminderMode.customDays].
  int customDaysBefore;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.isCompleted = false,
    this.colorIndex = 0,
    this.notificationStartId = 0,
    this.notificationReminderId = 0,
    this.reminderMode = ReminderMode.none,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.customDaysBefore = 1,
  });

  /// Returns true if the task is not completed and the current time is past the end date.
  bool get isOverdue {
    final now = DateTime.now();
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return !isCompleted && now.isAfter(end);
  }

  /// Returns true if the task starts and ends on the same calendar day.
  bool get isSingleDay =>
      startDate.year == endDate.year &&
      startDate.month == endDate.month &&
      startDate.day == endDate.day;

  /// Returns the reminder time as a [TimeOfDay] object.
  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderHour, minute: reminderMinute);

  /// Creates a copy of this task with the given fields replaced by new values.
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    bool? isCompleted,
    int? colorIndex,
    int? notificationStartId,
    int? notificationReminderId,
    ReminderMode? reminderMode,
    int? reminderHour,
    int? reminderMinute,
    int? customDaysBefore,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      colorIndex: colorIndex ?? this.colorIndex,
      notificationStartId: notificationStartId ?? this.notificationStartId,
      notificationReminderId:
          notificationReminderId ?? this.notificationReminderId,
      reminderMode: reminderMode ?? this.reminderMode,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      customDaysBefore: customDaysBefore ?? this.customDaysBefore,
    );
  }

  /// Converts the [Task] object to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'isCompleted': isCompleted,
    'colorIndex': colorIndex,
    'notificationStartId': notificationStartId,
    'notificationReminderId': notificationReminderId,
    'reminderMode': reminderMode.index,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'customDaysBefore': customDaysBefore,
  };

  /// Creates a [Task] object from a JSON map.
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    createdAt: DateTime.parse(json['createdAt']),
    isCompleted: json['isCompleted'] ?? false,
    colorIndex: json['colorIndex'] ?? 0,
    notificationStartId: json['notificationStartId'] ?? 0,
    notificationReminderId: json['notificationReminderId'] ?? 0,
    reminderMode: ReminderMode.values[json['reminderMode'] ?? 0],
    reminderHour: json['reminderHour'] ?? 9,
    reminderMinute: json['reminderMinute'] ?? 0,
    customDaysBefore: json['customDaysBefore'] ?? 1,
  );

  /// Encodes the [Task] object into a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Decodes a JSON string into a [Task] object.
  factory Task.fromJsonString(String s) => Task.fromJson(jsonDecode(s));
}
