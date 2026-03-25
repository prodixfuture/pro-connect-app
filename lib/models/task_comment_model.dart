// STEP 1.3: TASK COMMENT MODEL
// File: lib/modules/task_management/models/task_comment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCommentModel {
  final String id;
  final String taskId;
  final String userId;
  final String userName; // Cached for performance
  final String userRole; // Cached for UI
  final String message;
  final String? attachment; // URL if comment has attachment
  final String? attachmentType; // image, pdf, etc.
  final DateTime createdAt;
  final bool isEdited;
  final DateTime? editedAt;

  TaskCommentModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.message,
    this.attachment,
    this.attachmentType,
    required this.createdAt,
    this.isEdited = false,
    this.editedAt,
  });

  // Create from Firestore DocumentSnapshot
  factory TaskCommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskCommentModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userRole: data['userRole'] ?? '',
      message: data['message'] ?? '',
      attachment: data['attachment'],
      attachmentType: data['attachmentType'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isEdited: data['isEdited'] ?? false,
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'message': message,
      'attachment': attachment,
      'attachmentType': attachmentType,
      'createdAt': Timestamp.fromDate(createdAt),
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  // CopyWith method
  TaskCommentModel copyWith({
    String? id,
    String? taskId,
    String? userId,
    String? userName,
    String? userRole,
    String? message,
    String? attachment,
    String? attachmentType,
    DateTime? createdAt,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return TaskCommentModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      message: message ?? this.message,
      attachment: attachment ?? this.attachment,
      attachmentType: attachmentType ?? this.attachmentType,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  // Helper: Time ago format
  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
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
