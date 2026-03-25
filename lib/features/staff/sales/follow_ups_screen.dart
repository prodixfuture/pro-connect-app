import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowUpsScreen extends StatelessWidget {
  const FollowUpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Follow-ups')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('follow_ups')
            .where('assignedTo', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .orderBy('scheduledDate')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No follow-ups scheduled'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return Card(
                child: ListTile(
                  title: Text(doc['leadBusinessName']),
                  subtitle: Text('Scheduled: ${doc['scheduledDate'].toDate()}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      // Mark as completed
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
