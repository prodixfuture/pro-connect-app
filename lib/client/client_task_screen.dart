// UPDATED CLIENT TASK SCREEN - NO PENDING + MODERN UI
// File: lib/modules/task_management/screens/client/client_task_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ClientTaskScreen extends StatefulWidget {
  final String clientId;
  const ClientTaskScreen({super.key, required this.clientId});
  @override
  State<ClientTaskScreen> createState() => _ClientTaskScreenState();
}

class _ClientTaskScreenState extends State<ClientTaskScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String _search = '';
  static const _teal = Color(0xFF00897B);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this); // Changed to 3 tabs
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String _bucket(dynamic s) {
    final st = (s ?? '').toString().toLowerCase();
    if (st.contains('complet') || st == 'done') return 'completed';
    if (st.contains('revis')) return 'revision';
    if (st.contains('progress') || st.contains('start') || st.contains('work'))
      return 'active';
    return 'pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Tasks',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(children: [
            TabBar(
              controller: _tab,
              isScrollable: false,
              labelColor: _teal,
              unselectedLabelColor: Colors.black38,
              indicatorColor: _teal,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: '🔄 Working'),
                Tab(text: '✏️ Revision'),
                Tab(text: '✅ Done'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search task, project...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                ),
              ),
            ),
          ]),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: FirebaseFirestore.instance
            .collection('projects')
            .where('clientId', isEqualTo: widget.clientId)
            .get()
            .then((s) => s.docs.map((d) => d.id).toList()),
        builder: (_, projectSnap) {
          if (projectSnap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator(color: _teal));

          final projectIds = projectSnap.data ?? [];

          if (projectIds.isEmpty)
            return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.folder_off_rounded, size: 64, color: Colors.black12),
              SizedBox(height: 12),
              Text('No projects assigned',
                  style: TextStyle(color: Colors.black38)),
            ]));

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('projectId', whereIn: projectIds.take(10).toList())
                .snapshots(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting)
                return const Center(
                    child: CircularProgressIndicator(color: _teal));

              if (snap.hasError)
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error: ${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                    ]),
                  ),
                );

              var all = (snap.data?.docs ?? [])
                  .map((d) => <String, dynamic>{
                        'id': d.id,
                        ...d.data() as Map<String, dynamic>
                      })
                  .toList();

              // Filter out pending tasks - only show started/active/revision/completed
              all = all.where((t) {
                final status = (t['clientStatus'] ?? t['status'] ?? '')
                    .toString()
                    .toLowerCase();
                return !status.contains('pending') && status.isNotEmpty;
              }).toList();

              // Client-side sort
              all.sort((a, b) {
                Timestamp? ta, tb;
                try {
                  ta = (a['clientUpdatedAt'] ?? a['updatedAt']) as Timestamp?;
                } catch (_) {}
                try {
                  tb = (b['clientUpdatedAt'] ?? b['updatedAt']) as Timestamp?;
                } catch (_) {}
                if (ta == null && tb == null) return 0;
                if (ta == null) return 1;
                if (tb == null) return -1;
                return tb.compareTo(ta);
              });

              if (_search.isNotEmpty) {
                final q = _search.toLowerCase();
                all = all
                    .where((t) =>
                        (t['title'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q) ||
                        (t['projectName'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q))
                    .toList();
              }

              String getStatus(Map t) =>
                  (t['clientStatus'] ?? t['status'] ?? '').toString();
              final active =
                  all.where((t) => _bucket(getStatus(t)) == 'active').toList();
              final revision = all
                  .where((t) => _bucket(getStatus(t)) == 'revision')
                  .toList();
              final completed = all
                  .where((t) => _bucket(getStatus(t)) == 'completed')
                  .toList();

              return Column(children: [
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    _CountChip(
                        label: 'Working',
                        n: active.length,
                        color: Colors.orange),
                    const SizedBox(width: 8),
                    _CountChip(
                        label: 'Revision',
                        n: revision.length,
                        color: Colors.pink),
                    const SizedBox(width: 8),
                    _CountChip(
                        label: 'Done',
                        n: completed.length,
                        color: Colors.green),
                  ]),
                ),
                Expanded(
                    child: TabBarView(
                  controller: _tab,
                  children: [
                    _TaskList(tasks: active),
                    _TaskList(tasks: revision),
                    _TaskList(tasks: completed),
                  ],
                )),
              ]);
            },
          );
        },
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty)
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.task_alt_rounded, size: 64, color: Colors.black12),
        SizedBox(height: 10),
        Text('No tasks here', style: TextStyle(color: Colors.black38)),
      ]));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _TaskCard(data: tasks[i]),
    );
  }
}

class _TaskCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _TaskCard({required this.data});
  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _showFullLog = false;

  Color _stColor(String s) {
    final st = s.toLowerCase();
    if (st.contains('complet') || st == 'done') return Colors.green;
    if (st.contains('revis')) return Colors.pink;
    if (st.contains('progress') || st.contains('start') || st.contains('work'))
      return Colors.orange;
    return Colors.blueGrey;
  }

  String _stLabel(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  Color _prColor(dynamic p) {
    switch ((p ?? '').toString().toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final status =
        (d['clientStatus'] ?? d['status'] ?? 'in_progress').toString();
    final sc = _stColor(status);
    final sl = _stLabel(status);

    DateTime? dueDate;
    try {
      dueDate = (d['dueDate'] as Timestamp?)?.toDate();
    } catch (_) {}
    DateTime? updatedAt;
    try {
      updatedAt =
          ((d['clientUpdatedAt'] ?? d['updatedAt']) as Timestamp?)?.toDate();
    } catch (_) {}

    final history =
        List<Map>.from(d['clientHistory'] ?? d['statusHistory'] ?? []);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [sc.withOpacity(0.1), sc.withOpacity(0.05)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(d['title'] ?? 'Task',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sc,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(sl,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ]),
            if ((d['projectName'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.folder_outlined, size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Text(d['projectName'],
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
              ]),
            ],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if ((d['description'] ?? '').toString().isNotEmpty) ...[
              Text(d['description'],
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54, height: 1.5)),
              const SizedBox(height: 14),
            ],
            Wrap(spacing: 12, runSpacing: 8, children: [
              if ((d['assignedTo'] ?? '').toString().isNotEmpty)
                _Tag(
                    icon: Icons.person_outline_rounded,
                    text: d['assignedTo'],
                    color: Colors.blue),
              if ((d['priority'] ?? '').toString().isNotEmpty)
                _Tag(
                    icon: Icons.flag_rounded,
                    text: d['priority'],
                    color: _prColor(d['priority'])),
              if (dueDate != null)
                _Tag(
                  icon: Icons.calendar_today_rounded,
                  text: DateFormat('dd MMM yyyy').format(dueDate),
                  color: dueDate.isBefore(DateTime.now()) &&
                          !status.contains('complet')
                      ? Colors.red
                      : Colors.black45,
                ),
            ]),
            const SizedBox(height: 16),
            _ImprovedTimeline(currentStatus: status, history: history),
            if (history.length > 1) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _showFullLog = !_showFullLog),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            _showFullLog
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 18,
                            color: Colors.black38),
                        const SizedBox(width: 6),
                        Text(
                            _showFullLog
                                ? 'Hide activity log'
                                : 'Show activity log (${history.length})',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black38,
                                fontWeight: FontWeight.w500)),
                      ]),
                ),
              ),
              if (_showFullLog) ...[
                const Divider(height: 24),
                _ActivityLog(history: history),
              ],
            ],
            if (updatedAt != null) ...[
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.update_rounded,
                    size: 12, color: Colors.black26),
                const SizedBox(width: 4),
                Text(
                    'Updated ${DateFormat('dd MMM yyyy, hh:mm a').format(updatedAt)}',
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black26)),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _ImprovedTimeline extends StatelessWidget {
  final String currentStatus;
  final List<Map> history;
  const _ImprovedTimeline({required this.currentStatus, required this.history});

  static const _steps = [
    {'k': 'work_started', 'l': 'Started', 'i': Icons.play_circle_outline},
    {'k': 'in_progress', 'l': 'Working', 'i': Icons.sync},
    {'k': 'review', 'l': 'Review', 'i': Icons.rate_review_outlined},
    {'k': 'completed', 'l': 'Completed', 'i': Icons.check_circle_outline},
  ];

  int get _curIdx {
    final st = currentStatus.toLowerCase();
    if (st.contains('complet') || st == 'done') return 3;
    if (st.contains('review') || st.contains('submit')) return 2;
    if (st.contains('progress')) return 1;
    if (st.contains('start') || st == 'work_started') return 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cur = _curIdx;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Row(
            children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final done = (i ~/ 2) < cur;
            return Expanded(
                child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color:
                          done ? const Color(0xFF00897B) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    )));
          }
          final idx = i ~/ 2;
          final step = _steps[idx];
          final done = idx < cur;
          final isCur = idx == cur;
          final c =
              done || isCur ? const Color(0xFF00897B) : Colors.grey.shade300;

          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCur
                    ? const Color(0xFF00897B)
                    : done
                        ? const Color(0xFF00897B).withOpacity(0.15)
                        : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: c, width: 2),
              ),
              child: Icon(step['i'] as IconData,
                  size: 16,
                  color: isCur
                      ? Colors.white
                      : done
                          ? const Color(0xFF00897B)
                          : Colors.grey.shade400),
            ),
            const SizedBox(height: 6),
            Text(step['l'] as String,
                style: TextStyle(
                    fontSize: 10,
                    color: isCur || done
                        ? const Color(0xFF00897B)
                        : Colors.black38,
                    fontWeight: isCur ? FontWeight.bold : FontWeight.w500)),
          ]);
        })),
      ]),
    );
  }
}

class _ActivityLog extends StatelessWidget {
  final List<Map> history;
  const _ActivityLog({required this.history});

  Color _color(String s) {
    final st = s.toLowerCase();
    if (st.contains('complet') || st == 'done') return Colors.green;
    if (st.contains('revis')) return Colors.pink;
    if (st.contains('progress') || st.contains('start') || st.contains('work'))
      return Colors.orange;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<Map>.from(history);
    try {
      sorted.sort((a, b) {
        final ta = (a['timestamp'] as Timestamp?);
        final tb = (b['timestamp'] as Timestamp?);
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });
    } catch (_) {}

    return Column(
        children: sorted.asMap().entries.map((entry) {
      final isLast = entry.key == sorted.length - 1;
      final h = entry.value;
      final st = (h['status'] ?? '').toString();
      final sc = _color(st);
      final sl = st
          .split('_')
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
      DateTime? ts;
      try {
        ts = (h['timestamp'] as Timestamp?)?.toDate();
      } catch (_) {}
      final note = (h['note'] ?? h['comment'] ?? '').toString().trim();

      return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 24,
              child: Column(children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: sc,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    )),
                if (!isLast)
                  Expanded(
                      child: Container(width: 2, color: Colors.grey.shade200)),
              ])),
          const SizedBox(width: 12),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(sl,
                    style: TextStyle(
                        fontSize: 12, color: sc, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (ts != null)
                  Text(DateFormat('dd MMM, hh:mm a').format(ts),
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black26)),
              ]),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(note,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54)),
                ),
              ],
            ]),
          )),
        ]),
      );
    }).toList());
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Tag({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(text.toString(),
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ]),
      );
}

class _CountChip extends StatelessWidget {
  final String label;
  final int n;
  final Color color;
  const _CountChip({required this.label, required this.n, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
          child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Text('$n',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ]),
      ));
}
