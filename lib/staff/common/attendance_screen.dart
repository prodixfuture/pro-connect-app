import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  bool loading = true;
  bool punchedIn = false;
  bool punchedOut = false;

  late String docId;
  Map<String, dynamic>? todayData;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  String today() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadToday() async {
    docId = '${uid}_${today()}';

    final doc = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(docId)
        .get();

    if (doc.exists) {
      todayData = doc.data();
      punchedIn = todayData!['punchIn'] != null;
      punchedOut = todayData!['punchOut'] != null;
    }

    setState(() => loading = false);
  }

  Future<void> punchIn() async {
    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'uid': uid,
      'date': today(),
      'punchIn': FieldValue.serverTimestamp(),
      'punchOut': null,
    });

    _loadToday();
  }

  Future<void> punchOut() async {
    await FirebaseFirestore.instance.collection('attendance').doc(docId).update(
      {'punchOut': FieldValue.serverTimestamp()},
    );

    _loadToday();
  }

  String _duration(Map<String, dynamic> data) {
    if (data['punchIn'] == null || data['punchOut'] == null) {
      return '--';
    }

    final inTime = (data['punchIn'] as Timestamp).toDate();
    final outTime = (data['punchOut'] as Timestamp).toDate();
    final diff = outTime.difference(inTime);

    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔹 Today Attendance Card
                Card(
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          punchedOut
                              ? 'Completed'
                              : punchedIn
                              ? 'Punched In'
                              : 'Not Marked',
                        ),
                        const SizedBox(height: 12),

                        if (!punchedIn)
                          ElevatedButton(
                            onPressed: punchIn,
                            child: const Text('Punch In'),
                          ),

                        if (punchedIn && !punchedOut)
                          ElevatedButton(
                            onPressed: punchOut,
                            child: const Text('Punch Out'),
                          ),

                        if (punchedIn && punchedOut)
                          Text(
                            'Work Duration: ${_duration(todayData!)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ),

                // 🔹 History
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Attendance History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('attendance')
                        .where('uid', isEqualTo: uid)
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No attendance records'),
                        );
                      }

                      return ListView(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          return ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(data['date']),
                            subtitle: Text(
                              data['punchOut'] != null
                                  ? 'Duration: ${_duration(data)}'
                                  : 'In progress',
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
