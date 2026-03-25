// DESIGNER DASHBOARD SCREEN
// File: lib/modules/task_management/screens/designer/designer_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../utils/task_constants.dart';
import '../../utils/task_helpers.dart';
import '../../widgets/task_card.dart';
import 'designer_task_detail.dart';

class DesignerDashboard extends StatefulWidget {
  const DesignerDashboard({Key? key}) : super(key: key);

  @override
  State<DesignerDashboard> createState() => _DesignerDashboardState();
}

class _DesignerDashboardState extends State<DesignerDashboard>
    with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  late TabController _tabController;
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _taskService.getDesignerStats(_userId);
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'My Tasks',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: TaskColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!_isLoadingStats && _stats != null)
                          _buildStatsRow(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildQuickStats(),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'All Tasks'),
                  Tab(text: 'In Progress'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTasks(),
                _buildAllTasks(),
                _buildInProgressTasks(),
                _buildCompletedTasks(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final completionRate = _stats!['completionRate'] as double;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
              'Total Tasks', '${_stats!['totalTasks']}', Icons.assignment),
        ),
        Expanded(
          child: _buildStatItem(
              'Completed', '${_stats!['completedTasks']}', Icons.check_circle),
        ),
        Expanded(
          child: _buildStatItem('Success Rate',
              '${completionRate.toStringAsFixed(0)}%', Icons.trending_up),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildQuickStats() {
    if (_isLoadingStats)
      return const Center(child: CircularProgressIndicator());
    if (_stats == null) return const SizedBox.shrink();

    final totalHours = _stats!['totalHoursWorked'] as double;

    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard('In Progress',
              '${_stats!['inProgressTasks']}', Colors.blue, Icons.work_outline),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
              'Hours Worked',
              TaskHelpers.formatHours(totalHours),
              Colors.green,
              Icons.access_time),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTodayTasks() {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.streamTodayTasks(_userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty)
          return _buildEmptyState('No tasks due today', Icons.today);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) => TaskCard(
              task: tasks[index],
              onTap: () => _navigateToTaskDetail(tasks[index])),
        );
      },
    );
  }

  Widget _buildAllTasks() {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.streamTasksByDesigner(_userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty)
          return _buildEmptyState('No tasks assigned', Icons.assignment);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) => TaskCard(
              task: tasks[index],
              onTap: () => _navigateToTaskDetail(tasks[index])),
        );
      },
    );
  }

  Widget _buildInProgressTasks() {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.streamTasksByStatus('in_progress', _userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty)
          return _buildEmptyState('No tasks in progress', Icons.work_outline);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) => TaskCard(
              task: tasks[index],
              onTap: () => _navigateToTaskDetail(tasks[index])),
        );
      },
    );
  }

  Widget _buildCompletedTasks() {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.streamTasksByStatus('completed', _userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty)
          return _buildEmptyState('No completed tasks', Icons.check_circle);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) => TaskCard(
              task: tasks[index],
              onTap: () => _navigateToTaskDetail(tasks[index])),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _navigateToTaskDetail(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DesignerTaskDetail(taskId: task.id)),
    ).then((_) => _loadStats());
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
