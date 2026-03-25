import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardMetrics {
  final int totalLeads;
  final int newLeadsToday;
  final int followUpsDueToday;
  final int convertedLeads;
  final double conversionRate;
  final Map<String, int> statusBreakdown;
  final DateTime lastUpdated;

  DashboardMetrics({
    required this.totalLeads,
    required this.newLeadsToday,
    required this.followUpsDueToday,
    required this.convertedLeads,
    required this.conversionRate,
    required this.statusBreakdown,
    required this.lastUpdated,
  });

  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      totalLeads: 0,
      newLeadsToday: 0,
      followUpsDueToday: 0,
      convertedLeads: 0,
      conversionRate: 0.0,
      statusBreakdown: {
        'new': 0,
        'contacted': 0,
        'interested': 0,
        'proposal_sent': 0,
        'converted': 0,
        'lost': 0,
      },
      lastUpdated: DateTime.now(),
    );
  }

  factory DashboardMetrics.fromMap(Map<String, dynamic> data) {
    return DashboardMetrics(
      totalLeads: data['totalLeads'] ?? 0,
      newLeadsToday: data['newLeadsToday'] ?? 0,
      followUpsDueToday: data['followUpsDueToday'] ?? 0,
      convertedLeads: data['convertedLeads'] ?? 0,
      conversionRate: (data['conversionRate'] ?? 0.0).toDouble(),
      statusBreakdown: Map<String, int>.from(data['statusBreakdown'] ?? {}),
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalLeads': totalLeads,
      'newLeadsToday': newLeadsToday,
      'followUpsDueToday': followUpsDueToday,
      'convertedLeads': convertedLeads,
      'conversionRate': conversionRate,
      'statusBreakdown': statusBreakdown,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  bool get isValid {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inMinutes < 15; // Valid for 15 minutes
  }

  get previousTotalLeads => null;

  get previousConvertedLeads => null;

  get previousConversionRate => null;
}

class LeadFilter {
  final String? status;
  final String? priority;
  final String? source;
  final DateTime? fromDate;
  final DateTime? toDate;
  final SortOption sortBy;

  LeadFilter({
    this.status,
    this.priority,
    this.source,
    this.fromDate,
    this.toDate,
    this.sortBy = SortOption.latest,
  });

  LeadFilter copyWith({
    String? status,
    String? priority,
    String? source,
    DateTime? fromDate,
    DateTime? toDate,
    SortOption? sortBy,
  }) {
    return LeadFilter(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      source: source ?? this.source,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

enum SortOption {
  latest,
  oldest,
  followUpDue,
  priority,
}
