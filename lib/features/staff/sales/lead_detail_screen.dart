import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../client/models/lead.dart';

class LeadDetailScreen extends StatelessWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leads')
          .doc(leadId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final lead = Lead.fromFirestore(snapshot.data!);

        return Scaffold(
          appBar: AppBar(title: const Text('Lead Details')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(lead.businessName,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(lead.contactPerson, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makeCall(lead.phone),
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openWhatsApp(lead.phone),
                      icon: const Icon(Icons.chat),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone'),
                  subtitle: Text(lead.phone),
                ),
              ),
              if (lead.email != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(lead.email!),
                  ),
                ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Status'),
                  subtitle: Text(lead.status.label),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _makeCall(String phone) async {
    // Implement call functionality
  }

  void _openWhatsApp(String phone) async {
    // Implement WhatsApp functionality
  }
}
