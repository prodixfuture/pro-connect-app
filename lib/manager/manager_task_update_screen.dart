import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ManagerTaskUpdateScreen extends StatefulWidget {
  const ManagerTaskUpdateScreen({super.key});
  @override
  State<ManagerTaskUpdateScreen> createState() =>
      _ManagerTaskUpdateScreenState();
}

class _ManagerTaskUpdateScreenState extends State<ManagerTaskUpdateScreen> {
  static const _teal = Color(0xFF00897B);
  static const _purple = Color(0xFF5C35CC);

  Map<String, dynamic>? _project;
  Map<String, dynamic>? _task;
  String _status = 'pending';
  bool _saving = false;
  final _noteCtrl = TextEditingController();

  final List<Map<String, dynamic>> _statuses = [
    {
      'v': 'pending',
      'l': 'Pending',
      'i': Icons.hourglass_empty_rounded,
      'c': Colors.blueGrey
    },
    {
      'v': 'work_started',
      'l': 'Work Started',
      'i': Icons.play_circle_rounded,
      'c': Colors.blue
    },
    {
      'v': 'in_progress',
      'l': 'In Progress',
      'i': Icons.sync_rounded,
      'c': Colors.orange
    },
    {
      'v': 'revision',
      'l': 'Revision',
      'i': Icons.edit_rounded,
      'c': Colors.pink
    },
    {
      'v': 'completed',
      'l': 'Completed',
      'i': Icons.check_circle_rounded,
      'c': Colors.green
    },
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _curStatus => _statuses
      .firstWhere((s) => s['v'] == _status, orElse: () => _statuses[0]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Update Task Status',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 17)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_task != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _saving ? null : _updateStatus,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _teal))
                    : const Icon(Icons.check_rounded, color: _teal),
                label: Text(_saving ? 'Saving...' : 'Save',
                    style: const TextStyle(
                        color: _teal, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Step 1: Select Project ─────────────────────────────────────────
          _SectionHeader(
              label: 'Step 1',
              title: 'Select Project',
              icon: Icons.folder_rounded,
              color: _purple),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .orderBy('name')
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData)
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: _teal),
                ));
              final docs = snap.data!.docs;
              return _DropdownCard(
                hint: 'Choose a project...',
                value: _project?['id'],
                items: docs.map((d) {
                  final m = d.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: d.id,
                    child: Row(children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: _purple, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(m['name'] ?? d.id,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500))),
                    ]),
                  );
                }).toList(),
                onChanged: (v) {
                  final doc = docs.firstWhere((d) => d.id == v);
                  setState(() {
                    _project = {
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>
                    };
                    _task = null;
                  });
                },
              );
            },
          ),

          // ── Step 2: Select Task ────────────────────────────────────────────
          if (_project != null) ...[
            const SizedBox(height: 20),
            _SectionHeader(
                label: 'Step 2',
                title: 'Select Task',
                icon: Icons.task_alt_rounded,
                color: Colors.orange),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('projectId', isEqualTo: _project!['id'])
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData)
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: _teal),
                  ));
                final docs = snap.data!.docs;
                if (docs.isEmpty)
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3))),
                    child: const Center(
                        child: Text('No tasks in this project',
                            style: TextStyle(color: Colors.black38))),
                  );
                return _DropdownCard(
                  hint: 'Choose a task...',
                  value: _task?['id'],
                  items: docs.map((d) {
                    final m = d.data() as Map<String, dynamic>;
                    final st = (m['clientStatus'] ?? m['status'] ?? 'pending')
                        .toString();
                    return DropdownMenuItem(
                      value: d.id,
                      child: Row(children: [
                        _StatusDot(status: st),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(m['title'] ?? d.id,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500))),
                      ]),
                    );
                  }).toList(),
                  onChanged: (v) {
                    final doc = docs.firstWhere((d) => d.id == v);
                    final m = doc.data() as Map<String, dynamic>;
                    setState(() {
                      _task = {'id': doc.id, ...m};
                      _status = (m['clientStatus'] ?? m['status'] ?? 'pending')
                          .toString();
                    });
                  },
                );
              },
            ),
          ],

          // ── Task Info Card ─────────────────────────────────────────────────
          if (_task != null) ...[
            const SizedBox(height: 20),
            _TaskInfoCard(task: _task!),

            // ── Step 3: Status ───────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(
                label: 'Step 3',
                title: 'Update Status',
                icon: Icons.update_rounded,
                color: _teal),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2))
                  ]),
              child: Column(children: [
                ..._statuses.map((s) {
                  final selected = _status == s['v'];
                  final c = s['c'] as Color;
                  return GestureDetector(
                    onTap: () => setState(() => _status = s['v'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? c.withOpacity(0.1)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? c : Colors.transparent,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: selected ? c : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s['i'] as IconData,
                              size: 18,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade400),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Text(s['l'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? c : Colors.black54,
                                ))),
                        if (selected)
                          Icon(Icons.check_circle_rounded, color: c, size: 20),
                      ]),
                    ),
                  );
                }),
              ]),
            ),

            // ── Step 4: Note ─────────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(
                label: 'Step 4',
                title: 'Add Note  (Optional)',
                icon: Icons.notes_rounded,
                color: Colors.blueGrey),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2))
                  ]),
              child: TextField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Add a note for the client (e.g. "First draft uploaded")...',
                  hintStyle:
                      const TextStyle(color: Colors.black26, fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            // ── Save Button ──────────────────────────────────────────────────
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _updateStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_curStatus['c'] as Color),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                  shadowColor: (_curStatus['c'] as Color).withOpacity(0.4),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(_curStatus['i'] as IconData, size: 20),
                            const SizedBox(width: 10),
                            Text('Update to "${_curStatus['l']}"',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ]),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ]),
      ),
    );
  }

  Future<void> _updateStatus() async {
    if (_task == null) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final now = Timestamp.now();
      final ref =
          FirebaseFirestore.instance.collection('tasks').doc(_task!['id']);

      await ref.update({
        'clientStatus': _status,
        'clientUpdatedAt': now,
        'clientHistory': FieldValue.arrayUnion([
          {
            'status': _status,
            'note': _noteCtrl.text.trim(),
            'timestamp': now,
            'updatedBy': uid,
          }
        ]),
      });

      final clientId = _task!['clientId'];
      if (clientId != null && clientId.toString().isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': clientId,
          'title': 'Task Update',
          'body': '${_task!['title'] ?? 'Task'} is now ${_curStatus['l']}',
          'createdAt': now,
          'isRead': false,
        });
      }

      if (!mounted) return;
      setState(() {
        _saving = false;
        _noteCtrl.clear();
      });
      _showSuccess();
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showSuccess() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      color: (_curStatus['c'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(_curStatus['i'] as IconData,
                      size: 32, color: _curStatus['c'] as Color),
                ),
                const SizedBox(height: 16),
                const Text('Updated!',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Task status updated to "${_curStatus['l']}"',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _curStatus['c'] as Color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: const Text('Done'),
                  ),
                ),
              ]),
            ));
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label, title;
  final IconData icon;
  final Color color;
  const _SectionHeader(
      {required this.label,
      required this.title,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ]);
}

class _DropdownCard extends StatelessWidget {
  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  const _DropdownCard(
      {required this.hint,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint,
                style: const TextStyle(color: Colors.black38, fontSize: 14)),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.black38),
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
}

class _TaskInfoCard extends StatelessWidget {
  final Map<String, dynamic> task;
  const _TaskInfoCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final status =
        (task['clientStatus'] ?? task['status'] ?? 'pending').toString();
    DateTime? due;
    try {
      due = (task['dueDate'] as Timestamp?)?.toDate();
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF00897B).withOpacity(0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00897B).withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.task_rounded, size: 14, color: Color(0xFF00897B)),
          const SizedBox(width: 6),
          const Text('Selected Task',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF00897B),
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        Text(task['title'] ?? 'Task',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        if ((task['description'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(task['description'],
              style: const TextStyle(fontSize: 12, color: Colors.black45),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 10),
        Wrap(spacing: 12, children: [
          _StatusDot(status: status, showLabel: true),
          if ((task['priority'] ?? '').toString().isNotEmpty)
            _MiniTag(
                icon: Icons.flag_rounded,
                text: task['priority'],
                color: _prColor(task['priority'])),
          if (due != null)
            _MiniTag(
                icon: Icons.calendar_today_rounded,
                text: DateFormat('dd MMM yyyy').format(due),
                color: Colors.black45),
        ]),
      ]),
    );
  }

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
}

class _StatusDot extends StatelessWidget {
  final String status;
  final bool showLabel;
  const _StatusDot({required this.status, this.showLabel = false});

  Color get _c {
    final s = status.toLowerCase();
    if (s.contains('complet')) return Colors.green;
    if (s.contains('revis')) return Colors.pink;
    if (s.contains('progress') || s.contains('start')) return Colors.orange;
    return Colors.blueGrey;
  }

  String get _l => status
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _c, shape: BoxShape.circle)),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(_l,
              style: TextStyle(
                  fontSize: 11, color: _c, fontWeight: FontWeight.w600)),
        ],
      ]);
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MiniTag({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ]);
}
