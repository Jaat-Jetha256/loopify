import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_prefs_provider.dart';
import '../models/user_prefs.dart';
import '../widgets/glass.dart';
import 'manage_habits_screen.dart';
import 'backup_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPrefs = ref.watch(userPrefsProvider);
    final prefsNotifier = ref.read(userPrefsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: AppBar(
              backgroundColor: AppTokens.bgDeep.withOpacity(0.4),
              title: const Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                ),
              ),
              centerTitle: false,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          16,
          GlassTabBarSpacer.height,
        ),
        children: [
          // Daily Goals Section
          const Text(
            'Daily Goals',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(8),
            radius: AppTokens.rMd,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Protein Target', style: TextStyle(color: Colors.white)),
                  subtitle: Text('${userPrefs.proteinTarget}g', style: const TextStyle(color: Colors.white54)),
                  trailing: DropdownButton<int>(
                    value: userPrefs.proteinTarget,
                    dropdownColor: const Color(0xFF1D1E33),
                    style: const TextStyle(color: Colors.white),
                    items: [80, 100, 120, 150].map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text('${value}g'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) prefsNotifier.setProteinTarget(value);
                    },
                  ),
                ),
                _buildDurationPicker(
                  'Meditation Default',
                  userPrefs.meditationDefault,
                  (val) => prefsNotifier.updatePrefs(userPrefs.copyWith(meditationDefault: val)),
                ),
                _buildDurationPicker(
                  'Study Default',
                  userPrefs.studyDefault,
                  (val) => prefsNotifier.updatePrefs(userPrefs.copyWith(studyDefault: val)),
                ),
                _buildDurationPicker(
                  'Chess Default',
                  userPrefs.chessDefault,
                  (val) => prefsNotifier.updatePrefs(userPrefs.copyWith(chessDefault: val)),
                ),
                _buildDurationPicker(
                  'Cycling Default',
                  userPrefs.cyclingDefault,
                  (val) => prefsNotifier.updatePrefs(userPrefs.copyWith(cyclingDefault: val)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Streak Mode Section
          const Text(
            'Streak Requirements',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(8),
            radius: AppTokens.rMd,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Strict Mode', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    userPrefs.strictStreakMode ? '≥3 habits required' : '≥1 habit required',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  value: userPrefs.strictStreakMode,
                  activeColor: Colors.orange,
                  onChanged: (val) => prefsNotifier.setStrictMode(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Preferences Section
          const Text(
            'App Preferences',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(8),
            radius: AppTokens.rMd,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Haptic Feedback', style: TextStyle(color: Colors.white)),
                  value: userPrefs.hapticsEnabled,
                  activeColor: Colors.orange,
                  onChanged: (_) => prefsNotifier.toggleHaptics(),
                ),
                SwitchListTile(
                  title: const Text('Notifications', style: TextStyle(color: Colors.white)),
                  value: userPrefs.notificationsEnabled,
                  activeColor: Colors.orange,
                  onChanged: (_) => prefsNotifier.toggleNotifications(),
                ),
                if (userPrefs.notificationsEnabled) ...[
                  const Divider(color: Colors.white24),
                  ListTile(
                    title: const Text('Daily Reminder Time', style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      _formatTime(userPrefs.reminderHour, userPrefs.reminderMinute),
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: const Icon(Icons.schedule, color: Colors.orange),
                    onTap: () => _selectReminderTime(context, ref, userPrefs),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Custom Habits Section
          const Text(
            'Custom Habits',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            radius: AppTokens.rMd,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFFFF6B35),
                  size: 24,
                ),
              ),
              title: const Text(
                'Manage Custom Habits',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Edit, enable/disable, or delete your custom habits',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageHabitsScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Backup & Restore Section
          const Text(
            'Backup & Restore',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            radius: AppTokens.rMd,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cloud_sync,
                  color: Colors.cyanAccent,
                  size: 24,
                ),
              ),
              title: const Text(
                'Backup & Restore',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Export all data to Gmail/Drive/Files. Import on another device — streak, habits, projects, everything.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackupScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          GlassCard(
            padding: const EdgeInsets.all(20),
            radius: AppTokens.rMd,
            child: const Column(
              children: [
                Text(
                  'Loopify',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.accent,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Track tiny wins. Build unstoppable momentum.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
                SizedBox(height: 8),
                Text(
                  'v1.0.0',
                  style: TextStyle(color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPicker(String label, int value, Function(int) onChanged) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Text('$value min', style: const TextStyle(color: Colors.white54)),
      trailing: DropdownButton<int>(
        value: value,
        dropdownColor: const Color(0xFF1D1E33),
        style: const TextStyle(color: Colors.white),
        items: [5, 10, 15, 20, 30, 45, 60, 90].map((val) {
          return DropdownMenuItem(
            value: val,
            child: Text('$val min'),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  Future<void> _selectReminderTime(BuildContext context, WidgetRef ref, UserPrefs userPrefs) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: userPrefs.reminderHour, minute: userPrefs.reminderMinute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Color(0xFF1D1E33),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1D1E33),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await ref.read(userPrefsProvider.notifier).setReminderTime(picked.hour, picked.minute);
    }
  }
}
