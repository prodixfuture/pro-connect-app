// STAFF TASK DASHBOARD - PERFECT FINAL VERSION
// File: lib/modules/task_management/screens/staff/staff_task_dashboard.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../utils/task_helpers.dart';
import 'staff_task_detail.dart';
import 'personal_todo_screen.dart';
import '/staff/common/notification_screen.dart'; // Add this import

class StaffTaskDashboard extends StatefulWidget {
  const StaffTaskDashboard({Key? key}) : super(key: key);

  @override
  State<StaffTaskDashboard> createState() => _StaffTaskDashboardState();
}

class _StaffTaskDashboardState extends State<StaffTaskDashboard> {
  final TaskService _taskService = TaskService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  int _selectedTab = 0;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      final stats = await _taskService.getDesignerStats(_userId);

      if (mounted) {
        setState(() {
          _userData = userDoc.data();
          _stats = stats;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          SizedBox(height: 20),
          _buildStatusTabs(),
          SizedBox(height: 16),
          Expanded(child: _buildTaskList()),
        ],
      ),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  Widget _buildHeader() {
    final userName = _userData?['name'] ?? 'Staff Name';
    final productivityScore = _stats?['completionRate'] ?? 0.0;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final hasBadge = userData?['hasPremiumBadge'] ?? false;
        final badgeTitle = userData?['badgeTitle'] ?? 'Star Performer';
        final badgeType = userData?['badgeType'] ?? 'designer';

        Color badgeColor;
        IconData badgeIcon;
        switch (badgeType) {
          case 'designer':
          case 'design':
            badgeColor = Color(0xff9C27B0);
            badgeIcon = Icons.palette_rounded;
            break;
          case 'sales_rep':
          case 'sales':
            badgeColor = Color(0xffFFD700);
            badgeIcon = Icons.trending_up_rounded;
            break;
          case 'staff':
            badgeColor = Color(0xff4CAF50);
            badgeIcon = Icons.stars_rounded;
            break;
          case 'manager':
          case 'admin':
            badgeColor = Color(0xff2196F3);
            badgeIcon = Icons.lightbulb_rounded;
            break;
          default:
            badgeColor = Color(0xffFFD700);
            badgeIcon = Icons.star_rounded;
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6B7FED), Color(0xFF7B8FF7)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF6B7FED).withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd - MM - yyyy').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          // Notification Bell
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('notifications')
                                .where('userId', isEqualTo: _userId)
                                .snapshots(),
                            builder: (context, notifSnapshot) {
                              int unreadCount = 0;
                              if (notifSnapshot.hasData &&
                                  notifSnapshot.data != null) {
                                try {
                                  unreadCount =
                                      notifSnapshot.data!.docs.where((doc) {
                                    try {
                                      final data =
                                          doc.data() as Map<String, dynamic>?;
                                      return data != null &&
                                          !(data['isRead'] ?? false);
                                    } catch (e) {
                                      return false;
                                    }
                                  }).length;
                                } catch (e) {
                                  unreadCount = 0;
                                }
                              }

                              return InkWell(
                                onTap: () {
                                  // Navigate to notification screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          NotificationScreen(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Color(0xFFFF4444),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),

                          if (hasBadge && badgeTitle.isNotEmpty) ...[
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: badgeColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(badgeIcon,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    badgeTitle.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'GOOD ${_getGreeting().toUpperCase()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$userName',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Productivity Score',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${productivityScore.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: productivityScore / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTabs() {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.streamTasksByDesigner(_userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        final tasks = snapshot.data ?? [];
        final pendingCount = tasks.where((t) => t.status == 'pending').length;
        final inProgressCount = tasks
            .where((t) => t.status == 'in_progress' || t.status == 'review')
            .length;
        final revisionCount = tasks.where((t) => t.status == 'rejected').length;
        final completedCount =
            tasks.where((t) => t.status == 'completed').length;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTab('Pending', 0, pendingCount, Color(0xFF6B7FED)),
              SizedBox(width: 12),
              _buildTab('In Progress', 1, inProgressCount, Color(0xFFFFA726)),
              SizedBox(width: 12),
              _buildTab('Revision', 2, revisionCount, Color(0xFFFF7597)),
              SizedBox(width: 12),
              _buildTab('Completed', 3, completedCount, Color(0xFF66BB6A)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String label, int index, int count, Color color) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.3) : Colors.grey[200]!,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? color : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (count > 0 && index != 3) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    List<String> statuses;
    switch (_selectedTab) {
      case 0:
        statuses = ['pending'];
        break;
      case 1:
        statuses = ['in_progress', 'review'];
        break;
      case 2:
        statuses = ['rejected'];
        break;
      case 3:
        statuses = ['completed'];
        break;
      default:
        statuses = ['pending'];
    }

    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.streamTasksByDesigner(_userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('No tasks available'));
        }

        var tasks = snapshot.data!;
        tasks = tasks.where((t) => statuses.contains(t.status)).toList();

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 72, color: Colors.grey[300]),
                SizedBox(height: 12),
                Text(
                  'No tasks',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: tasks.length,
          itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
        );
      },
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    // Get status color (not priority color!)
    Color statusColor = _getStatusColor(task.status);

    String statusLabel;
    if (task.status == 'pending') {
      statusLabel = 'Pending';
    } else if (task.status == 'in_progress') {
      statusLabel = 'In Progress';
    } else if (task.status == 'review') {
      statusLabel = 'In Review';
    } else if (task.status == 'rejected') {
      statusLabel = 'Revision';
    } else {
      statusLabel = 'Completed';
    }

    // Calculate time details
    String durationText = '--:-- AM';
    String startTimeText = '--:-- AM';
    String endTimeText = '--:-- AM';

    if (task.startTime != null) {
      startTimeText = DateFormat('h:mm a').format(task.startTime!);
    }

    if (task.endTime != null) {
      endTimeText = DateFormat('h:mm a').format(task.endTime!);
    }

    if (task.actualHours != null && task.actualHours! > 0) {
      final hours = task.actualHours!.floor();
      final minutes = ((task.actualHours! - hours) * 60).round();
      durationText = '${hours}h ${minutes}m';
    }

    // Calculate overdue days
    String overdueText = '';
    if (task.dueDate != null) {
      final now = DateTime.now();
      final diff = task.dueDate!.difference(now);
      if (diff.isNegative) {
        overdueText = 'Overdue by ${diff.inDays.abs()}d';
      } else if (diff.inDays == 0) {
        overdueText = 'Due today';
      } else {
        overdueText = 'Due in ${diff.inDays}d';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor, width: 4), // LEFT LINE!
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StaffTaskDetail(taskId: task.id)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title ?? 'Untitled Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Priority & Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPillTag(
                    _getPriorityLabel(task.priority ?? 'medium'),
                    _getPriorityColor(task.priority ?? 'medium'),
                  ),
                  if (task.tags != null)
                    ...task.tags!
                        .map((tag) => _buildPillTag(tag, Colors.grey[600]!)),
                ],
              ),

              SizedBox(height: 12),

              Text(
                task.description ?? 'No description',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 12),

              // Time Details Row (like image 4)
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (overdueText.isNotEmpty)
                    _buildInfoIcon(Icons.calendar_today_outlined, overdueText,
                        Colors.grey[600]!),
                  _buildInfoIcon(
                      Icons.access_time_outlined, '30 m', Colors.grey[600]!),
                  _buildInfoIcon(Icons.play_circle_outline,
                      'Start Time : $startTimeText', Colors.grey[600]!),
                  _buildInfoIcon(Icons.stop_circle_outlined,
                      'End Time : $endTimeText', Colors.grey[600]!),
                  _buildInfoIcon(Icons.timer_outlined,
                      'Duration : $durationText', Colors.grey[600]!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTag(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B7FED), Color(0xFF7B8FF7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6B7FED).withOpacity(0.4),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PersonalTodoScreen()),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'My Todo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    // Status color for card left border
    switch (status.toLowerCase()) {
      case 'pending':
        return Color(0xFF6B7FED); // Blue
      case 'in_progress':
        return Color(0xFFFFA726); // Orange
      case 'review':
        return Color(0xFFFFA726); // Orange
      case 'rejected':
        return Color(0xFFFF7597); // Pink
      case 'completed':
        return Color(0xFF66BB6A); // Green
      default:
        return Color(0xFF6B7280); // Grey
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Color(0xFFEF4444); // Red
      case 'high':
        return Color(0xFFF59E0B); // Orange
      case 'medium':
        return Color(0xFF3B82F6); // Blue
      case 'low':
        return Color(0xFF10B981); // Green
      default:
        return Color(0xFF6B7280); // Grey
    }
  }

  String _getPriorityLabel(String priority) {
    return priority[0].toUpperCase() + priority.substring(1);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
