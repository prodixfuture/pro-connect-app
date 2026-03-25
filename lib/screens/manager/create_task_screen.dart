// CREATE TASK SCREEN
// File: lib/modules/task_management/screens/manager/create_task_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/task_service.dart';
import '../../utils/task_constants.dart';

class CreateTaskScreen extends StatefulWidget {
  final String projectId;

  const CreateTaskScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TaskService _taskService = TaskService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedDesignerId;
  String _selectedPriority = 'medium';
  String? _selectedDesignType;
  DateTime? _dueDate;
  double? _estimatedHours;
  List<String> _tags = [];
  final _tagController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _designers = [];

  @override
  void initState() {
    super.initState();
    _loadDesigners();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadDesigners() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .where('department', isEqualTo: 'design')
          .get();

      setState(() {
        _designers = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'] ?? 'Unknown',
                })
            .toList();
      });
    } catch (e) {
      print('Error loading designers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Task'),
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
              onPressed: _createTask,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter task title';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Assign to Designer
            DropdownButtonFormField<String>(
              value: _selectedDesignerId,
              decoration: const InputDecoration(
                labelText: 'Assign to Designer *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: _designers.map<DropdownMenuItem<String>>((designer) {
                return DropdownMenuItem<String>(
                  value: designer['id'] as String,
                  child: Text(designer['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDesignerId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a designer';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Priority
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: TaskPriority.all.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Icon(
                        TaskPriority.getIcon(priority),
                        color: TaskPriority.getColor(priority),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(TaskPriority.getLabel(priority)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Design Type
            DropdownButtonFormField<String>(
              value: _selectedDesignType,
              decoration: const InputDecoration(
                labelText: 'Design Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.design_services),
              ),
              items: DesignType.all.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(DesignType.getIcon(type), size: 20),
                      const SizedBox(width: 8),
                      Text(DesignType.getLabel(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDesignType = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Due Date
            InkWell(
              onTap: _selectDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dueDate != null
                      ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                      : 'Select due date',
                  style: TextStyle(
                    color: _dueDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Estimated Hours
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Estimated Hours',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
                suffixText: 'hours',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _estimatedHours = double.tryParse(value);
                });
              },
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
              onPressed: _isLoading ? null : _createTask,
              icon: const Icon(Icons.add_task),
              label: Text(_isLoading ? 'Creating...' : 'Create Task'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
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

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.createTask(
        projectId: widget.projectId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedTo: _selectedDesignerId!,
        priority: _selectedPriority,
        designType: _selectedDesignType,
        dueDate: _dueDate,
        estimatedHours: _estimatedHours,
        tags: _tags.isNotEmpty ? _tags : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating task: $e'),
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
