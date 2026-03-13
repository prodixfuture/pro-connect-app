import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task/create_task_screen.dart';
import 'task/staff_task_list.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(data['description']),
                const SizedBox(height: 16),

                DropdownButton<String>(
                  value: data['status'],
                  items: const [
                    DropdownMenuItem(value: 'started', child: Text('Started')),
                    DropdownMenuItem(
                      value: 'revision',
                      child: Text('Revision'),
                    ),
                    DropdownMenuItem(
                      value: 'delivered',
                      child: Text('Delivered'),
                    ),
                  ],
                  onChanged: (v) async {
                    await FirebaseFirestore.instance
                        .collection('projects')
                        .doc(projectId)
                        .update({'status': v});
                  },
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  child: const Text('Add Task'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateTaskScreen(projectId: projectId),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
                Expanded(child: StaffTaskList(projectId: projectId)),
              ],
            ),
          );
        },
      ),
    );
  }
}
