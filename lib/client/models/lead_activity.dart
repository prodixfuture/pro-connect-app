import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  statusChange('status_change', 'Status Changed'),
  noteAdded('note_added', 'Note Added'),
  followUpCompleted('follow_up_completed', 'Follow-up Completed'),
  call('call', 'Call Made'),
  email('email', 'Email Sent'),
  meeting('meeting', 'Meeting Held'),
  whatsapp('whatsapp', 'WhatsApp Message');

  final String value;
  final String label;

  const ActivityType(this.value, this.label);

  static ActivityType fromValue(String value) {
    return ActivityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ActivityType.noteAdded,
    );
  }
}

class LeadActivity {
  final String id;
  final String leadId;
  final String leadBusinessName;
  final ActivityType activityType;
  final String description;
  final String performedBy;
  final String performedByName;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  LeadActivity({
    required this.id,
    required this.leadId,
    required this.leadBusinessName,
    required this.activityType,
    required this.description,
    required this.performedBy,
    required this.performedByName,
    this.metadata = const {},
    required this.createdAt,
  });

  factory LeadActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return LeadActivity(
      id: doc.id,
      leadId: data['leadId'] ?? '',
      leadBusinessName: data['leadBusinessName'] ?? '',
      activityType: ActivityType.fromValue(data['activityType'] ?? 'note_added'),
      description: data['description'] ?? '',
      performedBy: data['performedBy'] ?? '',
      performedByName: data['performedByName'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'leadId': leadId,
      'leadBusinessName': leadBusinessName,
      'activityType': activityType.value,
      'description': description,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
