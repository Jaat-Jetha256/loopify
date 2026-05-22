import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../constants/habits.dart';
import '../models/day_log.dart';
import '../providers/day_log_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/user_prefs_provider.dart';
import '../providers/project_provider.dart';
import '../providers/custom_habit_provider.dart';
import '../providers/user_stats_provider.dart';
import '../widgets/modern_habit_card.dart';
import '../widgets/modern_progress_ring.dart';
import '../widgets/modern_custom_habit_card.dart';
import '../widgets/gradient_box_border.dart';
import '../widgets/firebar.dart';
import '../widgets/midnight_countdown.dart';
import '../widgets/milestone_modal.dart';
import '../widgets/add_custom_habit_dialog.dart';
import '../widgets/cold_streak_banner.dart';
import '../widgets/streak_obituary_modal.dart';
import '../widgets/achievement_modal.dart';
import '../widgets/achievement_note_dialog.dart';
import '../widgets/glass.dart';
import '../models/habit_log.dart';
import '../services/streak_service.dart';
import '../services/widget_service.dart';
import '../services/midnight_service.dart';
import '../services/hive_service.dart';
import '../services/achievement_service.dart';
import '../services/recovery_service.dart';
import '../services/challenge_service.dart';
import '../services/notification_service.dart';
import '../providers/challenge_provider.dart';
import '../widgets/set_challenge_dialog.dart';
import '../widgets/challenge_deadline_modal.dart';
import '../widgets/active_challenges_banner.dart';
import 'manage_habits_screen.dart';
import 'history_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  late ConfettiController _confettiController;
  int _lastHabitCount = 0;
  DateTime _lastCheckedDate = DateTime.now();
  RecoveryEligibility? _recoveryEligibility;
  bool _isRecoveryInProgress = false;
  final List<String> _pendingDeadlineModals = [];
  bool _isShowingDeadlineModal = false;
  bool _hasShownPermissionPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 700));
    _lastCheckedDate = DateTime.now();
    _checkStreakOnInit();
    _setupMidnightCallback();
    _checkRecoveryEligibility();
    _initChallengeService();
    _checkNotificationPermissions();
  }

  void _checkRecoveryEligibility() {
    setState(() {
      _recoveryEligibility = RecoveryService.checkEligibility();
    });
  }

  void _handleRecovery() async {
    if (_recoveryEligibility == null || !_recoveryEligibility!.isEligible) return;
    if (_isRecoveryInProgress) return; // Guard against multiple calls

    final yesterday = _recoveryEligibility!.yesterday!;
    final brokenStreak = _recoveryEligibility!.brokenStreakValue ?? 0;
    final userPrefs = ref.read(userPrefsProvider);

    // Get or create yesterday's log
    DayLog yesterdayLog = HiveService.getDayLogByDate(yesterday) ??
        DayLog.createEmpty(yesterday);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditDayScreen(
            dayLog: yesterdayLog,
            onSaveCallback: (savedLog) async {
              // Guard against multiple callback executions
              if (_isRecoveryInProgress) return;
              _isRecoveryInProgress = true;

              // Execute recovery after saving
              final success = await RecoveryService.executeRecovery(
                savedLog,
                userPrefs.strictStreakMode,
              );

              if (success && mounted) {
                // Reload providers
                ref.read(streakProvider.notifier).reload();
                ref.read(userStatsProvider.notifier).reload();

                // Clear recovery eligibility
                _checkRecoveryEligibility();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Streak recovered! You\'re back to ${brokenStreak + 1} days!',
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );

                // Play confetti
                _confettiController.play();
              } else if (!success && mounted) {
                final requiredHabits = userPrefs.strictStreakMode ? 3 : 1;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Recovery failed. Log at least $requiredHabits habit${requiredHabits > 1 ? 's' : ''} for yesterday.',
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
                // Reset the guard so user can retry
                _isRecoveryInProgress = false;
              }
            },
          ),
        ),
      );
    }
  }

  void _setupMidnightCallback() {
    // Re-initialize midnight service with callback to this screen
    MidnightService.initialize(onMidnight: _handleMidnightRollover);
  }

  void _handleMidnightRollover() async {
    if (mounted) {
      debugPrint('HomeScreen: Midnight rollover detected, refreshing UI');

      final statsNotifier = ref.read(userStatsProvider.notifier);
      final userPrefs = ref.read(userPrefsProvider);

      // Check yesterday's completion before resetting
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayLog = HiveService.getDayLogByDate(yesterday);
      final requiredHabits = userPrefs.strictStreakMode ? 3 : 1;

      if (yesterdayLog == null || yesterdayLog.totalHabitsLogged < requiredHabits) {
        // Failed yesterday - increment cold streak
        await statsNotifier.incrementColdStreak();
      } else {
        // Succeeded yesterday - reset cold streak
        await statsNotifier.resetColdStreak();
        await statsNotifier.incrementDaysActive();
      }

      // Reset the day log provider for the new day
      final dayLogNotifier = ref.read(currentDayLogProvider.notifier);
      dayLogNotifier.resetForNewDay();

      // Recalculate streak (with break detection)
      final result = await StreakService.calculateStreakWithResult(userPrefs.strictStreakMode);
      ref.read(streakProvider.notifier).updateState(result.state);

      // Show streak obituary if broken
      if (result.streakBroken && result.brokenStreakValue > 0 && mounted) {
        // Record the streak break
        await statsNotifier.recordStreakBreak(
          result.brokenStreakValue,
          result.breakDate ?? DateTime.now(),
        );

        // Calculate days to next milestone
        final nextMilestone = _getNextMilestone(result.brokenStreakValue);
        final daysAway = nextMilestone - result.brokenStreakValue;

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            StreakObituaryModal.show(
              context,
              result.brokenStreakValue,
              result.breakDate ?? DateTime.now(),
              daysAway,
              _getMilestoneName(nextMilestone),
            );
          }
        });
      }

      // Expire old challenges
      ref.read(challengeProvider.notifier).expireOldChallenges();

      // Update widget
      WidgetService.updateWidget();

      // Force UI rebuild
      setState(() {
        _lastCheckedDate = DateTime.now();
      });
    }
  }

  int _getNextMilestone(int currentStreak) {
    const milestones = [3, 7, 21, 30, 50, 100, 365];
    for (final milestone in milestones) {
      if (currentStreak < milestone) return milestone;
    }
    return 365;
  }

  String _getMilestoneName(int milestone) {
    switch (milestone) {
      case 3: return 'Spark Ignited';
      case 7: return 'First Flame';
      case 21: return 'Habit Forged';
      case 30: return 'Month Warrior';
      case 50: return 'Iron Will';
      case 100: return 'Centurion';
      case 365: return 'Legend';
      default: return 'Next Level';
    }
  }

  void _checkStreakOnInit() async {
    // Run async to avoid blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userPrefs = ref.read(userPrefsProvider);
      final statsNotifier = ref.read(userStatsProvider.notifier);

      // Use calculateStreakWithResult to detect streak breaks
      final result = await StreakService.calculateStreakWithResult(userPrefs.strictStreakMode);

      // Update the streak provider with the new state
      final streakNotifier = ref.read(streakProvider.notifier);
      streakNotifier.updateState(result.state);

      // Record streak break if it happened
      if (result.streakBroken && result.brokenStreakValue > 0) {
        await statsNotifier.recordStreakBreak(
          result.brokenStreakValue,
          result.breakDate ?? DateTime.now(),
        );
      }

      // Always check recovery eligibility after streak calculation
      _checkRecoveryEligibility();

      if (mounted) {
        setState(() {});
      }
    });
  }

  void _checkForDayChange() {
    // Check if day has changed since last check
    if (MidnightService.hasCrossedMidnight(_lastCheckedDate)) {
      debugPrint('HomeScreen: Day change detected via manual check');
      _handleMidnightRollover();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ChallengeService.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _hasShownPermissionPrompt = false;
      _checkNotificationPermissions();
      _checkMissedChallengeDeadlines();
    }
  }

  void _initChallengeService() {
    ChallengeService.initialize(
      onDeadlineReached: (challenge) {
        if (!_pendingDeadlineModals.contains(challenge.id)) {
          _pendingDeadlineModals.add(challenge.id);
          _showNextDeadlineModal();
        }
      },
    );

    // Handle notification tap when app is in background
    NotificationService.onChallengeNotificationTapped = (challengeId) {
      if (!_pendingDeadlineModals.contains(challengeId)) {
        _pendingDeadlineModals.add(challengeId);
      }
      _showNextDeadlineModal();
    };

    // Handle notification tap that cold-launched the app (app was killed)
    NotificationService.getLaunchChallengeId().then((challengeId) {
      if (challengeId != null && !_pendingDeadlineModals.contains(challengeId)) {
        _pendingDeadlineModals.add(challengeId);
        _showNextDeadlineModal();
      }
    });
  }

  void _checkNotificationPermissions() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final userPrefs = ref.read(userPrefsProvider);
      if (!userPrefs.notificationsEnabled) return;

      final allGranted = await NotificationService.checkAndRequestPermissions();

      if (allGranted) {
        // Permissions OK — reschedule any challenge notifications that may have
        // silently failed before the permission was granted.
        await ChallengeService.rescheduleAllNotifications();
        return;
      }

      if (_hasShownPermissionPrompt || !mounted) return;
      _hasShownPermissionPrompt = true;

      // Determine what's missing
      final notifEnabled = await NotificationService.areNotificationsEnabled();
      if (!notifEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission denied. Enable it in system settings for reminders.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        // Notification permission granted but exact alarms not allowed
        _showExactAlarmPermissionDialog();
      }
    });
  }

  void _showExactAlarmPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.alarm, color: Colors.orange, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Allow Exact Alarms',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: const Text(
          'Loopify needs the "Alarms & Reminders" permission to notify you when challenge deadlines arrive.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('LATER', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationService.openExactAlarmSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OPEN SETTINGS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _checkMissedChallengeDeadlines() {
    final missed = ChallengeService.checkMissedDeadlines();
    for (final challenge in missed) {
      if (!_pendingDeadlineModals.contains(challenge.id)) {
        _pendingDeadlineModals.add(challenge.id);
      }
    }
    _showNextDeadlineModal();
  }

  void _showNextDeadlineModal() {
    if (_isShowingDeadlineModal || _pendingDeadlineModals.isEmpty || !mounted) return;

    _isShowingDeadlineModal = true;
    final challengeId = _pendingDeadlineModals.removeAt(0);

    // Reload challenge from Hive to get latest state
    final challenge = HiveService.getChallenge(challengeId);
    if (challenge == null || !challenge.isActive || challenge.isSnoozed) {
      _isShowingDeadlineModal = false;
      _showNextDeadlineModal();
      return;
    }

    ChallengeDeadlineModal.show(
      context,
      challenge: challenge,
      onComplete: (saveChoice) {
        _handleChallengeComplete(challenge, saveChoice);
        _isShowingDeadlineModal = false;
        Future.delayed(const Duration(milliseconds: 500), _showNextDeadlineModal);
      },
      onSnooze: (minutes) {
        ref.read(challengeProvider.notifier).snoozeChallenge(challenge.id, minutes);
        _isShowingDeadlineModal = false;
        Future.delayed(const Duration(milliseconds: 300), _showNextDeadlineModal);
      },
      onCancel: () {
        ref.read(challengeProvider.notifier).cancelChallenge(challenge.id);
        _isShowingDeadlineModal = false;
        Future.delayed(const Duration(milliseconds: 300), _showNextDeadlineModal);
      },
    );
  }

  void _handleChallengeComplete(challenge, int saveChoice) {
    ref.read(challengeProvider.notifier).completeChallenge(challenge.id, saveChoice);

    if (saveChoice == 1 && challenge.habitName != 'custom_challenge') {
      // Log as habit (only for actual habits, not freeform challenges)
      final notifier = ref.read(currentDayLogProvider.notifier);
      notifier.updateHabit(challenge.habitName, HabitLog(logged: true));

      // Update streak and widget
      final userPrefs = ref.read(userPrefsProvider);
      final currentCount = ref.read(currentDayLogProvider).totalHabitsLogged;
      StreakService.checkTodayProgress(currentCount, userPrefs.strictStreakMode);
      ref.read(streakProvider.notifier).reload();
      WidgetService.updateWidget();
    } else if (saveChoice == 2 || (saveChoice == 1 && challenge.habitName == 'custom_challenge')) {
      // Save as badge
      final badgeId = 'challenge_${challenge.habitName}_${DateTime.now().millisecondsSinceEpoch}';
      ref.read(userStatsProvider.notifier).unlockBadge(badgeId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saveChoice == 1
                ? '${challenge.habitDisplayName} logged!'
                : '${challenge.habitDisplayName} badge earned!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onHabitConfirm(HabitType habitType, HabitLog habitLog) async {
    final notifier = ref.read(currentDayLogProvider.notifier);
    final habitName = habitType.toString().split('.').last;
    final userPrefs = ref.read(userPrefsProvider);
    final streakState = ref.read(streakProvider);
    final oldStreak = streakState.currentStreak;
    final statsNotifier = ref.read(userStatsProvider.notifier);

    notifier.updateHabit(habitName, habitLog);

    // Track lifetime habit
    if (habitLog.logged) {
      await statsNotifier.incrementLifetimeHabits();
    }

    // Trigger confetti on first habit of the day
    final currentCount = ref.read(currentDayLogProvider).totalHabitsLogged;
    if (_lastHabitCount == 0 && currentCount == 1) {
      _confettiController.play();
    }
    _lastHabitCount = currentCount;

    // Check if streak should increment
    await StreakService.checkTodayProgress(currentCount, userPrefs.strictStreakMode);

    // Reload streak provider to reflect any changes
    ref.read(streakProvider.notifier).reload();

    // Check for milestone
    final newStreakState = ref.read(streakProvider);
    final milestone = StreakService.getMilestoneToShow(oldStreak, newStreakState.currentStreak);
    if (milestone != null && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          MilestoneModal.show(context, milestone);
        }
      });
    }

    // Check for achievement unlocks
    final currentStats = ref.read(userStatsProvider);
    AchievementService.checkAndUnlock(
      context,
      ref,
      currentStats,
      newStreakState.currentStreak,
    );

    // Update home screen widget
    WidgetService.updateWidget();

    // Show success toast with humorous messages for >5 habits
    final info = habitDetails[habitType]!;

    String message;
    if (currentCount > 5) {
      message = completionQuips[math.Random().nextInt(completionQuips.length)];
    } else {
      message = '${info.name} logged. Flame lit.';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: info.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for day change on every rebuild (lightweight check)
    _checkForDayChange();

    final dayLog = ref.watch(currentDayLogProvider);
    final streakState = ref.watch(streakProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final projects = ref.watch(projectsProvider);
    final activeProjectNames = projects.where((p) => p.active).map((p) => p.name).toList();
    final customHabits = ref.watch(activeCustomHabitsProvider);

    _lastHabitCount = dayLog.totalHabitsLogged;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              children: [
                const _HomeHeader(),
                // Midnight Countdown (only shows after 10 PM)
                const MidnightCountdown(),
                // Cold Streak Banner (shows when failing)
                ColdStreakBanner(
                  coldStreak: ref.watch(userStatsProvider).coldStreak,
                  onTap: () {
                    // Show analytics screen or motivation message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Get back on track! Complete habits today.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
                // Recovery Card (shows when streak just broke and can be recovered)
                if (_recoveryEligibility != null && _recoveryEligibility!.isEligible)
                  _RecoveryCard(
                    brokenStreak: _recoveryEligibility!.brokenStreakValue!,
                    tokensRemaining: ref.watch(userStatsProvider).streakRecoveryTokens,
                    onRecover: _handleRecovery,
                  ),
                // Today Card - Calculate total from visible default + active custom habits
                Builder(
                  builder: (context) {
                    // Count visible default habits (11 total - hidden ones)
                    final visibleDefaultHabits = HabitType.values.length - userPrefs.hiddenHabits.length;
                    // Add active custom habits
                    final totalHabits = visibleDefaultHabits + customHabits.length;
                    return ModernProgressRing(
                      current: dayLog.totalHabitsLogged,
                      total: totalHabits,
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Action row — Achievement + Challenge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _GlassActionTile(
                          emoji: '🏆',
                          label: 'Achievement',
                          accent: AppTokens.accent,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showDialog(
                              context: context,
                              builder: (context) => const AchievementNoteDialog(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GlassActionTile(
                          icon: Icons.timer_outlined,
                          label: 'Challenge',
                          accent: const Color(0xFFAB47BC),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            SetChallengeDialog.show(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Active Challenges Banner
                const ActiveChallengesBanner(),
                const SizedBox(height: 16),
                // Streak Firebar
                Firebar(
                  streakCount: streakState.currentStreak,
                  milestoneLabel: streakState.milestoneLabel,
                  gracePassesUsed: streakState.gracePassesUsedThisWeek,
                  totalGracePasses: 1,
                ),
                const SizedBox(height: 24),
                // Habit Cards (filtered by visibility)
                if (!userPrefs.hiddenHabits.contains('meditation'))
                  LoopifyHabitCard(
                    habitType: HabitType.meditation,
                    habitLog: dayLog.meditation,
                    onConfirm: (log) => _onHabitConfirm(HabitType.meditation, log),
                    defaultDuration: userPrefs.meditationDefault,
                  ),
                if (!userPrefs.hiddenHabits.contains('serum'))
                  LoopifyHabitCard(
                    habitType: HabitType.serum,
                    habitLog: dayLog.serum,
                    onConfirm: (log) => _onHabitConfirm(HabitType.serum, log),
                  ),
                if (!userPrefs.hiddenHabits.contains('coldShower'))
                  LoopifyHabitCard(
                    habitType: HabitType.coldShower,
                    habitLog: dayLog.coldShower,
                    onConfirm: (log) => _onHabitConfirm(HabitType.coldShower, log),
                  ),
                if (!userPrefs.hiddenHabits.contains('jawGym'))
                  LoopifyHabitCard(
                    habitType: HabitType.jawGym,
                    habitLog: dayLog.jawGym,
                    onConfirm: (log) => _onHabitConfirm(HabitType.jawGym, log),
                  ),
                if (!userPrefs.hiddenHabits.contains('chewQuest'))
                  LoopifyHabitCard(
                    habitType: HabitType.chewQuest,
                    habitLog: dayLog.chewQuest,
                    onConfirm: (log) => _onHabitConfirm(HabitType.chewQuest, log),
                  ),
                if (!userPrefs.hiddenHabits.contains('protein'))
                  LoopifyHabitCard(
                    habitType: HabitType.protein,
                    habitLog: dayLog.protein,
                    onConfirm: (log) => _onHabitConfirm(HabitType.protein, log),
                    proteinTarget: userPrefs.proteinTarget,
                  ),
                if (!userPrefs.hiddenHabits.contains('study'))
                  LoopifyHabitCard(
                    habitType: HabitType.study,
                    habitLog: dayLog.study,
                  onConfirm: (log) => _onHabitConfirm(HabitType.study, log),
                  defaultDuration: userPrefs.studyDefault,
                ),
                if (!userPrefs.hiddenHabits.contains('chess'))
                  LoopifyHabitCard(
                    habitType: HabitType.chess,
                    habitLog: dayLog.chess,
                    onConfirm: (log) => _onHabitConfirm(HabitType.chess, log),
                    defaultDuration: userPrefs.chessDefault,
                  ),
                if (!userPrefs.hiddenHabits.contains('cycling'))
                  LoopifyHabitCard(
                    habitType: HabitType.cycling,
                    habitLog: dayLog.cycling,
                    onConfirm: (log) => _onHabitConfirm(HabitType.cycling, log),
                    defaultDuration: userPrefs.cyclingDefault,
                  ),
                if (!userPrefs.hiddenHabits.contains('buildStreak'))
                  LoopifyHabitCard(
                    habitType: HabitType.buildStreak,
                    habitLog: dayLog.buildStreak,
                    onConfirm: (log) => _onHabitConfirm(HabitType.buildStreak, log),
                    availableProjects: activeProjectNames,
                  ),
                if (!userPrefs.hiddenHabits.contains('madScientist'))
                  LoopifyHabitCard(
                    habitType: HabitType.madScientist,
                    habitLog: dayLog.madScientist,
                    onConfirm: (log) => _onHabitConfirm(HabitType.madScientist, log),
                  ),
                // Custom Habits
                ...customHabits.map((customHabit) {
                  final habitLog = dayLog.customHabits?[customHabit.id] ?? HabitLog(logged: false);
                  return ModernCustomHabitCard(
                    habit: customHabit,
                    habitLog: habitLog,
                    onConfirm: (log) async {
                      final notifier = ref.read(currentDayLogProvider.notifier);
                      final userPrefs = ref.read(userPrefsProvider);
                      final streakState = ref.read(streakProvider);
                      final oldStreak = streakState.currentStreak;

                      notifier.updateHabit(customHabit.id, log);

                      // Trigger confetti on first habit of the day
                      final currentCount = ref.read(currentDayLogProvider).totalHabitsLogged;
                      if (_lastHabitCount == 0 && currentCount == 1) {
                        _confettiController.play();
                      }
                      _lastHabitCount = currentCount;

                      // Check if streak should increment
                      await StreakService.checkTodayProgress(currentCount, userPrefs.strictStreakMode);

                      // Reload streak provider to reflect any changes
                      ref.read(streakProvider.notifier).reload();

                      // Check for milestone
                      final newStreakState = ref.read(streakProvider);
                      final milestone = StreakService.getMilestoneToShow(oldStreak, newStreakState.currentStreak);
                      if (milestone != null && mounted) {
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            MilestoneModal.show(context, milestone);
                          }
                        });
                      }

                      // Check for achievement unlocks
                      final currentStats = ref.read(userStatsProvider);
                      AchievementService.checkAndUnlock(
                        context,
                        ref,
                        currentStats,
                        newStreakState.currentStreak,
                      );

                      // Update home screen widget
                      WidgetService.updateWidget();

                      // Show success toast
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${customHabit.name} logged! 🎯'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: customHabit.color,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  );
                }),
                // Add Custom Habit Button - Glass design
                GestureDetector(
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageHabitsScreen(),
                      ),
                    );
                  },
                  child: AccentGlassCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    padding: const EdgeInsets.all(16),
                    radius: AppTokens.rLg,
                    accent: AppTokens.accent,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddCustomHabitDialog(),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTokens.accent.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTokens.accent.withOpacity(0.45),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppTokens.accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add Custom Habit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Long press to manage',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 11,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppTokens.accent.withOpacity(0.6),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
                const GlassTabBarSpacer(),
              ],
            ),
          ),
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 15,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                Colors.amber,
                Colors.orange,
                Colors.pink,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final int brokenStreak;
  final int tokensRemaining;
  final VoidCallback onRecover;

  const _RecoveryCard({
    required this.brokenStreak,
    required this.tokensRemaining,
    required this.onRecover,
  });

  @override
  Widget build(BuildContext context) {
    return AccentGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      radius: AppTokens.rMd,
      accent: Colors.amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.replay_rounded,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECOVER YESTERDAY',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your $brokenStreak-day streak can be saved!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Fill in yesterday\'s habits to restore your streak.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.toll,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$tokensRemaining token${tokensRemaining > 1 ? 's' : ''} left',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onRecover,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'RECOVER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Late night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppTokens.accent,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassActionTile extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _GlassActionTile({
    this.emoji,
    this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AccentGlassCard(
      accent: accent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      radius: AppTokens.rMd,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (emoji != null)
            Text(emoji!, style: const TextStyle(fontSize: 20))
          else if (icon != null)
            Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
