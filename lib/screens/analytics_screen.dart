import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_stats.dart';
import '../providers/user_stats_provider.dart';
import '../services/analytics_service.dart';
import '../services/hive_service.dart';
import '../widgets/habit_heatmap.dart';
import '../widgets/weekly_report_modal.dart';
import '../widgets/glass.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedTimeRange = '7days';

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(userStatsProvider);

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
                'Analytics',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          16,
          GlassTabBarSpacer.height,
        ),
        child: Column(
          children: [
            // Performance Overview Card
            _buildPerformanceOverview(stats),
            const SizedBox(height: 16),

            // Time Range Selector
            _buildTimeRangeSelector(),
            const SizedBox(height: 16),

            // Streak vs Goals Comparison
            _buildStreakComparison(),
            const SizedBox(height: 16),

            // Weekly Report Button
            _buildWeeklyReportButton(context),
            const SizedBox(height: 16),

            // Stats Grid
            _buildStatsGrid(stats),
            const SizedBox(height: 16),

            // Streak Breaks History
            _buildStreakBreaksSection(stats),
            const SizedBox(height: 16),

            // Heatmap Calendar
            const HabitHeatmap(days: 90),
            const SizedBox(height: 16),

            // Best/Worst Days
            _buildBestWorstDays(),
            const SizedBox(height: 16),

            // Best/Worst Habits
            _buildBestWorstHabits(),
            const SizedBox(height: 16),

            // Habit Correlations
            _buildHabitCorrelations(),
            const SizedBox(height: 16),

            // Recommended Features
            _buildRecommendedFeatures(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedFeatures(UserStats stats) {
    // Generate personalized recommendations based on stats
    List<Map<String, dynamic>> recommendations = [];

    // Recommendation 1: If success rate is low, suggest setting reminders
    if (stats.successRate < 60) {
      recommendations.add({
        'icon': Icons.notifications_active,
        'color': Colors.orange,
        'title': 'Enable Daily Reminders',
        'description': 'Set up notifications to stay on track',
      });
    }

    // Recommendation 2: If they have streak breaks, suggest streak freeze
    if (stats.totalStreakBreaks > 3) {
      recommendations.add({
        'icon': Icons.ac_unit,
        'color': Colors.blue,
        'title': 'Use Streak Freeze',
        'description': 'Protect your streak on tough days',
      });
    }

    // Recommendation 3: Always suggest custom habits if few are active
    recommendations.add({
      'icon': Icons.add_task,
      'color': Colors.green,
      'title': 'Add Custom Habits',
      'description': 'Track more personalized goals',
    });

    // Recommendation 4: If success rate is good, suggest harder challenges
    if (stats.successRate >= 70) {
      recommendations.add({
        'icon': Icons.trending_up,
        'color': Colors.purple,
        'title': 'Enable Strict Mode',
        'description': 'Require 3+ habits daily for streaks',
      });
    }

    // Recommendation 5: Suggest achievement tracking
    recommendations.add({
      'icon': Icons.emoji_events,
      'color': Colors.amber,
      'title': 'Track Achievements',
      'description': 'Log your wins and milestones',
    });

    return GlassCard(
      padding: const EdgeInsets.all(20),
      radius: AppTokens.rMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              SizedBox(width: 12),
              Text(
                'Recommended For You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.take(4).map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRecommendationCard(
                  rec['icon'] as IconData,
                  rec['color'] as Color,
                  rec['title'] as String,
                  rec['description'] as String,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(IconData icon, Color color, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 20),
        ],
      ),
    );
  }

  Widget _buildWeeklyReportButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final reportData = await AnalyticsService.getWeeklyReport();
        if (context.mounted) {
          WeeklyReportModal.show(
            context,
            grade: reportData['grade'],
            weeklySuccessRate: reportData['successRate'],
            totalHabitsThisWeek: reportData['totalHabits'],
            daysActiveThisWeek: reportData['daysActive'],
            bestDay: reportData['bestDay'],
            worstDay: reportData['worstDay'],
            topHabits: reportData['topHabits'],
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6B46C1),
              Color(0xFF553C9A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B46C1).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text(
              'VIEW WEEKLY REPORT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview(UserStats stats) {
    final successRate = stats.successRate;
    final performanceLevel = _getPerformanceLevel(successRate);
    final levelColor = _getPerformanceLevelColor(successRate);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            levelColor.withValues(alpha: 0.2),
            const Color(0xFF1D1E33),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: levelColor.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    performanceLevel,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: levelColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getMotivationalMessage(successRate),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getPerformanceIcon(successRate),
                  color: levelColor,
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  '${successRate.toStringAsFixed(1)}%',
                  'Completion',
                  Icons.check_circle_outline,
                  levelColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  '${stats.totalDaysActive}',
                  'Days Active',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  '${stats.lifetimeHabitsCompleted}',
                  'Total Habits',
                  Icons.emoji_events,
                  Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getPerformanceLevel(double rate) {
    if (rate >= 80) return 'LEGENDARY';
    if (rate >= 60) return 'CRUSHING IT';
    if (rate >= 40) return 'BUILDING UP';
    if (rate >= 20) return 'GETTING STARTED';
    return 'RISE UP';
  }

  Color _getPerformanceLevelColor(double rate) {
    if (rate >= 80) return const Color(0xFFFFD700); // Gold
    if (rate >= 60) return Colors.green;
    if (rate >= 40) return Colors.blue;
    if (rate >= 20) return Colors.orange;
    return Colors.red;
  }

  IconData _getPerformanceIcon(double rate) {
    if (rate >= 80) return Icons.military_tech;
    if (rate >= 60) return Icons.local_fire_department;
    if (rate >= 40) return Icons.trending_up;
    if (rate >= 20) return Icons.show_chart;
    return Icons.fitness_center;
  }

  String _getMotivationalMessage(double rate) {
    if (rate >= 80) return 'Elite performance! Keep dominating!';
    if (rate >= 60) return 'Strong work! You\'re on fire!';
    if (rate >= 40) return 'Good momentum! Keep pushing!';
    if (rate >= 20) return 'Building habits! Stay consistent!';
    return 'Every journey starts somewhere!';
  }

  Widget _buildStatsGrid(UserStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Lifetime Habits',
          stats.lifetimeHabitsCompleted.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Days Active',
          stats.totalDaysActive.toString(),
          Icons.calendar_today,
          Colors.blue,
        ),
        _buildStatCard(
          'Streak Breaks',
          stats.totalStreakBreaks.toString(),
          Icons.broken_image,
          Colors.red,
        ),
        _buildStatCard(
          'Recovery Tokens',
          stats.streakRecoveryTokens.toString(),
          Icons.stars,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: AppTokens.rMd,
      borderColor: color.withOpacity(0.30),
      tint: color.withOpacity(0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBreaksSection(UserStats stats) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      radius: AppTokens.rMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text(
                'Streak Break History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (stats.streakBreakHistory.isEmpty)
            Text(
              'No streak breaks yet! Keep it up! 🔥',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            )
          else
            ...stats.streakBreakHistory.take(5).map((date) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red.withValues(alpha: 0.7), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(date),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                )),
          if (stats.lastStreakBreakDate != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              'Last broken: ${stats.lastBrokenStreak} days on ${_formatDate(stats.lastStreakBreakDate!)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBestWorstDays() {
    return FutureBuilder<List<WeekdayStats>>(
      future: AnalyticsService.getBestWorstDays(),
      builder: (context, snapshot) {
        return GlassCard(
          padding: const EdgeInsets.all(20),
          radius: AppTokens.rMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.green, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Best & Worst Days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasData && snapshot.data!.isNotEmpty) ...[
                // Best day
                _buildDayCard(
                  snapshot.data!.first,
                  Colors.green,
                  Icons.emoji_events,
                  'Best Day',
                ),
                const SizedBox(height: 12),
                // Worst day
                _buildDayCard(
                  snapshot.data!.last,
                  Colors.red,
                  Icons.sentiment_dissatisfied,
                  'Needs Work',
                ),
              ] else
                Text(
                  'Complete more habits to see insights!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayCard(WeekdayStats stats, Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.dayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.successRate.toStringAsFixed(0)}% success rate • ${stats.averageHabits.toStringAsFixed(1)} avg habits',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestWorstHabits() {
    return FutureBuilder<List<HabitPerformance>>(
      future: AnalyticsService.getBestWorstHabits(),
      builder: (context, snapshot) {
        return GlassCard(
          padding: const EdgeInsets.all(20),
          radius: AppTokens.rMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.stars, color: Colors.amber, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Best & Worst Habits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasData && snapshot.data!.isNotEmpty) ...[
                // Best habit (highest completion rate)
                _buildHabitPerformanceCard(
                  snapshot.data!.first,
                  Colors.green,
                  Icons.emoji_events,
                  'Most Consistent',
                ),
                const SizedBox(height: 12),
                // Worst habit (lowest completion rate)
                _buildHabitPerformanceCard(
                  snapshot.data!.last,
                  Colors.orange,
                  Icons.flag,
                  'Room to Grow',
                ),
              ] else
                Text(
                  'Complete more habits to see insights!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHabitPerformanceCard(HabitPerformance performance, Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performance.habitName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${performance.completionRate.toStringAsFixed(0)}% completion • ${performance.timesCompleted}/${performance.totalDays} days',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCorrelations() {
    return FutureBuilder<List<HabitCorrelation>>(
      future: AnalyticsService.getHabitCorrelations(),
      builder: (context, snapshot) {
        return GlassCard(
          padding: const EdgeInsets.all(20),
          radius: AppTokens.rMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.link, color: Colors.blue, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Habit Pairs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Habits you often do together',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasData && snapshot.data!.isNotEmpty)
                ...snapshot.data!.map((correlation) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCorrelationCard(correlation),
                    ))
              else
                Text(
                  'Need more data to find patterns!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCorrelationCard(HabitCorrelation correlation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  correlation.habit1,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.link, color: Colors.blue.withValues(alpha: 0.6), size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    correlation.habit2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(correlation.correlationScore * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildTimeRangeSelector() {
    return GlassSegmented<String>(
      selected: _selectedTimeRange,
      onChanged: (v) => setState(() => _selectedTimeRange = v),
      items: const [
        (value: '7days', label: '7 Days'),
        (value: '30days', label: '30 Days'),
        (value: 'all', label: 'All Time'),
      ],
    );
  }


  Widget _buildStreakComparison() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStreakComparisonData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final data = snapshot.data!;
        final currentStreak = data['currentStreak'] as int;
        final avgHabitsPerDay = data['avgHabitsPerDay'] as double;
        final trend = data['trend'] as String;
        final trendColor = data['trendColor'] as Color;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                trendColor.withValues(alpha: 0.2),
                const Color(0xFF1D1E33),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: trendColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: trendColor, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Performance Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTrendStat('Current Streak', '$currentStreak days', Icons.local_fire_department, Colors.orange),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildTrendStat('Avg Habits/Day', avgHabitsPerDay.toStringAsFixed(1), Icons.check_circle, Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      trend == 'improving' ? Icons.arrow_upward :
                      trend == 'declining' ? Icons.arrow_downward : Icons.remove,
                      color: trendColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      trend == 'improving' ? 'Improving! Keep it up!' :
                      trend == 'declining' ? 'Trending down. Time to bounce back!' :
                      'Steady progress. Stay consistent!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getStreakComparisonData() async {
    final allLogs = HiveService.getAllDayLogs();

    if (allLogs.isEmpty) {
      return {
        'currentStreak': 0,
        'avgHabitsPerDay': 0.0,
        'trend': 'steady',
        'trendColor': Colors.blue,
      };
    }

    // Calculate current streak
    int currentStreak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final log = HiveService.getDayLogByDate(date);

      if (log != null && log.totalHabitsLogged >= 1) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Calculate average habits per day
    final totalHabits = allLogs.fold<int>(0, (sum, log) => sum + log.totalHabitsLogged);
    final avgHabitsPerDay = totalHabits / allLogs.length;

    // Determine trend (compare last 7 days vs previous 7 days)
    final last7Days = allLogs.take(7).toList();
    final previous7Days = allLogs.skip(7).take(7).toList();

    String trend = 'steady';
    Color trendColor = Colors.blue;

    if (last7Days.length >= 3 && previous7Days.length >= 3) {
      final last7Avg = last7Days.fold<int>(0, (sum, log) => sum + log.totalHabitsLogged) / last7Days.length;
      final prev7Avg = previous7Days.fold<int>(0, (sum, log) => sum + log.totalHabitsLogged) / previous7Days.length;

      if (last7Avg > prev7Avg * 1.1) {
        trend = 'improving';
        trendColor = Colors.green;
      } else if (last7Avg < prev7Avg * 0.9) {
        trend = 'declining';
        trendColor = Colors.orange;
      }
    }

    return {
      'currentStreak': currentStreak,
      'avgHabitsPerDay': avgHabitsPerDay,
      'trend': trend,
      'trendColor': trendColor,
    };
  }
}
