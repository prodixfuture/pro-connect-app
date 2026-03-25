import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfficeTimingSettingsScreen extends StatefulWidget {
  const OfficeTimingSettingsScreen({Key? key}) : super(key: key);

  @override
  State<OfficeTimingSettingsScreen> createState() =>
      _OfficeTimingSettingsScreenState();
}

class _OfficeTimingSettingsScreenState
    extends State<OfficeTimingSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isSaving = false;

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _lateTime = const TimeOfDay(hour: 9, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  Map<String, dynamic>? _currentSettings;

  @override
  void initState() {
    super.initState();
    _loadTimingSettings();
  }

  Future<void> _loadTimingSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doc =
          await _firestore.collection('settings').doc('office_timing').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _currentSettings = data;

          // Parse saved times
          if (data['startTime'] != null) {
            _startTime = _parseTimeOfDay(data['startTime']);
          }
          if (data['lateTime'] != null) {
            _lateTime = _parseTimeOfDay(data['lateTime']);
          }
          if (data['endTime'] != null) {
            _endTime = _parseTimeOfDay(data['endTime']);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Error loading settings: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    // Expected format: "HH:mm" or "H:mm"
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeDisplay(TimeOfDay time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _selectTime(String type) async {
    TimeOfDay initialTime;
    String title;

    switch (type) {
      case 'start':
        initialTime = _startTime;
        title = 'Select Start Time';
        break;
      case 'late':
        initialTime = _lateTime;
        title = 'Select Late Time';
        break;
      case 'end':
        initialTime = _endTime;
        title = 'Select End Time';
        break;
      default:
        return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: title,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5C6BC0),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'start':
            _startTime = picked;
            // Validate: late time should be after start time
            if (_lateTime.hour < _startTime.hour ||
                (_lateTime.hour == _startTime.hour &&
                    _lateTime.minute <= _startTime.minute)) {
              _lateTime = TimeOfDay(
                  hour: _startTime.hour, minute: _startTime.minute + 30);
            }
            break;
          case 'late':
            _lateTime = picked;
            break;
          case 'end':
            _endTime = picked;
            break;
        }
      });
    }
  }

  Future<void> _saveTimingSettings() async {
    // Validate times
    if (_lateTime.hour < _startTime.hour ||
        (_lateTime.hour == _startTime.hour &&
            _lateTime.minute <= _startTime.minute)) {
      _showSnackBar('Late time must be after start time', Colors.orange);
      return;
    }

    if (_endTime.hour < _lateTime.hour ||
        (_endTime.hour == _lateTime.hour &&
            _endTime.minute <= _lateTime.minute)) {
      _showSnackBar('End time must be after late time', Colors.orange);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore.collection('settings').doc('office_timing').set({
        'startTime': _formatTimeOfDay(_startTime),
        'lateTime': _formatTimeOfDay(_lateTime),
        'endTime': _formatTimeOfDay(_endTime),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'Admin',
      });

      setState(() {
        _currentSettings = {
          'startTime': _formatTimeOfDay(_startTime),
          'lateTime': _formatTimeOfDay(_lateTime),
          'endTime': _formatTimeOfDay(_endTime),
        };
      });

      _showSnackBar('Office timing saved successfully! ✓', Colors.green);
    } catch (e) {
      _showSnackBar('Error saving settings: $e', Colors.red);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Timing Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Configure office working hours. Staff punching in after late time will be marked as "Late"',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Current Settings
                  if (_currentSettings != null) ...[
                    const Text(
                      'Current Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Settings Active',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildCurrentTimingRow(
                              'Start Time', _formatTimeDisplay(_startTime)),
                          const SizedBox(height: 8),
                          _buildCurrentTimingRow(
                              'Late After', _formatTimeDisplay(_lateTime)),
                          const SizedBox(height: 8),
                          _buildCurrentTimingRow(
                              'End Time', _formatTimeDisplay(_endTime)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'No office timing configured yet',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Configure New Timing
                  const Text(
                    'Configure Office Timing',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Start Time
                  _buildTimeCard(
                    icon: Icons.wb_sunny,
                    iconColor: const Color(0xFF66BB6A),
                    title: 'Start Time',
                    subtitle: 'Office working hours begin',
                    time: _startTime,
                    onTap: () => _selectTime('start'),
                  ),

                  const SizedBox(height: 12),

                  // Late Time
                  _buildTimeCard(
                    icon: Icons.warning,
                    iconColor: const Color(0xFFFFA726),
                    title: 'Late After',
                    subtitle: 'Mark as late after this time',
                    time: _lateTime,
                    onTap: () => _selectTime('late'),
                  ),

                  const SizedBox(height: 12),

                  // End Time
                  _buildTimeCard(
                    icon: Icons.nights_stay,
                    iconColor: const Color(0xFF5C6BC0),
                    title: 'End Time',
                    subtitle: 'Standard office closing time',
                    time: _endTime,
                    onTap: () => _selectTime('end'),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTimingSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save Office Timing',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Example Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Example',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildExampleRow(
                            'Punch in at 8:45 AM', 'On Time ✓', Colors.green),
                        const SizedBox(height: 8),
                        _buildExampleRow(
                            'Punch in at 9:35 AM', 'Late ⚠', Colors.orange),
                        const SizedBox(height: 8),
                        _buildExampleRow(
                            'Punch out at 6:30 PM', 'Overtime 🌙', Colors.blue),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTimeDisplay(time),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF5C6BC0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to change',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTimingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildExampleRow(String scenario, String result, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            scenario,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const Icon(Icons.arrow_forward, size: 16),
        const SizedBox(width: 8),
        Text(
          result,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
