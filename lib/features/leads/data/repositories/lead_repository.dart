import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lead_model.dart';

class LeadRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<LeadModel>> getMyLeads(String uid) {
    return _db
        .collection('leads')
        .where('assignedTo', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => LeadModel.fromFirestore(d)).toList());
  }

  Future<void> addLead(Map<String, dynamic> data) {
    return _db.collection('leads').add(data);
  }

  Future<void> updateLead(String id, Map<String, dynamic> data) {
    return _db.collection('leads').doc(id).update(data);
  }
}
