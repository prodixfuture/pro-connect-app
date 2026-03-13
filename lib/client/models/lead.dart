import 'package:cloud_firestore/cloud_firestore.dart';

enum LeadStatus {
  newLead('new', 'New'),
  contacted('contacted', 'Contacted'),
  interested('interested', 'Interested'),
  proposalSent('proposal_sent', 'Proposal Sent'),
  converted('converted', 'Converted'),
  lost('lost', 'Lost');

  final String value;
  final String label;

  const LeadStatus(this.value, this.label);

  static LeadStatus fromValue(String value) {
    return LeadStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => LeadStatus.newLead,
    );
  }
}

enum LeadPriority {
  hot('hot', 'Hot', '🔥'),
  warm('warm', 'Warm', '🌤️'),
  cold('cold', 'Cold', '❄️');

  final String value;
  final String label;
  final String emoji;

  const LeadPriority(this.value, this.label, this.emoji);

  static LeadPriority fromValue(String value) {
    return LeadPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => LeadPriority.cold,
    );
  }
}

enum LeadSource {
  instagram('instagram', 'Instagram'),
  website('website', 'Website'),
  referral('referral', 'Referral'),
  coldCall('cold_call', 'Cold Call'),
  event('event', 'Event'),
  linkedin('linkedin', 'LinkedIn'),
  facebook('facebook', 'Facebook'),
  other('other', 'Other');

  final String value;
  final String label;

  const LeadSource(this.value, this.label);

  static LeadSource fromValue(String value) {
    return LeadSource.values.firstWhere(
      (source) => source.value == value,
      orElse: () => LeadSource.other,
    );
  }
}

class Lead {
  final String id;
  final String businessName;
  final String contactPerson;
  final String phone;
  final String? email;
  final LeadSource leadSource;
  final LeadStatus status;
  final LeadPriority priority;
  final String assignedTo;
  final String assignedToName;
  final String department;
  final String? notes;
  final DateTime? nextFollowUpDate;
  final DateTime? lastContactedDate;
  final double conversionProbability;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? convertedAt;
  final DateTime? lostAt;
  final String? lostReason;
  final double? dealValue;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final bool isFollowUpOverdue;
  final int daysSinceCreated;
  final int daysSinceLastContact;
  final int activityCount;

  Lead({
    required this.id,
    required this.businessName,
    required this.contactPerson,
    required this.phone,
    this.email,
    required this.leadSource,
    required this.status,
    required this.priority,
    required this.assignedTo,
    required this.assignedToName,
    required this.department,
    this.notes,
    this.nextFollowUpDate,
    this.lastContactedDate,
    this.conversionProbability = 50.0,
    required this.createdAt,
    required this.updatedAt,
    this.convertedAt,
    this.lostAt,
    this.lostReason,
    this.dealValue,
    this.tags = const [],
    this.customFields = const {},
    this.isFollowUpOverdue = false,
    this.daysSinceCreated = 0,
    this.daysSinceLastContact = 0,
    this.activityCount = 0,
  });

  factory Lead.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Lead(
      id: doc.id,
      businessName: data['businessName'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      leadSource: LeadSource.fromValue(data['leadSource'] ?? 'other'),
      status: LeadStatus.fromValue(data['status'] ?? 'new'),
      priority: LeadPriority.fromValue(data['priority'] ?? 'cold'),
      assignedTo: data['assignedTo'] ?? '',
      assignedToName: data['assignedToName'] ?? '',
      department: data['department'] ?? 'sales',
      notes: data['notes'],
      nextFollowUpDate: (data['nextFollowUpDate'] as Timestamp?)?.toDate(),
      lastContactedDate: (data['lastContactedDate'] as Timestamp?)?.toDate(),
      conversionProbability: (data['conversionProbability'] ?? 50.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      convertedAt: (data['convertedAt'] as Timestamp?)?.toDate(),
      lostAt: (data['lostAt'] as Timestamp?)?.toDate(),
      lostReason: data['lostReason'],
      dealValue: data['dealValue']?.toDouble(),
      tags: List<String>.from(data['tags'] ?? []),
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
      isFollowUpOverdue: data['isFollowUpOverdue'] ?? false,
      daysSinceCreated: data['daysSinceCreated'] ?? 0,
      daysSinceLastContact: data['daysSinceLastContact'] ?? 0,
      activityCount: data['activityCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessName': businessName,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'leadSource': leadSource.value,
      'status': status.value,
      'priority': priority.value,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'department': department,
      'notes': notes,
      'nextFollowUpDate': nextFollowUpDate != null ? Timestamp.fromDate(nextFollowUpDate!) : null,
      'lastContactedDate': lastContactedDate != null ? Timestamp.fromDate(lastContactedDate!) : null,
      'conversionProbability': conversionProbability,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'convertedAt': convertedAt != null ? Timestamp.fromDate(convertedAt!) : null,
      'lostAt': lostAt != null ? Timestamp.fromDate(lostAt!) : null,
      'lostReason': lostReason,
      'dealValue': dealValue,
      'tags': tags,
      'customFields': customFields,
      'isFollowUpOverdue': isFollowUpOverdue,
      'daysSinceCreated': daysSinceCreated,
      'daysSinceLastContact': daysSinceLastContact,
      'activityCount': activityCount,
    };
  }

  Lead copyWith({
    String? id,
    String? businessName,
    String? contactPerson,
    String? phone,
    String? email,
    LeadSource? leadSource,
    LeadStatus? status,
    LeadPriority? priority,
    String? assignedTo,
    String? assignedToName,
    String? department,
    String? notes,
    DateTime? nextFollowUpDate,
    DateTime? lastContactedDate,
    double? conversionProbability,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? convertedAt,
    DateTime? lostAt,
    String? lostReason,
    double? dealValue,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    bool? isFollowUpOverdue,
    int? daysSinceCreated,
    int? daysSinceLastContact,
    int? activityCount,
  }) {
    return Lead(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      leadSource: leadSource ?? this.leadSource,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      department: department ?? this.department,
      notes: notes ?? this.notes,
      nextFollowUpDate: nextFollowUpDate ?? this.nextFollowUpDate,
      lastContactedDate: lastContactedDate ?? this.lastContactedDate,
      conversionProbability: conversionProbability ?? this.conversionProbability,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      convertedAt: convertedAt ?? this.convertedAt,
      lostAt: lostAt ?? this.lostAt,
      lostReason: lostReason ?? this.lostReason,
      dealValue: dealValue ?? this.dealValue,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      isFollowUpOverdue: isFollowUpOverdue ?? this.isFollowUpOverdue,
      daysSinceCreated: daysSinceCreated ?? this.daysSinceCreated,
      daysSinceLastContact: daysSinceLastContact ?? this.daysSinceLastContact,
      activityCount: activityCount ?? this.activityCount,
    );
  }
}
