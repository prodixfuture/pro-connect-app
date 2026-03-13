// STAFF TASK DETAIL - ULTRA SIMPLE VERSION
// File: lib/modules/task_management/screens/staff/staff_task_detail.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class StaffTaskDetail extends StatefulWidget {
  final String taskId;

  const StaffTaskDetail({Key? key, required this.taskId}) : super(key: key);

  @override
  State<StaffTaskDetail> createState() => _StaffTaskDetailState();
}

class _StaffTaskDetailState extends State<StaffTaskDetail> {
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? _projectData;
  Map<String, dynamic>? _clientData;
  bool _isLoading = false;

  // Cache to prevent flicker
  Map<String, dynamic>? _cachedTaskData;

  @override
  void initState() {
    super.initState();
    _loadProjectAndClient();
  }

  Future<void> _loadProjectAndClient() async {
    try {
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();

      if (!taskDoc.exists) return;

      final taskData = taskDoc.data() as Map<String, dynamic>;
      final projectId = taskData['projectId'] as String?;

      if (projectId == null) return;

      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get();

      if (projectDoc.exists && mounted) {
        final project = projectDoc.data();
        if (mounted) setState(() => _projectData = project);

        final clientId = project?['clientId'];
        if (clientId != null) {
          final clientDoc = await FirebaseFirestore.instance
              .collection('clients')
              .doc(clientId)
              .get();

          if (clientDoc.exists && mounted) {
            setState(() => _clientData = clientDoc.data());
          }
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Use cached data if available during refresh
          if (_cachedTaskData != null) {
            return _buildContent(_cachedTaskData!);
          }
          return Scaffold(
            appBar: AppBar(title: Text('Task Details')),
            body: Center(child: Text('Task not found')),
          );
        }

        final taskData = snapshot.data!.data() as Map<String, dynamic>;

        // Update cache
        _cachedTaskData = taskData;

        return _buildContent(taskData);
      },
    );
  }

  Widget _buildContent(Map<String, dynamic> taskData) {
    final status = taskData['status'] ?? 'pending';
    final title = taskData['title'] ?? 'Task';
    final description = taskData['description'] ?? '';
    final dueDate = taskData['dueDate'] != null
        ? (taskData['dueDate'] as Timestamp).toDate()
        : null;
    final estimatedHours = taskData['estimatedHours'];
    final startTime = taskData['startTime'] != null
        ? (taskData['startTime'] as Timestamp).toDate()
        : null;
    final endTime = taskData['endTime'] != null
        ? (taskData['endTime'] as Timestamp).toDate()
        : null;
    final actualHours = taskData['actualHours'];
    final rejectionReason = taskData['rejectionReason'];

    // Simple check: if has startTime but no endTime = running
    final isWorkRunning = startTime != null && endTime == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Submit Button OR Review Submitted Message
            if (status == 'in_progress' || status == 'rejected')
              _buildSubmitButton()
            else if (status == 'review')
              _buildReviewSubmittedBanner(),

            if (status == 'in_progress' ||
                status == 'rejected' ||
                status == 'review')
              SizedBox(height: 20),

            // Timer Display (show for pending, in_progress, rejected)
            if (startTime != null &&
                (status == 'pending' ||
                    status == 'in_progress' ||
                    status == 'rejected'))
              _TimerWidget(
                startTime: startTime,
                endTime: endTime,
                isRunning: isWorkRunning,
              ),

            if (startTime != null &&
                (status == 'pending' ||
                    status == 'in_progress' ||
                    status == 'rejected'))
              SizedBox(height: 20),

            // Start/Stop Buttons (for pending, in_progress, rejected)
            if (status == 'pending' ||
                status == 'in_progress' ||
                status == 'rejected')
              _buildWorkButtons(isWorkRunning),

            if (status == 'pending' ||
                status == 'in_progress' ||
                status == 'rejected')
              SizedBox(height: 24),

            // Task Details
            _buildTaskDetails(
              description,
              dueDate,
              estimatedHours,
              startTime,
              endTime,
              actualHours,
            ),

            SizedBox(height: 20),

            // Client & Project
            _buildClientProject(),

            SizedBox(height: 20),

            // Rejection Reason
            if (status == 'rejected' && rejectionReason != null)
              _buildRejectionReason(rejectionReason),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF6B7FED),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Submit for Review',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildReviewSubmittedBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review Submitted',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Waiting for admin approval',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkButtons(bool isRunning) {
    return Row(
      children: [
        // START BUTTON
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_isLoading || isRunning) ? null : _startWork,
            style: ElevatedButton.styleFrom(
              backgroundColor: (!isRunning && !_isLoading)
                  ? Color(0xFF10B981)
                  : Colors.grey[300],
              foregroundColor:
                  (!isRunning && !_isLoading) ? Colors.white : Colors.grey[600],
              padding: EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.play_arrow, size: 20),
            label: Text(
              'Start Work',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        // STOP BUTTON
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_isLoading || !isRunning) ? null : _stopWork,
            style: ElevatedButton.styleFrom(
              backgroundColor: (isRunning && !_isLoading)
                  ? Color(0xFFEF4444)
                  : Colors.grey[300],
              foregroundColor:
                  (isRunning && !_isLoading) ? Colors.white : Colors.grey[600],
              padding: EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              isRunning ? Icons.stop : Icons.check,
              size: 20,
            ),
            label: Text(
              isRunning ? 'Stop Work' : 'Work Stopped',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDetails(
    String? description,
    DateTime? dueDate,
    dynamic estimatedHours,
    DateTime? startTime,
    DateTime? endTime,
    dynamic actualHours,
  ) {
    final now = DateTime.now();
    final isOverdue = dueDate != null && dueDate.isBefore(now);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              description?.isEmpty ?? true ? 'No description' : description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 16),
          if (dueDate != null)
            _buildInfoItem('Due Date', _formatDueDate(dueDate),
                isOverdue: isOverdue),
          if (estimatedHours != null) ...[
            SizedBox(height: 12),
            _buildInfoItem('Estimated', '${estimatedHours}h'),
          ],
          if (startTime != null) ...[
            SizedBox(height: 12),
            _buildInfoItem(
                'Started', DateFormat('MMM dd, h:mm a').format(startTime)),
          ],
          if (endTime != null) ...[
            SizedBox(height: 12),
            _buildInfoItem(
                'Ended', DateFormat('MMM dd, h:mm a').format(endTime)),
          ],
          if (actualHours != null && actualHours > 0) ...[
            SizedBox(height: 12),
            _buildInfoItem('Duration', '${actualHours.toStringAsFixed(1)}h'),
          ],
        ],
      ),
    );
  }

  Widget _buildClientProject() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client & Project',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildInfoItem('Project', _projectData?['name'] ?? 'Loading...'),
          SizedBox(height: 12),
          _buildInfoItem(
              'Client',
              _clientData?['name'] ??
                  _projectData?['clientName'] ??
                  'Loading...'),
          if (_clientData?['email'] != null) ...[
            SizedBox(height: 12),
            _buildInfoItem('Email', _clientData!['email']),
          ],
          if (_clientData?['phone'] != null) ...[
            SizedBox(height: 12),
            _buildInfoItem('Phone', _clientData!['phone']),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectionReason(String reason) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFEF4444).withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text(
                'Needs Revision',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              reason,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isOverdue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isOverdue ? Color(0xFFEF4444) : Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.isNegative) {
      return 'Overdue by ${diff.inDays.abs()}d';
    } else if (diff.inDays == 0) {
      return 'Due today';
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  Future<void> _startWork() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();

      // Simple: just set startTime, clear endTime
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .update({
        'startTime': Timestamp.fromDate(now),
        'endTime': null, // Clear any previous end time
        'status': 'in_progress',
      });

      _showSnackBar('Work started', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _stopWork() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();

      // Get task to calculate duration
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();

      final taskData = taskDoc.data() as Map<String, dynamic>;
      final startTime = taskData['startTime'] != null
          ? (taskData['startTime'] as Timestamp).toDate()
          : null;

      double? actualHours;
      if (startTime != null) {
        final duration = now.difference(startTime);
        actualHours = duration.inMinutes / 60.0;
      }

      // Simple: just set endTime (this stops the timer)
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .update({
        'endTime': Timestamp.fromDate(now), // This makes isWorkRunning = false
        'actualHours': actualHours,
        // status stays 'in_progress'
      });

      _showSnackBar('Work stopped', Colors.orange);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForReview() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Submit for Review'),
        content: Text('Ready to submit for admin review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6B7FED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskId)
            .update({'status': 'review'});

        _showSnackBar('Submitted for review successfully', Colors.green);

        // Don't navigate away - let user see "Review Submitted" banner
        // Navigator.pop(context); // REMOVED
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}

// SEPARATE TIMER WIDGET
class _TimerWidget extends StatefulWidget {
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isRunning;

  const _TimerWidget({
    required this.startTime,
    required this.endTime,
    required this.isRunning,
  });

  @override
  State<_TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<_TimerWidget> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimer();
  }

  @override
  void didUpdateWidget(_TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning ||
        widget.startTime != oldWidget.startTime ||
        widget.endTime != oldWidget.endTime) {
      _updateTimer();
    }
  }

  void _updateTimer() {
    _timer?.cancel();

    if (widget.isRunning && widget.startTime != null) {
      // Timer running - update every second
      _elapsed = DateTime.now().difference(widget.startTime!);
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted && widget.isRunning) {
          setState(() {
            _elapsed = DateTime.now().difference(widget.startTime!);
          });
        }
      });
    } else if (widget.startTime != null && widget.endTime != null) {
      // Timer stopped - show final duration
      _elapsed = widget.endTime!.difference(widget.startTime!);
    } else {
      _elapsed = Duration.zero;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isRunning ? Color(0xFF10B981) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isRunning ? Icons.timer : Icons.timer_off,
            color: widget.isRunning ? Colors.white : Colors.grey[600],
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            '$hours:$minutes:$seconds',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: widget.isRunning ? Colors.white : Colors.grey[700],
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
