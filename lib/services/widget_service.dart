import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:math' as math;
import '../constants/habits.dart';
import 'hive_service.dart';

class WidgetService {
  static const String _widgetName = 'LoopifyWidget';
  static const MethodChannel _iosBridge = MethodChannel('loopify/widget');

  /// Update the home screen widget with current progress
  static Future<void> updateWidget() async {
    try {
      // Ensure app group is set every time — cheap and idempotent.
      // Protects against cases where initWidget() ran in a different isolate
      // or before the iOS plugin's static groupId was populated.
      await HomeWidget.setAppGroupId('group.com.loopify.loopify');

      final streakState = HiveService.getStreakState();
      final streak = streakState.currentStreak;

      // Get today's habits completed count
      final today = DateTime.now();
      final dayLog = HiveService.getDayLogByDate(today);
      final habitsCompleted = dayLog?.totalHabitsLogged ?? 0;

      print('📱 Widget Update: Streak=$streak, Habits=$habitsCompleted');

      // Determine which image and quip to use based on habits completed
      String imageName;
      String quip;

      if (habitsCompleted < 3) {
        // 0-2 habits: START quips
        imageName = '1.png';
        quip = widgetStartQuips[math.Random().nextInt(widgetStartQuips.length)];
      } else if (habitsCompleted >= 3 && habitsCompleted <= 5) {
        // 3-5 habits: KEEP GOING quips
        imageName = '2.png';
        quip = widgetKeepGoingQuips[math.Random().nextInt(widgetKeepGoingQuips.length)];
      } else {
        // 6+ habits: UNSTOPPABLE quips
        imageName = '3.png';
        quip = widgetUnstoppableQuips[math.Random().nextInt(widgetUnstoppableQuips.length)];
      }

      print('📱 Widget Image: $imageName, Quip: $quip');

      final lastUpdate = DateTime.now().toIso8601String();

      // Save data to widget (UserDefaults app-group on iOS, SharedPreferences on Android)
      await HomeWidget.saveWidgetData<int>('streak', streak);
      await HomeWidget.saveWidgetData<int>('habits_completed', habitsCompleted);
      await HomeWidget.saveWidgetData<String>('quip', quip);
      await HomeWidget.saveWidgetData<String>('image', imageName);
      await HomeWidget.saveWidgetData<String>('last_update', lastUpdate);

      // iOS: also mirror data into the keychain. iLoader strips app-group
      // entitlements on free certs, so UserDefaults sharing fails; keychain
      // sharing via the app-id-prefix group survives the re-sign.
      if (Platform.isIOS) {
        try {
          await _iosBridge.invokeMethod('sync', {
            'streak': streak,
            'habits_completed': habitsCompleted,
            'quip': quip,
            'image': imageName,
            'last_update': lastUpdate,
          });
        } catch (e) {
          print('iOS keychain bridge error: $e');
        }
      }

      print('📱 Data saved to HomeWidget');

      // Update the widget
      await HomeWidget.updateWidget(
        androidName: _widgetName,
        iOSName: _widgetName,
      );

      print('📱 Widget update requested');
    } catch (e) {
      print('❌ Error updating widget: $e');
    }
  }

  /// Initialize widget on app launch
  static Future<void> initWidget() async {
    try {
      await HomeWidget.setAppGroupId('group.com.loopify.loopify');
      await updateWidget();
    } catch (e) {
      print('Error initializing widget: $e');
    }
  }
}
