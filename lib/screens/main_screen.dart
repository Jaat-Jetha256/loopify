import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/glass.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import 'projects_screen_enhanced.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    AnalyticsScreen(),
    ProjectsScreenEnhanced(),
    SettingsScreen(),
  ];

  final List<_TabItem> _tabs = const [
    _TabItem(
      icon: Icons.local_fire_department_rounded,
      activeIcon: Icons.local_fire_department,
      label: 'Home',
    ),
    _TabItem(
      icon: Icons.history_rounded,
      activeIcon: Icons.history,
      label: 'History',
    ),
    _TabItem(
      icon: Icons.insights_rounded,
      activeIcon: Icons.insights,
      label: 'Stats',
    ),
    _TabItem(
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
      label: 'Projects',
    ),
    _TabItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTokens.bgDeep,
      body: Stack(
        children: [
          const Positioned.fill(
            child: GlassBackground(child: SizedBox.shrink()),
          ),
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offset = Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _screens[_currentIndex],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _GlassTabBar(
        currentIndex: _currentIndex,
        tabs: _tabs,
        onTap: _onTap,
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _GlassTabBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  const _GlassTabBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomInset > 0 ? bottomInset + 6 : 14,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.10),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppTokens.accent.withOpacity(0.08),
                  blurRadius: 28,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / tabs.length;
                return Stack(
                  children: [
                    // Animated selection pill
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      left: tabWidth * currentIndex + 8,
                      top: 8,
                      bottom: 8,
                      width: tabWidth - 16,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 380),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTokens.accent.withOpacity(0.92),
                              AppTokens.accentDeep.withOpacity(0.95),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTokens.accent.withOpacity(0.45),
                              blurRadius: 18,
                              spreadRadius: -2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(tabs.length, (index) {
                        final tab = tabs[index];
                        final isActive = index == currentIndex;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTap(index),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.55),
                                fontSize: 10,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 260),
                                    transitionBuilder: (child, anim) {
                                      return ScaleTransition(
                                        scale: Tween<double>(begin: 0.85, end: 1.0)
                                            .animate(anim),
                                        child: FadeTransition(opacity: anim, child: child),
                                      );
                                    },
                                    child: Icon(
                                      isActive ? tab.activeIcon : tab.icon,
                                      key: ValueKey('$index-$isActive'),
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.55),
                                      size: isActive ? 24 : 22,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(tab.label),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
