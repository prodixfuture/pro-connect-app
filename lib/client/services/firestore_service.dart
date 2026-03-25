import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lead.dart';
import '../models/follow_up.dart';
import '../models/lead_activity.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _leadsCollection => _firestore.collection('leads');
  CollectionReference get _followUpsCollection => _firestore.collection('follow_ups');
  CollectionReference get _activitiesCollection => _firestore.collection('lead_activities');
  CollectionReference get _dashboardCacheCollection => _firestore.collection('dashboard_cache');

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName ?? 'User';

  // LEADS
  
  Future<String> createLead(Lead lead) async {
    try {
      final docRef = await _leadsCollection.add(lead.toFirestore());
      
      // Create initial activity
      await _createActivity(
        leadId: docRef.id,
        leadBusinessName: lead.businessName,
        activityType: ActivityType.noteAdded,
        description: 'Lead created',
      );
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create lead: $e');
    }
  }

  Future<void> updateLead(String leadId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _leadsCollection.doc(leadId).update(updates);
    } catch (e) {
      throw Exception('Failed to update lead: $e');
    }
  }

  Future<void> updateLeadStatus(String leadId, String leadName, LeadStatus oldStatus, LeadStatus newStatus) async {
    try {
      final updates = {
        'status': newStatus.value,
        'updatedAt': Timestamp.now(),
      };

      if (newStatus == LeadStatus.converted) {
        updates['convertedAt'] = Timestamp.now();
      } else if (newStatus == LeadStatus.lost) {
        updates['lostAt'] = Timestamp.now();
      }

      await _leadsCollection.doc(leadId).update(updates);

      // Create activity
      await _createActivity(
        leadId: leadId,
        leadBusinessName: leadName,
        activityType: ActivityType.statusChange,
        description: 'Status changed from ${oldStatus.label} to ${newStatus.label}',
        metadata: {
          'previousStatus': oldStatus.value,
          'newStatus': newStatus.value,
        },
      );
    } catch (e) {
      throw Exception('Failed to update lead status: $e');
    }
  }

  Future<void> deleteLead(String leadId) async {
    try {
      await _leadsCollection.doc(leadId).delete();
    } catch (e) {
      throw Exception('Failed to delete lead: $e');
    }
  }

  Stream<List<Lead>> getLeadsStream({String? statusFilter}) {
    Query query = _leadsCollection
        .where('assignedTo', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true);

    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Lead.fromFirestore(doc)).toList();
    });
  }

  Future<Lead?> getLeadById(String leadId) async {
    try {
      final doc = await _leadsCollection.doc(leadId).get();
      if (doc.exists) {
        return Lead.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch lead: $e');
    }
  }

  // FOLLOW-UPS
  
  Future<String> createFollowUp(FollowUp followUp) async {
    try {
      final docRef = await _followUpsCollection.add(followUp.toFirestore());
      
      // Update lead's next follow-up date
      await _leadsCollection.doc(followUp.leadId).update({
        'nextFollowUpDate': Timestamp.fromDate(followUp.scheduledDate),
        'updatedAt': Timestamp.now(),
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create follow-up: $e');
    }
  }

  Future<void> updateFollowUp(String followUpId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _followUpsCollection.doc(followUpId).update(updates);
    } catch (e) {
      throw Exception('Failed to update follow-up: $e');
    }
  }

  Future<void> completeFollowUp(String followUpId, String leadId, String leadName, String notes) async {
    try {
      await _followUpsCollection.doc(followUpId).update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'completedNotes': notes,
        'updatedAt': Timestamp.now(),
      });

      // Update lead's last contacted date
      await _leadsCollection.doc(leadId).update({
        'lastContactedDate': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Create activity
      await _createActivity(
        leadId: leadId,
        leadBusinessName: leadName,
        activityType: ActivityType.followUpCompleted,
        description: 'Follow-up completed: $notes',
      );
    } catch (e) {
      throw Exception('Failed to complete follow-up: $e');
    }
  }

  Stream<List<FollowUp>> getFollowUpsStream({bool todayOnly = false}) {
    Query query = _followUpsCollection
        .where('assignedTo', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('scheduledDate');

    if (todayOnly) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      query = query
          .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledDate', isLessThan: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FollowUp.fromFirestore(doc)).toList();
    });
  }

  // ACTIVITIES
  
  Future<void> _createActivity({
    required String leadId,
    required String leadBusinessName,
    required ActivityType activityType,
    required String description,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final activity = LeadActivity(
        id: '',
        leadId: leadId,
        leadBusinessName: leadBusinessName,
        activityType: activityType,
        description: description,
        performedBy: currentUserId!,
        performedByName: currentUserName!,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      await _activitiesCollection.add(activity.toFirestore());

      // Increment activity count on lead
      await _leadsCollection.doc(leadId).update({
        'activityCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      // Silent fail - activity logging shouldn't block main operations
      print('Failed to create activity: $e');
    }
  }

  Stream<List<LeadActivity>> getActivitiesStream(String leadId) {
    return _activitiesCollection
        .where('leadId', isEqualTo: leadId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => LeadActivity.fromFirestore(doc)).toList();
    });
  }

  // NOTES
  
  Future<void> addNote(String leadId, String leadName, String note) async {
    try {
      await _leadsCollection.doc(leadId).update({
        'notes': note,
        'updatedAt': Timestamp.now(),
      });

      await _createActivity(
        leadId: leadId,
        leadBusinessName: leadName,
        activityType: ActivityType.noteAdded,
        description: note,
      );
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  // DASHBOARD CACHE
  
  Future<void> updateDashboardCache(String userId, Map<String, dynamic> metrics) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _dashboardCacheCollection.doc(userId).set({
        'date': dateKey,
        'metrics': metrics,
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Failed to update dashboard cache: $e');
    }
  }

  Future<Map<String, dynamic>?> getDashboardCache(String userId) async {
    try {
      final doc = await _dashboardCacheCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Failed to fetch dashboard cache: $e');
      return null;
    }
  }
}
