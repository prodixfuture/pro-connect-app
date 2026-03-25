// STEP 1.4: TASK ACTIVITY MODEL
// File: lib/modules/task_management/models/task_activity_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TaskActivityModel {
  final String id;
  final String taskId;
  final String action; // created, assigned, status_changed, etc.
  final String userId;
  final String userName;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // Additional context data
  final String? oldValue;
  final String? newValue;

  TaskActivityModel({
    required this.id,
    required this.taskId,
    required this.action,
    required this.userId,
    required this.userName,
    required this.timestamp,
    this.metadata,
    this.oldValue,
    this.newValue,
  });

  // Create from Firestore DocumentSnapshot
  factory TaskActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskActivityModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      action: data['action'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'],
      oldValue: data['oldValue'],
      newValue: data['newValue'],
    );
  }

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'action': action,
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'oldValue': oldValue,
      'newValue': newValue,
    };
  }

  // Helper: Human-readable description
  String get description {
    switch (action) {
      case 'created':
        return '$userName created this task';
      case 'assigned':
        return '$userName assigned this task';
      case 'status_changed':
        return '$userName changed status from $oldValue to $newValue';
      case 'priority_changed':
        return '$userName changed priority from $oldValue to $newValue';
      case 'started_work':
        return '$userName started working on this task';
      case 'stopped_work':
        return '$userName stopped working';
      case 'submitted':
        return '$userName submitted for review';
      case 'approved':
        return '$userName approved this task';
      case 'rejected':
        return '$userName rejected this task';
      case 'file_uploaded':
        return '$userName uploaded a file';
      case 'comment_added':
        return '$userName added a comment';
      default:
        return '$userName performed $action';
    }
  }

  // Helper: Time ago format
  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
