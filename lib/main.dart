import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'services/hive_service.dart';
import 'services/widget_service.dart';
import 'services/midnight_service.dart';
import 'services/notification_service.dart';
import 'services/challenge_service.dart';
import 'screens/main_screen.dart';
import 'widgets/glass.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize timezone database for scheduled notifications
    tz.initializeTimeZones();

    // Try to get local timezone, fallback to UTC if fails
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // India timezone
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }
  } catch (e) {
    print('Timezone initialization error: $e');
  }

  await HiveService.init();
  await WidgetService.initWidget();

  // Initialize notification service
  try {
    await NotificationService.initialize();

    // Schedule notifications if enabled
    final userPrefs = HiveService.getUserPrefs();
    if (userPrefs.notificationsEnabled) {
      await NotificationService.scheduleEveningReminder(
        hour: userPrefs.reminderHour,
        minute: userPrefs.reminderMinute,
      );
      await NotificationService.scheduleMidnightCheck();
    }

    // Always reschedule active challenge notifications on startup
    // (these are independent of the general notifications toggle)
    await ChallengeService.rescheduleAllNotifications();
  } catch (e) {
    print('Notification initialization error: $e');
  }

  // Initialize midnight monitoring service
  MidnightService.initialize();

  // Edge-to-edge system UI with transparent bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  runApp(const ProviderScope(child: LoopifyApp()));
}

class LoopifyApp extends StatelessWidget {
  const LoopifyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loopify',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const MainScreen(),
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      primaryColor: AppTokens.accent,
      scaffoldBackgroundColor: AppTokens.bgDeep,
      canvasColor: AppTokens.bgMid,
      splashFactory: InkRipple.splashFactory,
      colorScheme: ColorScheme.dark(
        primary: AppTokens.accent,
        secondary: AppTokens.accentSoft,
        surface: AppTokens.bgMid,
        background: AppTokens.bgDeep,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          )
          .copyWith(
            displayLarge: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
            displayMedium: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
            headlineMedium: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
            titleLarge: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            titleMedium: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
            bodyLarge: TextStyle(
              color: Colors.white,
              letterSpacing: -0.1,
            ),
            bodyMedium: TextStyle(
              color: Colors.white.withOpacity(0.78),
              letterSpacing: -0.1,
            ),
            labelLarge: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
      iconTheme: const IconThemeData(color: Colors.white),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.08),
        thickness: 0.6,
        space: 0.6,
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rMd)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTokens.bgHigh,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rSm)),
        elevation: 4,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppTokens.bgHigh,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rMd)),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        contentTextStyle: TextStyle(
          color: Colors.white.withOpacity(0.78),
          fontSize: 14,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: const BorderSide(color: AppTokens.accent, width: 1.6),
        ),
      ),
    );
  }
}
