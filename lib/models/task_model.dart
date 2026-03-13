// STEP 1.2: TASK MODEL
// File: lib/modules/task_management/models/task_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String assignedTo; // Designer user ID
  final String assignedBy; // Manager user ID
  final String department; // Always "design"
  final String priority; // low, medium, high, urgent
  final String status; // pending, in_progress, review, completed, rejected
  final DateTime? startTime;
  final DateTime? endTime;
  final double? estimatedHours;
  final double? actualHours;
  final List<TaskAttachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final String? rejectionReason;
  final List<String>? tags;
  final int? revisionCount;
  final String? designType; // logo, banner, illustration, ui_ux, etc.

  TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedBy,
    this.department = 'design',
    this.priority = 'medium',
    this.status = 'pending',
    this.startTime,
    this.endTime,
    this.estimatedHours,
    this.actualHours,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.rejectionReason,
    this.tags,
    this.revisionCount = 0,
    this.designType,
  });

  // Create from Firestore DocumentSnapshot
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      assignedBy: data['assignedBy'] ?? '',
      department: data['department'] ?? 'design',
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'pending',
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : null,
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      estimatedHours: data['estimatedHours']?.toDouble(),
      actualHours: data['actualHours']?.toDouble(),
      attachments: data['attachments'] != null
          ? (data['attachments'] as List)
              .map((e) => TaskAttachment.fromMap(e))
              .toList()
          : [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      rejectionReason: data['rejectionReason'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      revisionCount: data['revisionCount'] ?? 0,
      designType: data['designType'],
    );
  }

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'department': department,
      'priority': priority,
      'status': status,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'estimatedHours': estimatedHours,
      'actualHours': actualHours,
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'rejectionReason': rejectionReason,
      'tags': tags,
      'revisionCount': revisionCount,
      'designType': designType,
    };
  }

  // CopyWith method
  TaskModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? assignedTo,
    String? assignedBy,
    String? department,
    String? priority,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    double? estimatedHours,
    double? actualHours,
    List<TaskAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    String? rejectionReason,
    List<String>? tags,
    int? revisionCount,
    String? designType,
  }) {
    return TaskModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedBy: assignedBy ?? this.assignedBy,
      department: department ?? this.department,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      tags: tags ?? this.tags,
      revisionCount: revisionCount ?? this.revisionCount,
      designType: designType ?? this.designType,
    );
  }

  // Helper: Task is overdue
  bool get isOverdue =>
      dueDate != null &&
      DateTime.now().isAfter(dueDate!) &&
      status != 'completed';

  // Helper: Task is in progress
  bool get isInProgress => status == 'in_progress';

  // Helper: Task is completed
  bool get isCompleted => status == 'completed';

  // Helper: Task is pending
  bool get isPending => status == 'pending';

  // Helper: Task is in review
  bool get isInReview => status == 'review';

  // Helper: Hours remaining until due date
  int get hoursRemaining {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inHours;
  }

  // Helper: Progress percentage
  double get progressPercentage {
    if (estimatedHours == null || actualHours == null) return 0;
    return (actualHours! / estimatedHours! * 100).clamp(0, 100);
  }
}

// Task Attachment Sub-Model
class TaskAttachment {
  final String fileName;
  final String fileUrl;
  final String fileType; // image, pdf, zip, etc.
  final int fileSize; // in bytes
  final DateTime uploadedAt;
  final String uploadedBy;

  TaskAttachment({
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory TaskAttachment.fromMap(Map<String, dynamic> map) {
    return TaskAttachment(
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: map['uploadedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': uploadedBy,
    };
  }

  // Helper: Format file size
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
