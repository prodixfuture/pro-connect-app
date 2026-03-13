import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/dashboard_metrics.dart';

// Dashboard Metrics Provider
final dashboardMetricsProvider = StateNotifierProvider<DashboardMetricsNotifier,
    AsyncValue<DashboardMetrics>>((ref) {
  return DashboardMetricsNotifier();
});

class DashboardMetricsNotifier
    extends StateNotifier<AsyncValue<DashboardMetrics>> {
  DashboardMetricsNotifier() : super(const AsyncValue.loading()) {
    loadMetrics();
  }

  final _firestore = FirebaseFirestore.instance;

  Future<void> loadMetrics() async {
    state = const AsyncValue.loading();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        state = AsyncValue.data(DashboardMetrics.empty());
        return;
      }

      // Check cache first
      final cached = await _getCachedMetrics(userId);
      if (cached != null && cached.isValid) {
        state = AsyncValue.data(cached);
        return;
      }

      // Calculate real-time metrics
      final metrics = await _calculateMetrics(userId);

      // Update cache
      await _updateCache(userId, metrics);

      state = AsyncValue.data(metrics);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshMetrics() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final metrics = await _calculateMetrics(userId);
      await _updateCache(userId, metrics);
      state = AsyncValue.data(metrics);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<DashboardMetrics> _calculateMetrics(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get all leads for this user
    final leadsSnapshot = await _firestore
        .collection('leads')
        .where('assignedTo', isEqualTo: userId)
        .get();

    final allLeads = leadsSnapshot.docs;

    // Calculate metrics
    final totalLeads = allLeads.length;

    final newLeadsToday = allLeads.where((doc) {
      final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
      return createdAt != null &&
          createdAt.isAfter(startOfDay) &&
          createdAt.isBefore(endOfDay);
    }).length;

    final convertedLeads = allLeads.where((doc) {
      return doc.data()['status'] == 'converted';
    }).length;

    final conversionRate =
        totalLeads > 0 ? (convertedLeads / totalLeads) * 100 : 0.0;

    // Get follow-ups due today
    final followUpsSnapshot = await _firestore
        .collection('follow_ups')
        .where('assignedTo', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .where('scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledDate', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final followUpsDueToday = followUpsSnapshot.docs.length;

    // Status breakdown
    final statusBreakdown = <String, int>{
      'new': 0,
      'contacted': 0,
      'interested': 0,
      'proposal_sent': 0,
      'converted': 0,
      'lost': 0,
    };

    for (final doc in allLeads) {
      final status = doc.data()['status'] as String?;
      if (status != null && statusBreakdown.containsKey(status)) {
        statusBreakdown[status] = statusBreakdown[status]! + 1;
      }
    }

    return DashboardMetrics(
      totalLeads: totalLeads,
      newLeadsToday: newLeadsToday,
      followUpsDueToday: followUpsDueToday,
      convertedLeads: convertedLeads,
      conversionRate: conversionRate,
      statusBreakdown: statusBreakdown,
      lastUpdated: DateTime.now(),
    );
  }

  Future<DashboardMetrics?> _getCachedMetrics(String userId) async {
    try {
      final doc =
          await _firestore.collection('dashboard_cache').doc(userId).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['metrics'] != null) {
          return DashboardMetrics.fromMap(data['metrics']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateCache(String userId, DashboardMetrics metrics) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore.collection('dashboard_cache').doc(userId).set({
        'date': dateKey,
        'metrics': metrics.toMap(),
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silent fail for cache
    }
  }
}
