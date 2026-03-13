import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/lead.dart';
import '../services/firestore_service.dart';

// All Leads Provider (with filters)
final leadsProvider =
    StreamProvider.family<List<Lead>, LeadFilter>((ref, filter) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value([]);

  Query query = FirebaseFirestore.instance
      .collection('leads')
      .where('assignedTo', isEqualTo: userId);

  // Apply status filter
  if (filter.status != null && filter.status != 'all') {
    query = query.where('status', isEqualTo: filter.status);
  }

  // Apply sorting
  switch (filter.sortBy) {
    case SortOption.latest:
      query = query.orderBy('createdAt', descending: true);
      break;
    case SortOption.oldest:
      query = query.orderBy('createdAt', descending: false);
      break;
    case SortOption.followUpDue:
      query = query.orderBy('nextFollowUpDate', descending: false);
      break;
    case SortOption.priority:
      query = query.orderBy('priority', descending: true);
      break;
  }

  return query.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Lead.fromFirestore(doc)).toList();
  });
});

// Recent Leads Provider (last 10)
final recentLeadsProvider =
    StateNotifierProvider<RecentLeadsNotifier, AsyncValue<List<Lead>>>((ref) {
  return RecentLeadsNotifier();
});

class RecentLeadsNotifier extends StateNotifier<AsyncValue<List<Lead>>> {
  RecentLeadsNotifier() : super(const AsyncValue.loading()) {
    loadRecentLeads();
  }

  final _firestore = FirebaseFirestore.instance;

  Future<void> loadRecentLeads() async {
    state = const AsyncValue.loading();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final snapshot = await _firestore
          .collection('leads')
          .where('assignedTo', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final leads =
          snapshot.docs.map((doc) => Lead.fromFirestore(doc)).toList();

      state = AsyncValue.data(leads);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadRecentLeads();
  }
}

// Single Lead Provider
final leadDetailProvider = StreamProvider.family<Lead?, String>((ref, leadId) {
  return FirebaseFirestore.instance
      .collection('leads')
      .doc(leadId)
      .snapshots()
      .map((doc) {
    if (doc.exists) {
      return Lead.fromFirestore(doc);
    }
    return null;
  });
});

// Lead Actions Notifier
class LeadActionsNotifier extends StateNotifier<AsyncValue<void>> {
  LeadActionsNotifier() : super(const AsyncValue.data(null));

  final _firestoreService = FirestoreService();

  Future<void> createLead(Lead lead) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.createLead(lead);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateLead(String leadId, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateLead(leadId, updates);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteLead(String leadId) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.deleteLead(leadId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateStatus(String leadId, String leadName,
      LeadStatus newStatus, LeadStatus oldStatus) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateLeadStatus(
          leadId, leadName, oldStatus, newStatus);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final leadActionsProvider =
    StateNotifierProvider<LeadActionsNotifier, AsyncValue<void>>((ref) {
  return LeadActionsNotifier();
});

// Lead Filter Class (already exists in dashboard_metrics.dart but repeated here for clarity)
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
