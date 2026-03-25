// CONTENT CALENDAR MANAGER SCREEN WITH MONTHLY CALENDAR
// File: lib/modules/manager/screens/content_calendar_manager.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // Add to pubspec.yaml: table_calendar: ^3.0.9

class ContentCalendarManager extends StatefulWidget {
  const ContentCalendarManager({Key? key}) : super(key: key);

  @override
  State<ContentCalendarManager> createState() => _ContentCalendarManagerState();
}

class _ContentCalendarManagerState extends State<ContentCalendarManager> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Content Calendar'),
        backgroundColor: Color(0xFF9C27B0),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'client')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final clients = snapshot.data?.docs ?? [];

          if (clients.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              final clientData = client.data() as Map<String, dynamic>;
              return _buildClientCard(client.id, clientData);
            },
          );
        },
      ),
    );
  }

  Widget _buildClientCard(String clientId, Map<String, dynamic> clientData) {
    final name = clientData['name'] ?? 'Unnamed Client';
    final email = clientData['email'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientCalendarView(
                clientId: clientId,
                clientName: name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('content_calendar')
                    .where('clientId', isEqualTo: clientId)
                    .snapshots(),
                builder: (context, snap) {
                  final count = snap.data?.docs.length ?? 0;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF9C27B0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9C27B0),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'No clients found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CLIENT CALENDAR VIEW
// ══════════════════════════════════════════════════════════════════════════════

class ClientCalendarView extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientCalendarView({
    Key? key,
    required this.clientId,
    required this.clientName,
  }) : super(key: key);

  @override
  State<ClientCalendarView> createState() => _ClientCalendarViewState();
}

class _ClientCalendarViewState extends State<ClientCalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.clientName),
        backgroundColor: Color(0xFF9C27B0),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('content_calendar')
            .where('clientId', isEqualTo: widget.clientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          _buildEventsMap(snapshot.data?.docs ?? []);

          return Column(
            children: [
              _buildCalendar(),
              SizedBox(height: 8),
              Expanded(child: _buildNextSchedule()),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreate(),
        backgroundColor: Color(0xFF9C27B0),
        icon: Icon(Icons.add),
        label: Text('Schedule Content'),
      ),
    );
  }

  void _buildEventsMap(List<QueryDocumentSnapshot> docs) {
    _events.clear();
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final scheduledDate = (data['scheduledDate'] as Timestamp?)?.toDate();
      if (scheduledDate == null) continue;

      final dateKey = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
      );

      if (!_events.containsKey(dateKey)) {
        _events[dateKey] = [];
      }
      _events[dateKey]!.add({...data, 'id': doc.id});
    }
  }

  Widget _buildCalendar() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) {
          final dateKey = DateTime(day.year, day.month, day.day);
          return _events[dateKey] ?? [];
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Color(0xFFBA68C8).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Color(0xFF9C27B0),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Color(0xFFFF6F00),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildNextSchedule() {
    // Get upcoming events
    final now = DateTime.now();
    final upcomingEvents = <Map<String, dynamic>>[];

    _events.forEach((date, events) {
      if (date.isAfter(now) || isSameDay(date, now)) {
        for (var event in events) {
          upcomingEvents.add({...event, 'date': date});
        }
      }
    });

    upcomingEvents.sort((a, b) {
      final aDate = a['date'] as DateTime;
      final bDate = b['date'] as DateTime;
      return aDate.compareTo(bDate);
    });

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: upcomingEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available,
                            size: 48, color: Colors.grey[300]),
                        SizedBox(height: 12),
                        Text(
                          'No upcoming schedule',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: upcomingEvents.length,
                    itemBuilder: (context, index) {
                      final event = upcomingEvents[index];
                      return _buildScheduleCard(event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> event) {
    final date = event['date'] as DateTime;
    final title = event['title'] ?? 'Content';
    final platform = event['platform'] ?? '';
    final status = (event['status'] ?? 'scheduled').toString().toLowerCase();

    final scheduledDate = (event['scheduledDate'] as Timestamp?)?.toDate();
    final dayName = DateFormat('EEE').format(date);
    final day = date.day.toString();
    final timeRange = scheduledDate != null
        ? '${DateFormat('hh:mm a').format(scheduledDate)} - ${DateFormat('hh:mm a').format(scheduledDate.add(Duration(hours: 1)))}'
        : '';

    Color statusColor;
    if (status == 'published') {
      statusColor = Color(0xFF4CAF50);
    } else if (status == 'approved') {
      statusColor = Color(0xFF2196F3);
    } else {
      statusColor = Color(0xFF9C27B0);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  timeRange,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                if (platform.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      platform,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateContentScreen(
          clientId: widget.clientId,
          clientName: widget.clientName,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CREATE CONTENT SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class CreateContentScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const CreateContentScreen({
    Key? key,
    required this.clientId,
    required this.clientName,
  }) : super(key: key);

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedPlatform = 'facebook';
  String _selectedContentType = 'post';
  String _selectedStatus = 'scheduled';
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _platforms = [
    {
      'id': 'facebook',
      'name': 'Facebook',
      'icon': Icons.facebook,
      'color': Color(0xFF1877F2)
    },
    {
      'id': 'instagram',
      'name': 'Instagram',
      'icon': Icons.camera_alt,
      'color': Color(0xFFE4405F)
    },
    {
      'id': 'twitter',
      'name': 'Twitter',
      'icon': Icons.tag,
      'color': Color(0xFF1DA1F2)
    },
    {
      'id': 'linkedin',
      'name': 'LinkedIn',
      'icon': Icons.work,
      'color': Color(0xFF0A66C2)
    },
    {
      'id': 'youtube',
      'name': 'YouTube',
      'icon': Icons.play_circle_filled,
      'color': Color(0xFFFF0000)
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Schedule Content'),
        backgroundColor: Color(0xFF9C27B0),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildClientInfo(),
            SizedBox(height: 20),
            _buildTitleField(),
            SizedBox(height: 16),
            _buildDescriptionField(),
            SizedBox(height: 20),
            _buildPlatformSelector(),
            SizedBox(height: 20),
            _buildContentTypeSelector(),
            SizedBox(height: 20),
            _buildDateTimePicker(),
            SizedBox(height: 20),
            _buildStatusSelector(),
            SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.clientName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scheduling for',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  widget.clientName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Content Title *',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v?.trim().isEmpty ?? true ? 'Title required' : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: 4,
    );
  }

  Widget _buildPlatformSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform *', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _platforms.map((p) {
              final selected = _selectedPlatform == p['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedPlatform = p['id']),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? p['color'] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(p['icon'],
                          size: 18,
                          color: selected ? Colors.white : Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        p['name'],
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeSelector() {
    final types = ['post', 'story', 'video', 'article', 'reel'];
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Content Type', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: types.map((t) {
              final selected = _selectedContentType == t;
              return GestureDetector(
                onTap: () => setState(() => _selectedContentType = t),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? Color(0xFF9C27B0) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    t[0].toUpperCase() + t.substring(1),
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule Date & Time *',
              style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 20, color: Color(0xFF9C27B0)),
                        SizedBox(width: 10),
                        Text(DateFormat('dd MMM yyyy').format(_scheduledDate),
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
                  child: Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 20, color: Color(0xFF9C27B0)),
                        SizedBox(width: 10),
                        Text(_scheduledTime.format(context),
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    final statuses = [
      {'id': 'scheduled', 'name': 'Scheduled', 'color': Color(0xFF9C27B0)},
      {'id': 'approved', 'name': 'Approved', 'color': Color(0xFF2196F3)},
      {'id': 'published', 'name': 'Published', 'color': Color(0xFF4CAF50)},
    ];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: statuses.map((s) {
              final selected = _selectedStatus == s['id'] as String;
              final statusId = s['id'] as String;
              final statusName = s['name'] as String;
              final statusColor = s['color'] as Color;

              return GestureDetector(
                onTap: () => setState(() => _selectedStatus = statusId),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? statusColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusName,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitContent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF9C27B0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text('Schedule Content',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<void> _submitContent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final scheduledDateTime = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

      await FirebaseFirestore.instance.collection('content_calendar').add({
        'clientId': widget.clientId,
        'clientName': widget.clientName,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'platform': _selectedPlatform,
        'contentType': _selectedContentType,
        'scheduledDate': Timestamp.fromDate(scheduledDateTime),
        'status': _selectedStatus,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': widget.clientId,
        'title': 'New Content Scheduled',
        'body':
            'A new $_selectedContentType has been scheduled for ${DateFormat('dd MMM').format(scheduledDateTime)}',
        'type': 'content',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Content scheduled!'), backgroundColor: Colors.green),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
