import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Settings state
  bool _taskUpdates = true;
  bool _leaveUpdates = true;
  bool _payments = true;
  bool _messages = true;
  bool _announcements = true;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc =
          await _firestore.collection('notification_settings').doc(_uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _taskUpdates = data['taskUpdates'] ?? true;
          _leaveUpdates = data['leaveUpdates'] ?? true;
          _payments = data['payments'] ?? true;
          _messages = data['messages'] ?? true;
          _announcements = data['announcements'] ?? true;
        });
      }
    } catch (e) {
      _showError('Failed to load settings');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _firestore.collection('notification_settings').doc(_uid).set({
        'uid': _uid,
        'taskUpdates': _taskUpdates,
        'leaveUpdates': _leaveUpdates,
        'payments': _payments,
        'messages': _messages,
        'announcements': _announcements,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to save settings');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        title: const Text('Notification Settings'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card
                Card(
                  elevation: 0,
                  color: colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage Notifications',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose which updates you want to receive.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onPrimaryContainer
                                      .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Settings section
                _buildSection(
                  title: 'Work & Tasks',
                  items: [
                    _SettingItem(
                      icon: Icons.task_alt_rounded,
                      color: const Color(0xFF6366F1),
                      title: 'Task Updates',
                      subtitle: 'New assignments, completions & deadlines',
                      value: _taskUpdates,
                      onChanged: (v) => setState(() => _taskUpdates = v),
                    ),
                    _SettingItem(
                      icon: Icons.event_available_rounded,
                      color: const Color(0xFF10B981),
                      title: 'Leave Updates',
                      subtitle: 'Leave approvals, rejections & requests',
                      value: _leaveUpdates,
                      onChanged: (v) => setState(() => _leaveUpdates = v),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSection(
                  title: 'Finance',
                  items: [
                    _SettingItem(
                      icon: Icons.payments_rounded,
                      color: const Color(0xFFF59E0B),
                      title: 'Payment Alerts',
                      subtitle: 'Invoices created & payments received',
                      value: _payments,
                      onChanged: (v) => setState(() => _payments = v),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSection(
                  title: 'Communication',
                  items: [
                    _SettingItem(
                      icon: Icons.message_rounded,
                      color: const Color(0xFF3B82F6),
                      title: 'Messages',
                      subtitle: 'Direct messages from managers & team',
                      value: _messages,
                      onChanged: (v) => setState(() => _messages = v),
                    ),
                    _SettingItem(
                      icon: Icons.campaign_rounded,
                      color: const Color(0xFFEF4444),
                      title: 'System Announcements',
                      subtitle: 'Company-wide updates & announcements',
                      value: _announcements,
                      onChanged: (v) => setState(() => _announcements = v),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _taskUpdates = false;
                            _leaveUpdates = false;
                            _payments = false;
                            _messages = false;
                            _announcements = false;
                          });
                        },
                        icon: const Icon(Icons.notifications_off_outlined),
                        label: const Text('Mute All'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            _taskUpdates = true;
                            _leaveUpdates = true;
                            _payments = true;
                            _messages = true;
                            _announcements = true;
                          });
                        },
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Enable All'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_SettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildTile(item),
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(_SettingItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(item.icon, color: item.color, size: 22),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        item.subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: item.value,
        onChanged: item.onChanged,
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}
