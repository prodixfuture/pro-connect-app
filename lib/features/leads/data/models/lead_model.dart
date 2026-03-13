import 'package:cloud_firestore/cloud_firestore.dart';

class LeadModel {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String status;
  final String assignedTo;
  final DateTime createdAt;

  LeadModel({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.status,
    required this.assignedTo,
    required this.createdAt,
  });

  factory LeadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LeadModel(
      id: doc.id,
      name: data['name'],
      contactPerson: data['contactPerson'],
      phone: data['phone'],
      status: data['status'],
      assignedTo: data['assignedTo'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
