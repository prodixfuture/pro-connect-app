// UPDATED CREATE PROJECT SCREEN WITH CLIENT SELECTION
// File: lib/modules/task_management/screens/admin/create_project_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateProjectScreen extends StatefulWidget {
  final String? projectId; // For edit mode
  final Map<String, dynamic>? projectData; // For edit mode

  const CreateProjectScreen({
    Key? key,
    this.projectId,
    this.projectData,
  }) : super(key: key);

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final budgetCtrl = TextEditingController();
  final customClientCtrl = TextEditingController();

  String? selectedClientId;
  String clientType = 'existing'; // 'existing' or 'custom'
  DateTime? selectedDeadline;
  bool isLoading = false;

  bool get isEditMode => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode && widget.projectData != null) {
      _loadProjectData();
    }
  }

  void _loadProjectData() {
    final data = widget.projectData!;
    titleCtrl.text = data['name'] ?? data['title'] ?? '';
    descCtrl.text = data['description'] ?? '';
    budgetCtrl.text = data['budget']?.toString() ?? '';

    if (data['clientId'] != null) {
      clientType = 'existing';
      selectedClientId = data['clientId'];
    } else if (data['clientName'] != null) {
      clientType = 'custom';
      customClientCtrl.text = data['clientName'];
    }

    if (data['deadline'] != null) {
      selectedDeadline = (data['deadline'] as Timestamp).toDate();
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    budgetCtrl.dispose();
    customClientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Project' : 'Create Project'),
        backgroundColor: Color(0xFF6B7FED),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Project Title
            TextFormField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Project Title *',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Project title is required';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            // Description
            TextFormField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),

            SizedBox(height: 24),

            // Client Type Selection
            Text(
              'Client *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text('Existing Client'),
                    subtitle: Text('Select from registered clients'),
                    value: 'existing',
                    groupValue: clientType,
                    onChanged: (value) {
                      setState(() {
                        clientType = value!;
                        customClientCtrl.clear();
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('Custom Client'),
                    subtitle: Text('Enter client name manually'),
                    value: 'custom',
                    groupValue: clientType,
                    onChanged: (value) {
                      setState(() {
                        clientType = value!;
                        selectedClientId = null;
                      });
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Existing Client Dropdown
            if (clientType == 'existing')
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'client')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No clients found. Please add clients first or use custom option.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort clients by name in code
                  final clients = snapshot.data!.docs;
                  clients.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aName = aData['name'] ?? '';
                    final bName = bData['name'] ?? '';
                    return aName.compareTo(bName);
                  });

                  return DropdownButtonFormField<String>(
                    value: selectedClientId,
                    decoration: InputDecoration(
                      labelText: 'Select Client',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: clients.map((client) {
                      final clientData = client.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: client.id,
                        child: Text(clientData['name'] ?? 'Unnamed Client'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClientId = value;
                      });
                    },
                    validator: (value) {
                      if (clientType == 'existing' && value == null) {
                        return 'Please select a client';
                      }
                      return null;
                    },
                  );
                },
              ),

            // Custom Client Name
            if (clientType == 'custom')
              TextFormField(
                controller: customClientCtrl,
                decoration: InputDecoration(
                  labelText: 'Client Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter client name',
                ),
                validator: (value) {
                  if (clientType == 'custom' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Please enter client name';
                  }
                  return null;
                },
              ),

            SizedBox(height: 16),

            // Deadline
            InkWell(
              onTap: _selectDeadline,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Deadline (Optional)',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  selectedDeadline == null
                      ? 'Select deadline'
                      : '${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}',
                  style: TextStyle(
                    color:
                        selectedDeadline == null ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Budget
            TextFormField(
              controller: budgetCtrl,
              decoration: InputDecoration(
                labelText: 'Budget (Optional)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '0.00',
              ),
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6B7FED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditMode ? 'Update Project' : 'Create Project',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        selectedDeadline = picked;
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      String? clientName;
      String? clientId;

      // Get client info
      if (clientType == 'existing' && selectedClientId != null) {
        clientId = selectedClientId;
        final clientDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(clientId)
            .get();
        if (clientDoc.exists) {
          clientName = (clientDoc.data() as Map<String, dynamic>)['name'];
        }
      } else if (clientType == 'custom') {
        clientName = customClientCtrl.text.trim();
      }

      final projectData = {
        'name': titleCtrl.text.trim(),
        'title': titleCtrl.text.trim(), // Keep both for compatibility
        'description': descCtrl.text.trim(),
        'clientId': clientId,
        'clientName': clientName ?? 'No client',
        'deadline': selectedDeadline != null
            ? Timestamp.fromDate(selectedDeadline!)
            : null,
        'budget': budgetCtrl.text.isNotEmpty
            ? double.tryParse(budgetCtrl.text)
            : null,
        'status': 'active',
      };

      if (isEditMode) {
        // Update existing project
        projectData['updatedAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .update(projectData);

        _showSnackBar('Project updated successfully', Colors.green);
      } else {
        // Create new project
        projectData['createdAt'] = FieldValue.serverTimestamp();
        projectData['managerId'] = ''; // Set manager if needed
        projectData['staffIds'] = [];

        await FirebaseFirestore.instance
            .collection('projects')
            .add(projectData);

        _showSnackBar('Project created successfully', Colors.green);
      }

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
}
