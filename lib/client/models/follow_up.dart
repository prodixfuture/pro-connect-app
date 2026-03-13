import 'package:cloud_firestore/cloud_firestore.dart';

enum FollowUpType {
  call('call', 'Call'),
  email('email', 'Email'),
  meeting('meeting', 'Meeting'),
  whatsapp('whatsapp', 'WhatsApp');

  final String value;
  final String label;

  const FollowUpType(this.value, this.label);

  static FollowUpType fromValue(String value) {
    return FollowUpType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => FollowUpType.call,
    );
  }
}

enum FollowUpStatus {
  pending('pending', 'Pending'),
  completed('completed', 'Completed'),
  missed('missed', 'Missed'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String label;

  const FollowUpStatus(this.value, this.label);

  static FollowUpStatus fromValue(String value) {
    return FollowUpStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => FollowUpStatus.pending,
    );
  }
}

class FollowUp {
  final String id;
  final String leadId;
  final String leadBusinessName;
  final String assignedTo;
  final String assignedToName;
  final DateTime scheduledDate;
  final FollowUpType followUpType;
  final String? notes;
  final FollowUpStatus status;
  final DateTime? completedAt;
  final String? completedNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOverdue;
  final String priority;

  FollowUp({
    required this.id,
    required this.leadId,
    required this.leadBusinessName,
    required this.assignedTo,
    required this.assignedToName,
    required this.scheduledDate,
    required this.followUpType,
    this.notes,
    required this.status,
    this.completedAt,
    this.completedNotes,
    required this.createdAt,
    required this.updatedAt,
    this.isOverdue = false,
    this.priority = 'warm',
  });

  factory FollowUp.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FollowUp(
      id: doc.id,
      leadId: data['leadId'] ?? '',
      leadBusinessName: data['leadBusinessName'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      assignedToName: data['assignedToName'] ?? '',
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      followUpType: FollowUpType.fromValue(data['followUpType'] ?? 'call'),
      notes: data['notes'],
      status: FollowUpStatus.fromValue(data['status'] ?? 'pending'),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      completedNotes: data['completedNotes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isOverdue: data['isOverdue'] ?? false,
      priority: data['priority'] ?? 'warm',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'leadId': leadId,
      'leadBusinessName': leadBusinessName,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'followUpType': followUpType.value,
      'notes': notes,
      'status': status.value,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedNotes': completedNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isOverdue': isOverdue,
      'priority': priority,
    };
  }

  FollowUp copyWith({
    String? id,
    String? leadId,
    String? leadBusinessName,
    String? assignedTo,
    String? assignedToName,
    DateTime? scheduledDate,
    FollowUpType? followUpType,
    String? notes,
    FollowUpStatus? status,
    DateTime? completedAt,
    String? completedNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOverdue,
    String? priority,
  }) {
    return FollowUp(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      leadBusinessName: leadBusinessName ?? this.leadBusinessName,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      followUpType: followUpType ?? this.followUpType,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      completedNotes: completedNotes ?? this.completedNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOverdue: isOverdue ?? this.isOverdue,
      priority: priority ?? this.priority,
    );
  }
}
