import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/day_log.dart';
import '../models/habit_log.dart';
import '../models/achievement_note.dart';
import '../services/hive_service.dart';
import '../constants/habits.dart';
import 'package:intl/intl.dart';
import '../widgets/morph_chip.dart';
import '../widgets/custom_habit_chip.dart';
import '../widgets/glass.dart';
import '../providers/user_prefs_provider.dart';
import '../providers/project_provider.dart';
import '../providers/custom_habit_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/user_stats_provider.dart';
import '../services/widget_service.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final allLogs = HiveService.getAllDayLogs();
    final achievementNotes = HiveService.getAllAchievementNotes();
    final streakState = ref.watch(streakProvider);
    final userStats = ref.watch(userStatsProvider);

    // Create a map of date -> dayLog for quick lookup
    final logsByDate = <String, DayLog>{};
    for (final log in allLogs) {
      final key = DateFormat('yyyy-MM-dd').format(log.date);
      logsByDate[key] = log;
    }

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
                'History',
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
          ),

          // Stat row right under the app bar
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.local_fire_department,
                    value: '${streakState.currentStreak}',
                    label: 'Current',
                    color: AppTokens.accent,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.emoji_events,
                    value: '${streakState.bestStreak}',
                    label: 'Best',
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.calendar_today,
                    value: '${userStats.totalDaysActive}',
                    label: 'Active',
                    color: const Color(0xFF4ECDC4),
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.check_circle_outline,
                    value: '${userStats.lifetimeHabitsCompleted}',
                    label: 'Habits',
                    color: const Color(0xFF5F9FED),
                  ),
                ],
              ),
            ),
          ),

          // Calendar Section
          SliverToBoxAdapter(
            child: _CalendarSection(
              selectedMonth: _selectedMonth,
              logsByDate: logsByDate,
              onMonthChanged: (month) => setState(() => _selectedMonth = month),
              onDayTap: (date) {
                final key = DateFormat('yyyy-MM-dd').format(date);
                final dayLog = logsByDate[key];
                if (dayLog != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditDayScreen(dayLog: dayLog),
                    ),
                  );
                } else {
                  // Create empty log for that date if in the past
                  if (date.isBefore(DateTime.now())) {
                    final newLog = DayLog.createEmpty(date);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditDayScreen(dayLog: newLog),
                      ),
                    );
                  }
                }
              },
            ),
          ),

          // Achievement Notes Section
          if (achievementNotes.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.emoji_events, color: Color(0xFFFF6B35), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Achievements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${achievementNotes.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: achievementNotes.take(10).length,
                  itemBuilder: (context, index) {
                    final note = achievementNotes[index];
                    return _AchievementCard(note: note);
                  },
                ),
              ),
            ),
          ],

          // Recent Days Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Day Log Cards
          allLogs.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 60,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No activity yet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dayLog = allLogs[index];
                      return _DayLogCard(
                        dayLog: dayLog,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditDayScreen(dayLog: dayLog),
                            ),
                          );
                        },
                      );
                    },
                    childCount: allLogs.length,
                  ),
                ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.rSm),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.18),
                  color.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTokens.rSm),
              border: Border.all(color: color.withOpacity(0.30), width: 1),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarSection extends StatelessWidget {
  final DateTime selectedMonth;
  final Map<String, DayLog> logsByDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDayTap;

  const _CalendarSection({
    required this.selectedMonth,
    required this.logsByDate,
    required this.onMonthChanged,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    return GlassCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      radius: AppTokens.rLg,
      child: Column(
        children: [
          // Month Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month - 1));
                },
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              Text(
                DateFormat('MMMM yyyy').format(selectedMonth),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: selectedMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month))
                    ? () {
                        onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month + 1));
                      }
                    : null,
                icon: Icon(
                  Icons.chevron_right,
                  color: selectedMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month))
                      ? Colors.white
                      : Colors.white24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => SizedBox(
                      width: 36,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startingWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startingWeekday) {
                return const SizedBox();
              }

              final day = index - startingWeekday + 1;
              final date = DateTime(selectedMonth.year, selectedMonth.month, day);
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final dayLog = logsByDate[dateKey];
              final isToday = _isToday(date);
              final isFuture = date.isAfter(DateTime.now());
              final habitCount = dayLog?.totalHabitsLogged ?? 0;

              return GestureDetector(
                onTap: isFuture ? null : () => onDayTap(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getHeatmapColor(habitCount, isFuture),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: const Color(0xFFFF6B35), width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isFuture
                            ? Colors.white24
                            : habitCount > 0
                                ? Colors.white
                                : Colors.white60,
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Legend
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: Colors.transparent, label: '0'),
              _LegendItem(color: Colors.green.withOpacity(0.3), label: '1-3'),
              _LegendItem(color: Colors.green.withOpacity(0.5), label: '4-6'),
              _LegendItem(color: Colors.green.withOpacity(0.7), label: '7-9'),
              _LegendItem(color: Colors.green, label: '10+'),
            ],
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Color _getHeatmapColor(int habitCount, bool isFuture) {
    if (isFuture) return Colors.white.withOpacity(0.05);
    if (habitCount == 0) return Colors.white.withOpacity(0.05);
    if (habitCount <= 3) return Colors.green.withOpacity(0.3);
    if (habitCount <= 6) return Colors.green.withOpacity(0.5);
    if (habitCount <= 9) return Colors.green.withOpacity(0.7);
    return Colors.green;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white24),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementNote note;

  const _AchievementCard({required this.note});

  Color _getCategoryColor(int category) {
    switch (category) {
      case 0:
        return Colors.purple;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      default:
        return Colors.pink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(note.category);

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(note.emoji, style: const TextStyle(fontSize: 24)),
              const Spacer(),
              Text(
                DateFormat('MMM d').format(note.date),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.note,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DayLogCard extends ConsumerWidget {
  final DayLog dayLog;
  final VoidCallback? onTap;

  const _DayLogCard({required this.dayLog, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customHabits = ref.watch(customHabitsProvider);
    final isToday = _isToday(dayLog.date);
    final isYesterday = _isYesterday(dayLog.date);
    final dateStr = isToday
        ? 'Today'
        : isYesterday
            ? 'Yesterday'
            : DateFormat('EEEE, MMM d').format(dayLog.date);

    final progressPercent = (dayLog.totalHabitsLogged / 11 * 100).clamp(0, 100).toInt();

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.zero,
      onTap: onTap,
      borderColor: isToday ? AppTokens.accent.withOpacity(0.55) : null,
      child: Column(
          children: [
            // Header with progress bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Date & Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: isToday ? const Color(0xFFFF6B35) : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: dayLog.totalHabitsLogged / 11,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(
                              _getProgressColor(dayLog.totalHabitsLogged),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Habit count circle
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getProgressColor(dayLog.totalHabitsLogged).withOpacity(0.2),
                      border: Border.all(
                        color: _getProgressColor(dayLog.totalHabitsLogged),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${dayLog.totalHabitsLogged}',
                          style: TextStyle(
                            color: _getProgressColor(dayLog.totalHabitsLogged),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'habits',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Completed habits row
            if (dayLog.totalHabitsLogged > 0)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _buildCompletedHabits(dayLog, customHabits),
                ),
              ),
          ],
        ),
    );
  }

  List<Widget> _buildCompletedHabits(DayLog dayLog, List customHabits) {
    final completed = <Widget>[];

    void addIfLogged(bool logged, HabitType type) {
      if (logged) {
        final info = habitDetails[type]!;
        completed.add(_MiniHabitBadge(
          icon: info.icon,
          color: info.color,
        ));
      }
    }

    addIfLogged(dayLog.meditation.logged, HabitType.meditation);
    addIfLogged(dayLog.serum.logged, HabitType.serum);
    addIfLogged(dayLog.coldShower.logged, HabitType.coldShower);
    addIfLogged(dayLog.jawGym.logged, HabitType.jawGym);
    addIfLogged(dayLog.chewQuest.logged, HabitType.chewQuest);
    addIfLogged(dayLog.protein.logged, HabitType.protein);
    addIfLogged(dayLog.study.logged, HabitType.study);
    addIfLogged(dayLog.chess.logged, HabitType.chess);
    addIfLogged(dayLog.cycling.logged, HabitType.cycling);
    addIfLogged(dayLog.buildStreak.logged, HabitType.buildStreak);
    addIfLogged(dayLog.madScientist.logged, HabitType.madScientist);

    // Custom habits
    if (dayLog.customHabits != null) {
      for (final entry in dayLog.customHabits!.entries) {
        if (entry.value.logged) {
          final habitIndex = customHabits.indexWhere((h) => h.id == entry.key);
          if (habitIndex != -1) {
            final habit = customHabits[habitIndex];
            completed.add(_MiniHabitBadge(
              icon: habit.icon,
              color: habit.color,
            ));
          }
        }
      }
    }

    return completed;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  Color _getProgressColor(int count) {
    if (count == 0) return Colors.grey;
    if (count < 3) return Colors.orange;
    if (count < 6) return Colors.amber;
    if (count < 9) return Colors.lightGreen;
    return Colors.green;
  }
}

class _MiniHabitBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MiniHabitBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

// Edit Day Screen
class EditDayScreen extends ConsumerStatefulWidget {
  final DayLog dayLog;
  final Future<void> Function(DayLog savedLog)? onSaveCallback;

  const EditDayScreen({
    Key? key,
    required this.dayLog,
    this.onSaveCallback,
  }) : super(key: key);

  @override
  ConsumerState<EditDayScreen> createState() => _EditDayScreenState();
}

class _EditDayScreenState extends ConsumerState<EditDayScreen> {
  late DayLog _editedDayLog;

  @override
  void initState() {
    super.initState();
    _editedDayLog = widget.dayLog;
  }

  void _updateHabit(String habitName, HabitLog habitLog) {
    setState(() {
      switch (habitName) {
        case 'meditation':
          _editedDayLog = _editedDayLog.copyWith(meditation: habitLog);
          break;
        case 'serum':
          _editedDayLog = _editedDayLog.copyWith(serum: habitLog);
          break;
        case 'coldShower':
          _editedDayLog = _editedDayLog.copyWith(coldShower: habitLog);
          break;
        case 'jawGym':
          _editedDayLog = _editedDayLog.copyWith(jawGym: habitLog);
          break;
        case 'chewQuest':
          _editedDayLog = _editedDayLog.copyWith(chewQuest: habitLog);
          break;
        case 'protein':
          _editedDayLog = _editedDayLog.copyWith(protein: habitLog);
          break;
        case 'study':
          _editedDayLog = _editedDayLog.copyWith(study: habitLog);
          break;
        case 'chess':
          _editedDayLog = _editedDayLog.copyWith(chess: habitLog);
          break;
        case 'cycling':
          _editedDayLog = _editedDayLog.copyWith(cycling: habitLog);
          break;
        case 'buildStreak':
          _editedDayLog = _editedDayLog.copyWith(buildStreak: habitLog);
          break;
        case 'madScientist':
          _editedDayLog = _editedDayLog.copyWith(madScientist: habitLog);
          break;
        default:
          // Handle custom habits
          final customHabits = Map<String, HabitLog>.from(_editedDayLog.customHabits ?? {});
          customHabits[habitName] = habitLog;
          _editedDayLog = _editedDayLog.copyWith(customHabits: customHabits);
      }
    });
  }

  Future<void> _saveChanges() async {
    await HiveService.saveDayLog(_editedDayLog);

    // Update widget if editing today's log
    final today = DateTime.now();
    final isEditingToday = _editedDayLog.date.year == today.year &&
        _editedDayLog.date.month == today.month &&
        _editedDayLog.date.day == today.day;
    if (isEditingToday) {
      WidgetService.updateWidget();
    }

    // Call the callback if provided (e.g., for recovery flow)
    if (widget.onSaveCallback != null) {
      await widget.onSaveCallback!(_editedDayLog);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userPrefs = ref.watch(userPrefsProvider);
    final projects = ref.watch(projectsProvider);
    final customHabits = ref.watch(customHabitsProvider);
    final activeProjectNames = projects.where((p) => p.active).map((p) => p.name).toList();
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(_editedDayLog.date);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text('Edit $dateStr'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFFFF6B35)),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    '${_editedDayLog.totalHabitsLogged}/11',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _editedDayLog.totalHabitsLogged / 11,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B35)),
                        minHeight: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap any habit to toggle',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            MorphChip(
              habitType: HabitType.meditation,
              habitLog: _editedDayLog.meditation,
              onConfirm: (log) => _updateHabit('meditation', log),
              defaultDuration: userPrefs.meditationDefault,
            ),
            MorphChip(
              habitType: HabitType.serum,
              habitLog: _editedDayLog.serum,
              onConfirm: (log) => _updateHabit('serum', log),
            ),
            MorphChip(
              habitType: HabitType.coldShower,
              habitLog: _editedDayLog.coldShower,
              onConfirm: (log) => _updateHabit('coldShower', log),
            ),
            MorphChip(
              habitType: HabitType.jawGym,
              habitLog: _editedDayLog.jawGym,
              onConfirm: (log) => _updateHabit('jawGym', log),
            ),
            MorphChip(
              habitType: HabitType.chewQuest,
              habitLog: _editedDayLog.chewQuest,
              onConfirm: (log) => _updateHabit('chewQuest', log),
            ),
            MorphChip(
              habitType: HabitType.protein,
              habitLog: _editedDayLog.protein,
              onConfirm: (log) => _updateHabit('protein', log),
              proteinTarget: userPrefs.proteinTarget,
            ),
            MorphChip(
              habitType: HabitType.study,
              habitLog: _editedDayLog.study,
              onConfirm: (log) => _updateHabit('study', log),
              defaultDuration: userPrefs.studyDefault,
            ),
            MorphChip(
              habitType: HabitType.chess,
              habitLog: _editedDayLog.chess,
              onConfirm: (log) => _updateHabit('chess', log),
              defaultDuration: userPrefs.chessDefault,
            ),
            MorphChip(
              habitType: HabitType.cycling,
              habitLog: _editedDayLog.cycling,
              onConfirm: (log) => _updateHabit('cycling', log),
              defaultDuration: userPrefs.cyclingDefault,
            ),
            MorphChip(
              habitType: HabitType.buildStreak,
              habitLog: _editedDayLog.buildStreak,
              onConfirm: (log) => _updateHabit('buildStreak', log),
              availableProjects: activeProjectNames,
            ),
            MorphChip(
              habitType: HabitType.madScientist,
              habitLog: _editedDayLog.madScientist,
              onConfirm: (log) => _updateHabit('madScientist', log),
            ),
            // Add custom habits
            ...customHabits.map((customHabit) {
              final habitLog = _editedDayLog.customHabits?[customHabit.id] ?? HabitLog(logged: false);
              return CustomHabitChip(
                habit: customHabit,
                habitLog: habitLog,
                onConfirm: (log) => _updateHabit(customHabit.id, log),
              );
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
