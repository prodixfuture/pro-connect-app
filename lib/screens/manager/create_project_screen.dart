// CREATE PROJECT SCREEN
// File: lib/modules/task_management/screens/admin/create_project_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/project_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({Key? key}) : super(key: key);

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProjectService _projectService = ProjectService();

  final _nameController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _tagController = TextEditingController();

  String? _selectedManagerId;
  DateTime? _deadline;
  List<String> _tags = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _managers = [];

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientNameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadManagers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'manager')
          .get();

      setState(() {
        _managers = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'] ?? 'Unknown',
                })
            .toList();
      });
    } catch (e) {
      print('Error loading managers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Project'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _createProject,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Project Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter project name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Client Name
            TextFormField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Client Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter client name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 16),

            // Assign to Manager
            DropdownButtonFormField<String>(
              value: _selectedManagerId,
              decoration: const InputDecoration(
                labelText: 'Assign to Manager *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: _managers.map<DropdownMenuItem<String>>((manager) {
                return DropdownMenuItem<String>(
                  value: manager['id'] as String,
                  child: Text(manager['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedManagerId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a manager';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Deadline
            InkWell(
              onTap: _selectDeadline,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Deadline *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  errorText: _deadline == null &&
                          _formKey.currentState?.validate() == false
                      ? 'Please select deadline'
                      : null,
                ),
                child: Text(
                  _deadline != null
                      ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                      : 'Select deadline',
                  style: TextStyle(
                    color: _deadline != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Budget
            TextFormField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Budget',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                suffixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Tags
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: const InputDecoration(
                          labelText: 'Tags',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                          hintText: 'Add a tag',
                        ),
                        onSubmitted: (value) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTag,
                      child: const Text('Add'),
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _tags.remove(tag);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 32),

            // Create Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createProject,
              icon: const Icon(Icons.add),
              label: Text(_isLoading ? 'Creating...' : 'Create Project'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The assigned manager will be able to create and manage tasks for this project.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTag() {
    if (_tagController.text.trim().isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text.trim());
        _tagController.clear();
      });
    }
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _deadline = date;
      });
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a deadline'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _projectService.createProject(
        name: _nameController.text.trim(),
        clientName: _clientNameController.text.trim(),
        deadline: _deadline!,
        managerId: _selectedManagerId!,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        budget: _budgetController.text.trim().isNotEmpty
            ? double.parse(_budgetController.text.trim())
            : null,
        tags: _tags.isNotEmpty ? _tags : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
