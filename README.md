# ✦ Trak

A premium Flutter productivity app — task management & habit tracking in one place

Built with clean architecture using `provider` for state management, smart reminders, swipeable home screen widgets, and a polished dark/light UI.

![Flutter](https://img.shields.io/badge/Flutter-3.38.6-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10.7-0175C2?style=flat-square&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-6.0+%20(API%2023+)-3DDC84?style=flat-square&logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

> [!IMPORTANT]
> Although the codebase is written for both Android and iOS, the app has currently only been tested on Android.

---

## Preview

<!-- markdownlint-disable MD033 -->
| | |
| :---: | :---: |
| **Add Task (Dark)** | **Add Task (Light)** |
| <img src="images/addDark.png" width="270" alt="Add Task Dark Mode"> | <img src="images/addLight.png" width="270" alt="Add Task Light Mode"> |
| **Reminder System** | |
| <img src="images/reminder.png" width="270" alt="Reminder System"> | |
<!-- markdownlint-enable MD033 -->

---

## Features

### Task Management

- Create tasks with title, description (optional), and date range
- **Task Detail Screen** — full info view with animated mark complete, progress bar, days remaining
- **Overdue detection** — automatic badge when past due date
- **Sort options** — by start date, end date, created date, or overdue first
- **Tabs** — All / Active / Completed views
- **Swipe gestures** — swipe right to complete, swipe left to delete

### Habit Tracker

- Create daily habits/trackers with title, optional description and reminder time.
- **Connected calendar** — done days shown as filled circles linked by a bar (streak visualization)
- **Swipeable monthly calendar** — swipe left/right to browse months
- **7-day strip** on each card showing current week at a glance
- **Streak counter** — live current streak + total done/total days stats
- **Sort options** — newest, highest streak, best completion rate
- **Swipe to delete** trackers

### Smart Notifications

- **Tasks** — 4 reminder modes: on due day, day before, daily, or custom X days before
- **Trackers** — daily check-in reminder at your chosen time
- Creation confirmation notification (3 sec after saving)
- Notifications auto-cancelled on delete/archive

### Home Screen Widgets

- **Task Widget** — shows active task title + due date, navigate with `‹` `›`
- **Tracker Widget** — shows tracker title + today's status (✅/⭕) + 🔥 streak, navigate with `‹` `›`
- Both widgets refresh instantly after any change (no delay)
- Added via Android widget picker independently

### UI & Theming

- **Dark / Light mode** toggle — smooth animated transition
- **Color-coded cards** — 7 pastel colors auto-assigned uniquely
- **Colored card shadows** — depth that matches each card's accent color
- **Splash screen** — branded entry with subtle glow animation
- **Shared animated header** — title morphs between "Task Manager" / "Tracker"
- **Swipeable navigation** — PageView between Tasks and Tracker screens
- All colors, sizes, radii centralized in `app_theme.dart` — zero hardcoding

---

## Architecture

```dart
lib/
├── main.dart                        # Entry point + ThemeModeNotifier + providers
├── models/
│   ├── task.dart                    # Task model + ReminderMode enum
│   └── tracker.dart                 # Tracker model + streak/calendar logic
├── providers/
│   ├── task_provider.dart           # Task state + widget refresh channel
│   └── tracker_provider.dart        # Tracker state + notifications + widget refresh
├── screens/
│   ├── splash_screen.dart           # Animated splash screen
│   ├── main_screen.dart             # PageView + shared header + bottom nav
│   ├── home_screen.dart             # Task tabs (All / Active / Completed)
│   ├── tracker_screen.dart          # Tracker list with sort
│   ├── task_detail_screen.dart      # Task detail — complete, progress, info
│   ├── tracker_detail_screen.dart   # Tracker detail — connected calendar
│   ├── add_task_screen.dart         # Create task form
│   ├── edit_task_screen.dart        # Edit task form
│   ├── add_habit_screen.dart        # Create tracker form
│   └── edit_tracker_screen.dart     # Edit tracker form
├── services/
│   ├── notification_service.dart    # Task + tracker notification scheduling
│   └── storage_service.dart         # SharedPreferences helpers
├── utils/
│   ├── app_theme.dart               # All colors, sizes, themes
│   └── date_helper.dart             # Date formatting helpers
└── widgets/
    ├── task_card.dart               # Clean task card — tap to detail, swipe gestures
    ├── tracker_card.dart            # Tracker card — 7-day strip, swipe to archive/delete
    └── reminder_section.dart        # Reusable reminder picker UI

android/app/src/main/
├── kotlin/.../
│   ├── MainActivity.kt              # MethodChannel — refreshes both widgets
│   ├── TaskWidgetProvider.kt        # Task home screen widget
│   └── TrackerWidgetProvider.kt     # Tracker home screen widget
└── res/
    ├── layout/
    │   ├── task_widget.xml          # Task widget layout
    │   └── tracker_widget.xml       # Tracker widget layout
    ├── xml/
    │   ├── task_widget_info.xml     # Task widget metadata
    │   └── tracker_widget_info.xml  # Tracker widget metadata
    └── drawable/
        ├── ic_chevron_left.xml      # Custom ‹ arrow
        └── ic_chevron_right.xml     # Custom › arrow
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0` (Used 3.10.7)
- Android Studio or VS Code
- Android device / emulator (Android 6.0+ / API 23+)

### Installation

#### 1. Clone the repo

```bash
git clone https://github.com/sabihaniaz7/Task-Manager-Flutter.git
cd taskmanager
```

#### 2. Install dependencies

```bash
flutter pub get
```

#### 3. Run the app

```bash
flutter run
```

---

## Dependencies

| Package | Version | Purpose |
| --- | --- | --- |
| `provider` | ^6.1.5+1 | State management |
| `shared_preferences` | ^2.5.4 | Local data persistence |
| `flutter_local_notifications` | ^20.1.0 | Scheduled notifications |
| `flutter_timezone` | ^5.0.1 | Device timezone detection |
| `timezone` | ^0.10.1 | Timezone-aware scheduling |
| `uuid` | ^4.5.3 | Unique task IDs |
| `intl` | ^0.20.2 | Date formatting |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

---

## Notification System

### Tasks

| Trigger | Notification |
| --- | --- |
| Task created | Confirmation after 3 seconds |
| Single-day — on due day | Reminder at chosen time on due day |
| Multi-day — day before | Reminder at chosen time, 1 day before end |
| Multi-day — daily | Every day from start to due at chosen time |
| Multi-day — custom | X days before due at chosen time |

### Trackers

| Trigger | Notification |
| --------- | ------------- |
| Tracker created | Confirmation after 3 seconds |
| Reminder enabled | Daily check-in at chosen time (30 days scheduled ahead) |

> Notifications are automatically cancelled on delete or archive.

---

## Android Widgets

Two independent widgets — add each from your Android widget picker.

> **Note:** These custom widgets are currently only tested and supported on Android.

| Widget | Shows | Navigation |
| -------- | ------- | ----------- |
| **Task Widget** | Task title + due date | `‹` `›` to browse active tasks |
| **Tracker Widget** | Tracker name + today status + streak | `‹` `›` to browse trackers |

Both update instantly when you make changes in the app via a direct `MethodChannel` push — no polling delay.

Tapping the widget opens the app directly.

---

## Design System

All design tokens live in `lib/utils/app_theme.dart`:

```dart
// 7 pastel card color palette (assigned uniquely to trackers/tasks)
AppColors.cardPalette 
// #D8ECFF, #FFF3C4, #EAE8FF, #DDF5E8, #FFEDD8, #F0E0FF, #D8F5F2

// Light theme colors
AppColors.lightBg       // #F2F3F7 (Background)
AppColors.lightSurface  // #FFFFFF (Surface)
AppColors.lightPrimary  // #1C1C2E (Text/Action)
AppColors.lightSubtext  // #9098A8 (Captions)

// Dark theme colors
AppColors.darkBg        // #0F0F18 (Background)
AppColors.darkSurface   // #1A1A28 (Surface)
AppColors.darkPrimary   // #F0F0FF (Text/Action)
AppColors.darkSubtext   // #70728A (Captions)
```

> All colors, font sizes, spacing, and border radii are defined centrally in `app_theme.dart` — nothing is hardcoded in widgets. The app supports both light and dark themes with smooth animated transitions.

---

## License

```text
MIT License — free to use, modify, and distribute.
```

---

## Built With

- [Flutter](https://flutter.dev)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [provider](https://pub.dev/packages/provider)

---

Made with ❤️ using Flutter. By Sabiha Niaz
