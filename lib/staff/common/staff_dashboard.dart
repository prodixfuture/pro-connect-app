import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key, required Widget child});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final today = _today();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Attendance Card
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('attendance')
                  .doc('${uid}_$today')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _cardSkeleton();
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _statusCard(
                    title: 'Today Attendance',
                    subtitle: 'Not marked yet',
                    icon: Icons.fingerprint,
                    color: Colors.orange,
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;

                return _statusCard(
                  title: 'Today Attendance',
                  subtitle:
                      data['punchOut'] != null ? 'Completed' : 'Punch In Done',
                  icon: Icons.check_circle,
                  color: Colors.green,
                );
              },
            ),

            const SizedBox(height: 16),

            // 🔹 Leave Summary
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('leaves')
                  .where('uid', isEqualTo: uid)
                  .orderBy('appliedAt', descending: true)
                  .limit(1)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _cardSkeleton();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _statusCard(
                    title: 'Leave Status',
                    subtitle: 'No leave applied',
                    icon: Icons.event_note,
                    color: Colors.blueGrey,
                  );
                }

                final leave =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;

                return _statusCard(
                  title: 'Leave Status',
                  subtitle:
                      'Last leave: ${leave['status'].toString().toUpperCase()}',
                  icon: Icons.event_available,
                  color: leave['status'] == 'approved'
                      ? Colors.green
                      : leave['status'] == 'rejected'
                          ? Colors.red
                          : Colors.orange,
                );
              },
            ),

            const SizedBox(height: 16),

            // 🔹 Tasks Placeholder (future ready)
            _statusCard(
              title: 'My Tasks',
              subtitle: 'Task system enabled',
              icon: Icons.task_alt,
              color: Colors.purple,
            ),

            const SizedBox(height: 16),

            // 🔹 Salary Placeholder
            _statusCard(
              title: 'Salary',
              subtitle: 'View salary details',
              icon: Icons.account_balance_wallet,
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI COMPONENTS ----------

  Widget _statusCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _cardSkeleton() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const ListTile(
        leading: CircleAvatar(backgroundColor: Colors.grey),
        title: Text('Loading...'),
        subtitle: Text('Please wait'),
      ),
    );
  }

  static String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
