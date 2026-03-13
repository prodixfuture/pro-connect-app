// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../chat/client_chat_screen.dart';

// class ProjectDetailScreen extends StatelessWidget {
//   final String projectId;
//   const ProjectDetailScreen({super.key, required this.projectId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Project Details')),
//       body: FutureBuilder<DocumentSnapshot>(
//         future: FirebaseFirestore.instance
//             .collection('projects')
//             .doc(projectId)
//             .get(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final data = snapshot.data!.data() as Map<String, dynamic>;

//           return Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   data['title'],
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(data['description'] ?? ''),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Status: ${data['status']}',
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 24),

//                 ElevatedButton.icon(
//                   icon: const Icon(Icons.chat),
//                   label: const Text('Chat with Manager'),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) =>
//                             ClientChatScreen(managerId: data['managerId']),
//                       ),
//                     );
//                   },
//                 ),

//                 if (data['status'] == 'delivered')
//                   ElevatedButton(
//                     onPressed: () async {
//                       await FirebaseFirestore.instance
//                           .collection('projects')
//                           .doc(projectId)
//                           .update({'status': 'revision'});
//                     },
//                     child: const Text('Request Revision'),
//                   ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
