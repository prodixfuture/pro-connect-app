import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffTaskList extends StatelessWidget {
  final String projectId;
  const StaffTaskList({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('tasks')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                title: Text(data['title']),
                subtitle: Text('Status: ${data['status']}'),
                trailing: DropdownButton<String>(
                  value: data['status'],
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'working', child: Text('Working')),
                    DropdownMenuItem(value: 'done', child: Text('Done')),
                  ],
                  onChanged: (v) async {
                    await doc.reference.update({'status': v});
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
