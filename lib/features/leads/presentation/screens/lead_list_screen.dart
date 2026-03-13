import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/lead_repository.dart';
import '../widgets/lead_card.dart';

class LeadListScreen extends StatelessWidget {
  LeadListScreen({super.key});

  final repo = LeadRepository();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Leads')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-lead');
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: repo.getMyLeads(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final leads = snapshot.data!;

          if (leads.isEmpty) {
            return const Center(child: Text('No leads yet'));
          }

          return ListView.builder(
            itemCount: leads.length,
            itemBuilder: (context, index) {
              return LeadCard(lead: leads[index]);
            },
          );
        },
      ),
    );
  }
}
