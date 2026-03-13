// TEAM ANALYTICS SCREEN
// File: lib/modules/task_management/screens/manager/team_analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/task_service.dart';

import '../../utils/task_helpers.dart';

class TeamAnalyticsScreen extends StatefulWidget {
  final String projectId;

  const TeamAnalyticsScreen({Key? key, required this.projectId})
      : super(key: key);

  @override
  State<TeamAnalyticsScreen> createState() => _TeamAnalyticsScreenState();
}

class _TeamAnalyticsScreenState extends State<TeamAnalyticsScreen> {
  final TaskService taskService = TaskService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _projectStats = {};
  List<Map<String, dynamic>> _designerStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      // Load project stats
      final projectStats = await _loadProjectStats();

      // Load designer stats
      final designerStats = await _loadDesignerStats();

      setState(() {
        _projectStats = projectStats;
        _designerStats = designerStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _loadProjectStats() async {
    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('projectId', isEqualTo: widget.projectId)
        .get();

    final tasks = tasksSnapshot.docs;
    final totalTasks = tasks.length;
    final completedTasks =
        tasks.where((doc) => doc['status'] == 'completed').length;
    final inProgressTasks =
        tasks.where((doc) => doc['status'] == 'in_progress').length;
    final pendingTasks =
        tasks.where((doc) => doc['status'] == 'pending').length;
    final reviewTasks = tasks.where((doc) => doc['status'] == 'review').length;
    final rejectedTasks =
        tasks.where((doc) => doc['status'] == 'rejected').length;

    double totalEstimated = 0;
    double totalActual = 0;
    int overdueTasks = 0;

    for (var doc in tasks) {
      // ignore: unnecessary_cast
      final data = doc.data() as Map<String, dynamic>;
      totalEstimated += (data['estimatedHours'] ?? 0.0);
      totalActual += (data['actualHours'] ?? 0.0);

      if (data['dueDate'] != null) {
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        if (DateTime.now().isAfter(dueDate) && data['status'] != 'completed') {
          overdueTasks++;
        }
      }
    }

    final completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;
    final efficiency =
        totalEstimated > 0 ? (totalActual / totalEstimated * 100) : 0.0;

    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'inProgressTasks': inProgressTasks,
      'pendingTasks': pendingTasks,
      'reviewTasks': reviewTasks,
      'rejectedTasks': rejectedTasks,
      'overdueTasks': overdueTasks,
      'completionRate': completionRate,
      'totalEstimatedHours': totalEstimated,
      'totalActualHours': totalActual,
      'efficiency': efficiency,
    };
  }

  Future<List<Map<String, dynamic>>> _loadDesignerStats() async {
    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('projectId', isEqualTo: widget.projectId)
        .get();

    final Map<String, Map<String, dynamic>> designerMap = {};

    for (var doc in tasksSnapshot.docs) {
      final data = doc.data();
      final designerId = data['assignedTo'];

      if (!designerMap.containsKey(designerId)) {
        final userDoc =
            await _firestore.collection('users').doc(designerId).get();
        final userData = userDoc.data() ?? {};

        designerMap[designerId] = {
          'id': designerId,
          'name': userData['name'] ?? 'Unknown',
          'totalTasks': 0,
          'completedTasks': 0,
          'inProgressTasks': 0,
          'pendingTasks': 0,
          'rejectedTasks': 0,
          'totalHours': 0.0,
          'avgCompletionTime': 0.0,
          'completionTimes': <double>[],
        };
      }

      final stats = designerMap[designerId]!;
      stats['totalTasks']++;

      final status = data['status'];
      if (status == 'completed') {
        stats['completedTasks']++;

        // Calculate completion time
        if (data['createdAt'] != null && data['updatedAt'] != null) {
          final created = (data['createdAt'] as Timestamp).toDate();
          final updated = (data['updatedAt'] as Timestamp).toDate();
          final completionTime = updated.difference(created).inHours.toDouble();
          (stats['completionTimes'] as List<double>).add(completionTime);
        }
      } else if (status == 'in_progress') {
        stats['inProgressTasks']++;
      } else if (status == 'pending') {
        stats['pendingTasks']++;
      } else if (status == 'rejected') {
        stats['rejectedTasks']++;
      }

      stats['totalHours'] += (data['actualHours'] ?? 0.0);
    }

    // Calculate average completion time
    designerMap.forEach((key, value) {
      final times = value['completionTimes'] as List<double>;
      if (times.isNotEmpty) {
        value['avgCompletionTime'] =
            times.reduce((a, b) => a + b) / times.length;
      }
      value.remove('completionTimes');
    });

    return designerMap.values.toList()
      ..sort((a, b) => b['completedTasks'].compareTo(a['completedTasks']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Project Overview
                  _buildProjectOverview(),

                  const SizedBox(height: 24),

                  // Task Distribution
                  _buildTaskDistribution(),

                  const SizedBox(height: 24),

                  // Performance Metrics
                  _buildPerformanceMetrics(),

                  const SizedBox(height: 24),

                  // Designer Performance
                  _buildDesignerPerformance(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildProjectOverview() {
    final totalTasks = _projectStats['totalTasks'] ?? 0;
    final completionRate = _projectStats['completionRate'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Progress Ring
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: completionRate / 100,
                        strokeWidth: 15,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completionRate < 30
                              ? Colors.red
                              : completionRate < 70
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${completionRate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Complete',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    '$totalTasks',
                    Icons.assignment,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    '${_projectStats['completedTasks']}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'In Progress',
                    '${_projectStats['inProgressTasks']}',
                    Icons.work_outline,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Overdue',
                    '${_projectStats['overdueTasks']}',
                    Icons.error_outline,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskDistribution() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDistributionBar(
              'Pending',
              _projectStats['pendingTasks'] ?? 0,
              _projectStats['totalTasks'] ?? 1,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildDistributionBar(
              'In Progress',
              _projectStats['inProgressTasks'] ?? 0,
              _projectStats['totalTasks'] ?? 1,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildDistributionBar(
              'In Review',
              _projectStats['reviewTasks'] ?? 0,
              _projectStats['totalTasks'] ?? 1,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildDistributionBar(
              'Completed',
              _projectStats['completedTasks'] ?? 0,
              _projectStats['totalTasks'] ?? 1,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildDistributionBar(
              'Rejected',
              _projectStats['rejectedTasks'] ?? 0,
              _projectStats['totalTasks'] ?? 1,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(
      String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    final efficiency = _projectStats['efficiency'] ?? 0.0;
    final totalEstimated = _projectStats['totalEstimatedHours'] ?? 0.0;
    final totalActual = _projectStats['totalActualHours'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Time Efficiency',
                    '${efficiency.toStringAsFixed(0)}%',
                    efficiency <= 100 ? Icons.trending_up : Icons.trending_down,
                    efficiency <= 100 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Estimated Hours',
                    TaskHelpers.formatHours(totalEstimated),
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
              'Actual Hours Worked',
              TaskHelpers.formatHours(totalActual),
              Icons.timer,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignerPerformance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Designer Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (_designerStats.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No designer data available'),
                ),
              )
            else
              ..._designerStats.map((designer) {
                return _buildDesignerCard(designer);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignerCard(Map<String, dynamic> designer) {
    final completionRate = designer['totalTasks'] > 0
        ? (designer['completedTasks'] / designer['totalTasks'] * 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Completion Rate
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  TaskHelpers.getInitials(designer['name']),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      designer['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${completionRate.toStringAsFixed(0)}% completion rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Stats
          Row(
            children: [
              _buildDesignerStat(
                Icons.assignment,
                '${designer['totalTasks']}',
                'Total',
              ),
              _buildDesignerStat(
                Icons.check_circle,
                '${designer['completedTasks']}',
                'Done',
              ),
              _buildDesignerStat(
                Icons.work_outline,
                '${designer['inProgressTasks']}',
                'Working',
              ),
              _buildDesignerStat(
                Icons.access_time,
                TaskHelpers.formatHours(designer['totalHours']),
                'Hours',
              ),
            ],
          ),

          if (designer['avgCompletionTime'] > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Avg. completion: ${TaskHelpers.formatHours(designer['avgCompletionTime'])}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesignerStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
