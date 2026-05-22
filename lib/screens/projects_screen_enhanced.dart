import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../widgets/glass.dart';
import 'project_detail_screen.dart';
import 'dart:math' as math;

class ProjectsScreenEnhanced extends ConsumerStatefulWidget {
  const ProjectsScreenEnhanced({Key? key}) : super(key: key);

  @override
  ConsumerState<ProjectsScreenEnhanced> createState() => _ProjectsScreenEnhancedState();
}

class _ProjectsScreenEnhancedState extends ConsumerState<ProjectsScreenEnhanced> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;
  String _selectedView = 'grid'; // 'grid' or 'list'
  late AnimationController _fabController;

  final List<Color> _colors = [
    const Color(0xFFFF6B6B), // Red
    const Color(0xFFFF9F43), // Orange
    const Color(0xFFFFD93D), // Yellow
    const Color(0xFF6BCF7F), // Green
    const Color(0xFF4ECDC4), // Teal
    const Color(0xFF5F9FED), // Blue
    const Color(0xFF9B59B6), // Purple
    const Color(0xFFEC407A), // Pink
    const Color(0xFF26A69A), // Cyan
    const Color(0xFFFF7043), // Deep Orange
  ];

  final List<Map<String, dynamic>> _iconData = [
    {'icon': Icons.code, 'label': 'Code'},
    {'icon': Icons.design_services, 'label': 'Design'},
    {'icon': Icons.business_center, 'label': 'Business'},
    {'icon': Icons.fitness_center, 'label': 'Fitness'},
    {'icon': Icons.school, 'label': 'Study'},
    {'icon': Icons.music_note, 'label': 'Music'},
    {'icon': Icons.camera_alt, 'label': 'Photo'},
    {'icon': Icons.rocket_launch, 'label': 'Startup'},
    {'icon': Icons.palette, 'label': 'Art'},
    {'icon': Icons.science, 'label': 'Research'},
    {'icon': Icons.sports_esports, 'label': 'Gaming'},
    {'icon': Icons.language, 'label': 'Language'},
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showAddProjectDialog() {
    _selectedColorIndex = math.Random().nextInt(_colors.length);
    _selectedIconIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF1D1E33),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.rocket_launch, color: Colors.orange, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create New Project',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Name Input
                      const Text(
                        'Project Name',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'e.g., Mobile App, Fitness Goal...',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                          prefixIcon: const Icon(Icons.edit, color: Colors.orange),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.orange, width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0A0E21),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Color Selection
                      const Text(
                        'Choose Color',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(_colors.length, (index) {
                          final isSelected = _selectedColorIndex == index;
                          return GestureDetector(
                            onTap: () => setDialogState(() => _selectedColorIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 54 : 48,
                              height: isSelected ? 54 : 48,
                              decoration: BoxDecoration(
                                color: _colors[index],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _colors[index].withValues(alpha: 0.6),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : [],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 28)
                                  : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Icon Selection
                      const Text(
                        'Choose Icon',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: _iconData.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedIconIndex == index;
                          final iconInfo = _iconData[index];
                          return GestureDetector(
                            onTap: () => setDialogState(() => _selectedIconIndex = index),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _colors[_selectedColorIndex].withValues(alpha: 0.3)
                                        : const Color(0xFF0A0E21),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? _colors[_selectedColorIndex] : Colors.white24,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Icon(
                                    iconInfo['icon'] as IconData,
                                    color: isSelected ? _colors[_selectedColorIndex] : Colors.white60,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  iconInfo['label'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? _colors[_selectedColorIndex] : Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _nameController.clear();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_nameController.text.isNotEmpty) {
                            final colorValue = _colors[_selectedColorIndex].value;
                            ref.read(projectsProvider.notifier).addProject(
                                  _nameController.text,
                                  colorValue.toRadixString(16).substring(2),
                                  (_iconData[_selectedIconIndex]['icon'] as IconData).codePoint.toString(),
                                );
                            _nameController.clear();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Project created! 🚀'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle, size: 20),
                            SizedBox(width: 8),
                            Text('Create Project', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final activeProjects = projects.where((p) => p.active).toList();
    final archivedProjects = projects.where((p) => !p.active).toList();

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
                'Projects',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GlassIconButton(
                    icon: _selectedView == 'grid' ? Icons.view_list : Icons.grid_view,
                    onTap: () => setState(() => _selectedView = _selectedView == 'grid' ? 'list' : 'grid'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: activeProjects.isEmpty
          ? _buildEmptyState()
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    16,
                    16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildStatsOverview(activeProjects),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _selectedView == 'grid'
                      ? _buildGridView(activeProjects)
                      : _buildListView(activeProjects),
                ),
                if (archivedProjects.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Archived',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: _buildArchivedList(archivedProjects),
                  ),
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: _GlassFab(onTap: _showAddProjectDialog),
      ),
    );
  }

  Widget _buildEmptyState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _fabController.status != AnimationStatus.completed) {
        _fabController.forward();
      }
    });

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.rocket_launch, size: 80, color: Colors.orange.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Projects Yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Start building something legendary!\nTap the button below to create your first project',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.white60, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(List<Project> activeProjects) {
    int totalMilestones = 0;
    int completedMilestones = 0;
    int totalHours = 0;

    for (var p in activeProjects) {
      totalMilestones += p.milestones.length;
      completedMilestones += p.milestoneCompleted.where((c) => c).length;
      totalHours += p.hoursSpent;
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      radius: AppTokens.rMd,
      borderColor: AppTokens.accent.withOpacity(0.30),
      shadows: [
        BoxShadow(
          color: AppTokens.accent.withOpacity(0.12),
          blurRadius: 22,
          spreadRadius: -4,
        ),
      ],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildOverviewStat(activeProjects.length.toString(), 'Active', Icons.folder_open, AppTokens.accent),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildOverviewStat('$completedMilestones/$totalMilestones', 'Milestones', Icons.flag, Colors.green),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildOverviewStat('${totalHours}h', 'Total Time', Icons.access_time, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
      ],
    );
  }

  Widget _buildGridView(List<Project> activeProjects) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildProjectGridCard(activeProjects[index]),
        childCount: activeProjects.length,
      ),
    );
  }

  Widget _buildListView(List<Project> activeProjects) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildProjectListCard(activeProjects[index]),
        ),
        childCount: activeProjects.length,
      ),
    );
  }

  Widget _buildProjectGridCard(Project project) {
    final color = Color(int.parse('0xFF${project.colorHex}'));
    final icon = IconData(int.parse(project.icon), fontFamily: 'MaterialIcons');
    final progress = project.completionPercentage;

    return Dismissible(
      key: Key(project.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(projectsProvider.notifier).archiveProject(project.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${project.name} archived'), behavior: SnackBarBehavior.floating),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project))),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1D1E33), color.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        project.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (project.milestones.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.flag, size: 14, color: color),
                            const SizedBox(width: 4),
                            Text(
                              '${project.milestoneCompleted.where((c) => c).length}/${project.milestones.length}',
                              style: TextStyle(fontSize: 12, color: color),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.white60),
                          const SizedBox(width: 4),
                          Text('${project.hoursSpent}h', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (progress == 100)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectListCard(Project project) {
    final color = Color(int.parse('0xFF${project.colorHex}'));
    final icon = IconData(int.parse(project.icon), fontFamily: 'MaterialIcons');
    final progress = project.completionPercentage;

    return Dismissible(
      key: Key('list_${project.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(projectsProvider.notifier).archiveProject(project.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${project.name} archived'), behavior: SnackBarBehavior.floating),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project))),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1D1E33), color.withValues(alpha: 0.05)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      if (project.milestones.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 6,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (project.milestones.isNotEmpty) ...[
                            Icon(Icons.flag, size: 14, color: color),
                            const SizedBox(width: 4),
                            Text(
                              '${project.milestoneCompleted.where((c) => c).length}/${project.milestones.length}',
                              style: TextStyle(fontSize: 12, color: color),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Icon(Icons.access_time, size: 14, color: Colors.white60),
                          const SizedBox(width: 4),
                          Text('${project.hoursSpent}h', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArchivedList(List<Project> archivedProjects) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final project = archivedProjects[index];
          final color = Color(int.parse('0xFF${project.colorHex}'));
          final icon = IconData(int.parse(project.icon), fontFamily: 'MaterialIcons');

          return Dismissible(
            key: Key('archived_${project.id}'),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                ref.read(projectsProvider.notifier).unarchiveProject(project.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${project.name} restored'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                );
                return false;
              } else {
                return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1D1E33),
                        title: const Text('Delete Project?', style: TextStyle(color: Colors.white)),
                        content: Text('Delete "${project.name}"? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
              }
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                ref.read(projectsProvider.notifier).deleteProject(project.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${project.name} deleted'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                );
              }
            },
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.only(left: 20),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [Icon(Icons.unarchive, color: Colors.white), SizedBox(width: 8), Text('Restore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))],
              ),
            ),
            secondaryBackground: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.delete_forever, color: Colors.white)],
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color.withValues(alpha: 0.5), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name, style: const TextStyle(fontSize: 15, color: Colors.white54)),
                        const SizedBox(height: 4),
                        const Text('Swipe to restore or delete', style: TextStyle(fontSize: 11, color: Colors.white30)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: archivedProjects.length,
      ),
    );
  }
}

class _GlassFab extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [AppTokens.accent, AppTokens.accentDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.20),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTokens.accent.withOpacity(0.55),
                    blurRadius: 22,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'New Project',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
