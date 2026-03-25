// CONTENT CALENDAR CREATION SCREEN (MANAGER)
// File: lib/modules/manager/screens/create_content_calendar.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreateContentCalendarScreen extends StatefulWidget {
  const CreateContentCalendarScreen({Key? key}) : super(key: key);

  @override
  State<CreateContentCalendarScreen> createState() =>
      _CreateContentCalendarScreenState();
}

class _CreateContentCalendarScreenState
    extends State<CreateContentCalendarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedClientId;
  String? _selectedClientName;
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
      'name': 'Twitter/X',
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

  final List<Map<String, String>> _contentTypes = [
    {'id': 'post', 'name': 'Post'},
    {'id': 'story', 'name': 'Story'},
    {'id': 'video', 'name': 'Video'},
    {'id': 'article', 'name': 'Article'},
    {'id': 'reel', 'name': 'Reel'},
  ];

  final List<Map<String, dynamic>> _statuses = [
    {'id': 'scheduled', 'name': 'Scheduled', 'color': Color(0xFF9C27B0)},
    {'id': 'approved', 'name': 'Approved', 'color': Color(0xFF2196F3)},
    {'id': 'published', 'name': 'Published', 'color': Color(0xFF4CAF50)},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Create Content Schedule'),
        backgroundColor: Color(0xFF9C27B0),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildClientSelector(),
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

  Widget _buildClientSelector() {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Client *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
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
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No clients found',
                    style: TextStyle(color: Colors.orange[900]),
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                value: _selectedClientId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                hint: Text('Choose a client'),
                items: clients.map((client) {
                  final data = client.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: client.id,
                    child: Text(data['name'] ?? 'Unnamed Client'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClientId = value;
                    final client = clients.firstWhere((c) => c.id == value);
                    _selectedClientName =
                        (client.data() as Map<String, dynamic>)['name'];
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a client' : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Title *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: 'Enter content title',
            ),
            validator: (value) =>
                value?.trim().isEmpty ?? true ? 'Title is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: 'Enter content description',
            ),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSelector() {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _platforms.map((platform) {
              final isSelected = _selectedPlatform == platform['id'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPlatform = platform['id'];
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? platform['color'] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? platform['color'] : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        platform['icon'],
                        size: 20,
                        color: isSelected ? Colors.white : Colors.black54,
                      ),
                      SizedBox(width: 8),
                      Text(
                        platform['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
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
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Type *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _contentTypes.map((type) {
              final isSelected = _selectedContentType == type['id'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedContentType = type['id']!;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF9C27B0) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Color(0xFF9C27B0) : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    type['name']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Date & Time *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
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
                        Text(
                          DateFormat('dd MMM yyyy').format(_scheduledDate),
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
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
                        Text(
                          _scheduledTime.format(context),
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
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
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statuses.map((status) {
              final isSelected = _selectedStatus == status['id'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStatus = status['id'];
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? status['color'] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? status['color'] : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    status['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Schedule Content',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  Future<void> _submitContent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a client')),
      );
      return;
    }

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
        'clientId': _selectedClientId,
        'clientName': _selectedClientName,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'platform': _selectedPlatform,
        'contentType': _selectedContentType,
        'scheduledDate': Timestamp.fromDate(scheduledDateTime),
        'status': _selectedStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser!.uid,
      });

      // Send notification to client
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': _selectedClientId,
        'title': 'New Content Scheduled',
        'body':
            'A new ${_selectedContentType} has been scheduled for ${DateFormat('dd MMM').format(scheduledDateTime)}',
        'type': 'content',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Content scheduled successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
