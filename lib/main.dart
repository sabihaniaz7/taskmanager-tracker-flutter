import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskmanager/providers/task_provider.dart';
import 'package:taskmanager/providers/tracker_provider.dart';
import 'package:taskmanager/screens/splash_screen.dart';
import 'package:taskmanager/services/notification_service.dart';
import 'package:taskmanager/utils/app_theme.dart';

/// The entry point of the application.
///
/// Initializes services, loads settings, and sets up the application's root providers.
void main() async {
  // Ensure that widget binding is initialized before service initialization.
  WidgetsFlutterBinding.ensureInitialized();

  // Do not let plugin startup failures block the first frame in release.
  try {
    await NotificationService().init();
  } catch (_) {}

  ThemeMode saved = ThemeMode.system;
  try {
    saved = await ThemeModeNotifier.load();
  } catch (_) {}

  runApp(
    MultiProvider(
      providers: [
        // Provider for managing tasks.
        ChangeNotifierProvider(create: (_) => TaskProvider()..loadTasks()),
        // Provider for managing habit tracking data.
        ChangeNotifierProvider(
          create: (_) => TrackerProvider()..loadTrackingData(),
        ),
        // Provider for managing application theme mode (Light/Dark).
        ChangeNotifierProvider(create: (_) => ThemeModeNotifier(saved)),
      ],
      child: const TaskManagerApp(),
    ),
  );
}

/// The root widget of the Trak application.
///
/// Configures the overall application theme, title, and initial route.
class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the theme notifier for changes to rebuild the app when theme mode changes.
    final themeNotifier = context.watch<ThemeModeNotifier>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trak',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.mode,
      builder: (context, child) {
        // Resolve actual brightness for AnimatedTheme to provide smooth transitions.
        final brightness = themeNotifier.mode == ThemeMode.system
            ? MediaQuery.platformBrightnessOf(context)
            : themeNotifier.mode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light;

        return AnimatedTheme(
          data: brightness == Brightness.dark
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
