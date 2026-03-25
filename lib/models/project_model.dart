// STEP 1.1: PROJECT MODEL
// File: lib/modules/task_management/models/project_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String name;
  final String clientName;
  final DateTime deadline;
  final String createdBy;
  final String managerId;
  final DateTime createdAt;
  final String status; // active, completed, on_hold, cancelled
  final String? description;
  final double? budget;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  ProjectModel({
    required this.id,
    required this.name,
    required this.clientName,
    required this.deadline,
    required this.createdBy,
    required this.managerId,
    required this.createdAt,
    this.status = 'active',
    this.description,
    this.budget,
    this.tags,
    this.metadata,
  });

  // Create from Firestore DocumentSnapshot
  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      name: data['name'] ?? '',
      clientName: data['clientName'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      managerId: data['managerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
      description: data['description'],
      budget: data['budget']?.toDouble(),
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      metadata: data['metadata'],
    );
  }

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'clientName': clientName,
      'deadline': Timestamp.fromDate(deadline),
      'createdBy': createdBy,
      'managerId': managerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'description': description,
      'budget': budget,
      'tags': tags,
      'metadata': metadata,
    };
  }

  // CopyWith method for updates
  ProjectModel copyWith({
    String? id,
    String? name,
    String? clientName,
    DateTime? deadline,
    String? createdBy,
    String? managerId,
    DateTime? createdAt,
    String? status,
    String? description,
    double? budget,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      deadline: deadline ?? this.deadline,
      createdBy: createdBy ?? this.createdBy,
      managerId: managerId ?? this.managerId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper: Check if project is overdue
  bool get isOverdue =>
      DateTime.now().isAfter(deadline) && status != 'completed';

  // Helper: Days remaining until deadline
  int get daysRemaining => deadline.difference(DateTime.now()).inDays;

  // Helper: Project is active
  bool get isActive => status == 'active';

  String? get clientId => null;
}
