// COMPLETE TASK SERVICE
// File: lib/modules/task_management/services/task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../models/task_comment_model.dart';
import '../models/task_activity_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _tasksCollection => _firestore.collection('tasks');
  CollectionReference get _commentsCollection =>
      _firestore.collection('task_comments');
  CollectionReference get _activityCollection =>
      _firestore.collection('task_activity');

  // ==================== CREATE TASK ====================
  Future<String> createTask({
    required String projectId,
    required String title,
    required String description,
    required String assignedTo,
    String priority = 'medium',
    double? estimatedHours,
    DateTime? dueDate,
    List<String>? tags,
    String? designType,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final task = TaskModel(
        id: '',
        projectId: projectId,
        title: title,
        description: description,
        assignedTo: assignedTo,
        assignedBy: userId,
        priority: priority,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        estimatedHours: estimatedHours,
        dueDate: dueDate,
        tags: tags,
        designType: designType,
      );

      final docRef = await _tasksCollection.add(task.toFirestore());

      await _logActivity(taskId: docRef.id, action: 'created', userId: userId);
      await _sendTaskNotification(
        userId: assignedTo,
        title: 'New Task Assigned',
        message: 'You have been assigned: $title',
        taskId: docRef.id,
      );

      return docRef.id;
    } catch (e) {
      throw 'Failed to create task: $e';
    }
  }

  // ==================== UPDATE TASK ====================
  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? priority,
    String? status,
    double? estimatedHours,
    DateTime? dueDate,
    List<String>? tags,
    List<TaskAttachment>? attachments,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (priority != null) updates['priority'] = priority;
      if (status != null) updates['status'] = status;
      if (estimatedHours != null) updates['estimatedHours'] = estimatedHours;
      if (dueDate != null) updates['dueDate'] = Timestamp.fromDate(dueDate);
      if (tags != null) updates['tags'] = tags;
      if (attachments != null) {
        updates['attachments'] = attachments.map((e) => e.toMap()).toList();
      }

      await _tasksCollection.doc(taskId).update(updates);

      if (status != null) {
        await _logActivity(
          taskId: taskId,
          action: 'status_changed',
          userId: userId,
          newValue: status,
        );
      }
    } catch (e) {
      throw 'Failed to update task: $e';
    }
  }

  // ==================== START TASK TIMER ====================
  Future<void> startTask(String taskId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      await _tasksCollection.doc(taskId).update({
        'startTime': FieldValue.serverTimestamp(),
        'status': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logActivity(
          taskId: taskId, action: 'started_work', userId: userId);
    } catch (e) {
      throw 'Failed to start task: $e';
    }
  }

  // ==================== STOP TASK TIMER ====================
  Future<void> stopTask(String taskId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final taskDoc = await _tasksCollection.doc(taskId).get();
      final taskData = taskDoc.data() as Map<String, dynamic>;

      if (taskData['startTime'] != null) {
        final startTime = (taskData['startTime'] as Timestamp).toDate();
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        final hours = duration.inMinutes / 60.0;
        final currentActualHours = (taskData['actualHours'] ?? 0.0);

        await _tasksCollection.doc(taskId).update({
          'endTime': Timestamp.fromDate(endTime),
          'actualHours': currentActualHours + hours,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _logActivity(
          taskId: taskId,
          action: 'stopped_work',
          userId: userId,
          metadata: {'hours': hours},
        );
      }
    } catch (e) {
      throw 'Failed to stop task: $e';
    }
  }

  // ==================== SUBMIT TASK ====================
  Future<void> submitTask(String taskId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      await _tasksCollection.doc(taskId).update({
        'status': 'review',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logActivity(taskId: taskId, action: 'submitted', userId: userId);

      final taskDoc = await _tasksCollection.doc(taskId).get();
      final taskData = taskDoc.data() as Map<String, dynamic>;
      final managerId = taskData['assignedBy'];

      await _sendTaskNotification(
        userId: managerId,
        title: 'Task Submitted for Review',
        message: '${taskData['title']} has been submitted',
        taskId: taskId,
      );
    } catch (e) {
      throw 'Failed to submit task: $e';
    }
  }

  // ==================== APPROVE TASK ====================
  Future<void> approveTask(String taskId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      await _tasksCollection.doc(taskId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logActivity(taskId: taskId, action: 'approved', userId: userId);

      final taskDoc = await _tasksCollection.doc(taskId).get();
      final taskData = taskDoc.data() as Map<String, dynamic>;

      await _sendTaskNotification(
        userId: taskData['assignedTo'],
        title: 'Task Approved',
        message: 'Your task "${taskData['title']}" has been approved!',
        taskId: taskId,
      );
    } catch (e) {
      throw 'Failed to approve task: $e';
    }
  }

  // ==================== REJECT TASK ====================
  Future<void> rejectTask(String taskId, String reason) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final taskDoc = await _tasksCollection.doc(taskId).get();
      final currentRevisions =
          (taskDoc.data() as Map<String, dynamic>)['revisionCount'] ?? 0;

      await _tasksCollection.doc(taskId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'revisionCount': currentRevisions + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logActivity(
        taskId: taskId,
        action: 'rejected',
        userId: userId,
        metadata: {'reason': reason},
      );

      final taskData = taskDoc.data() as Map<String, dynamic>;
      await _sendTaskNotification(
        userId: taskData['assignedTo'],
        title: 'Task Needs Revision',
        message: 'Your task "${taskData['title']}" needs changes',
        taskId: taskId,
      );
    } catch (e) {
      throw 'Failed to reject task: $e';
    }
  }

  // ==================== ADD COMMENT ====================
  Future<void> addComment({
    required String taskId,
    required String message,
    String? attachment,
    String? attachmentType,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      final comment = TaskCommentModel(
        id: '',
        taskId: taskId,
        userId: userId,
        userName: userData['name'] ?? 'Unknown',
        userRole: userData['role'] ?? 'staff',
        message: message,
        attachment: attachment,
        attachmentType: attachmentType,
        createdAt: DateTime.now(),
      );

      await _commentsCollection.add(comment.toFirestore());
      await _logActivity(
          taskId: taskId, action: 'comment_added', userId: userId);
    } catch (e) {
      throw 'Failed to add comment: $e';
    }
  }

  // ==================== DELETE TASK ====================
  Future<void> deleteTask(String taskId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      // Delete all comments
      final commentsSnapshot =
          await _commentsCollection.where('taskId', isEqualTo: taskId).get();

      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all activity
      final activitySnapshot =
          await _activityCollection.where('taskId', isEqualTo: taskId).get();

      for (var doc in activitySnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete task
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      throw 'Failed to delete task: $e';
    }
  }

  // ==================== STREAM OPERATIONS ====================

  Stream<TaskModel> streamTask(String taskId) {
    return _tasksCollection.doc(taskId).snapshots().map((doc) {
      if (!doc.exists) throw 'Task not found';
      return TaskModel.fromFirestore(doc);
    });
  }

  Stream<List<TaskModel>> streamTasksByDesigner(String designerId) {
    return _tasksCollection
        .where('assignedTo', isEqualTo: designerId)
        .where('department', isEqualTo: 'design')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  Stream<List<TaskModel>> streamTasksByProject(String projectId) {
    return _tasksCollection
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  Stream<List<TaskModel>> streamTasksByStatus(String status, String userId) {
    return _tasksCollection
        .where('assignedTo', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  Stream<List<TaskModel>> streamTodayTasks(String designerId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _tasksCollection
        .where('assignedTo', isEqualTo: designerId)
        .where('dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dueDate', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  Stream<List<TaskCommentModel>> streamComments(String taskId) {
    return _commentsCollection
        .where('taskId', isEqualTo: taskId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskCommentModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<TaskActivityModel>> streamActivity(String taskId) {
    return _activityCollection
        .where('taskId', isEqualTo: taskId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskActivityModel.fromFirestore(doc))
            .toList());
  }

  // ==================== GET STATISTICS ====================

  Future<Map<String, dynamic>> getDesignerStats(String designerId) async {
    try {
      final tasksSnapshot = await _tasksCollection
          .where('assignedTo', isEqualTo: designerId)
          .get();

      final tasks = tasksSnapshot.docs;
      final totalTasks = tasks.length;
      final completedTasks =
          tasks.where((doc) => doc['status'] == 'completed').length;
      final inProgressTasks =
          tasks.where((doc) => doc['status'] == 'in_progress').length;
      final pendingTasks =
          tasks.where((doc) => doc['status'] == 'pending').length;

      double totalHoursWorked = 0;
      for (var doc in tasks) {
        totalHoursWorked +=
            ((doc.data() as Map<String, dynamic>)['actualHours'] ?? 0.0);
      }

      final completionRate =
          totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'inProgressTasks': inProgressTasks,
        'pendingTasks': pendingTasks,
        'totalHoursWorked': totalHoursWorked,
        'completionRate': completionRate,
      };
    } catch (e) {
      throw 'Failed to get designer stats: $e';
    }
  }

  // ==================== PRIVATE HELPERS ====================

  Future<void> _logActivity({
    required String taskId,
    required String action,
    required String userId,
    String? oldValue,
    String? newValue,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName =
          (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';

      final activity = TaskActivityModel(
        id: '',
        taskId: taskId,
        action: action,
        userId: userId,
        userName: userName,
        timestamp: DateTime.now(),
        oldValue: oldValue,
        newValue: newValue,
        metadata: metadata,
      );

      await _activityCollection.add(activity.toFirestore());
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }

  Future<void> _sendTaskNotification({
    required String userId,
    required String title,
    required String message,
    required String taskId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': 'task',
        'referenceId': taskId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }
}
