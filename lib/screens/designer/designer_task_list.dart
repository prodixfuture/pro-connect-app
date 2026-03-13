// DESIGNER TASK LIST SCREEN
// File: lib/modules/task_management/screens/designer/designer_task_list.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../utils/task_constants.dart';

import '../../widgets/task_card.dart';
import 'designer_task_detail.dart';

class DesignerTaskList extends StatefulWidget {
  const DesignerTaskList({Key? key}) : super(key: key);

  @override
  State<DesignerTaskList> createState() => _DesignerTaskListState();
}

class _DesignerTaskListState extends State<DesignerTaskList> {
  final TaskService _taskService = TaskService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  String _sortBy = 'date'; // date, priority, deadline
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: TaskColors.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Filter Chips
          _buildFilterChips(),

          // Task List
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Status Filters
          _buildFilterChip(
            'All',
            _selectedStatus == 'all',
            () => setState(() => _selectedStatus = 'all'),
            Colors.grey,
          ),
          _buildFilterChip(
            'Pending',
            _selectedStatus == 'pending',
            () => setState(() => _selectedStatus = 'pending'),
            Colors.orange,
          ),
          _buildFilterChip(
            'In Progress',
            _selectedStatus == 'in_progress',
            () => setState(() => _selectedStatus = 'in_progress'),
            Colors.blue,
          ),
          _buildFilterChip(
            'Review',
            _selectedStatus == 'review',
            () => setState(() => _selectedStatus = 'review'),
            Colors.purple,
          ),
          _buildFilterChip(
            'Completed',
            _selectedStatus == 'completed',
            () => setState(() => _selectedStatus = 'completed'),
            Colors.green,
          ),
          _buildFilterChip(
            'Rejected',
            _selectedStatus == 'rejected',
            () => setState(() => _selectedStatus = 'rejected'),
            Colors.red,
          ),

          const SizedBox(width: 8),
          Container(width: 1, color: Colors.grey[300]),
          const SizedBox(width: 8),

          // Priority Filters
          _buildFilterChip(
            'All Priority',
            _selectedPriority == 'all',
            () => setState(() => _selectedPriority = 'all'),
            Colors.grey,
          ),
          _buildFilterChip(
            'Urgent',
            _selectedPriority == 'urgent',
            () => setState(() => _selectedPriority = 'urgent'),
            Colors.red,
          ),
          _buildFilterChip(
            'High',
            _selectedPriority == 'high',
            () => setState(() => _selectedPriority = 'high'),
            Colors.orange,
          ),
          _buildFilterChip(
            'Medium',
            _selectedPriority == 'medium',
            () => setState(() => _selectedPriority = 'medium'),
            Colors.blue,
          ),
          _buildFilterChip(
            'Low',
            _selectedPriority == 'low',
            () => setState(() => _selectedPriority = 'low'),
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey[100],
        selectedColor: color.withOpacity(0.2),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? color : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.streamTasksByDesigner(_userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        List<TaskModel> tasks = snapshot.data ?? [];

        // Apply filters
        tasks = _applyFilters(tasks);

        // Apply search
        if (_searchQuery.isNotEmpty) {
          tasks = tasks.where((task) {
            return task.title.toLowerCase().contains(_searchQuery) ||
                task.description.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        // Apply sorting
        tasks = _applySorting(tasks);

        if (tasks.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(seconds: 1));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                onTap: () => _navigateToTaskDetail(task),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message = 'No tasks found';
    IconData icon = Icons.inbox_outlined;

    if (_searchQuery.isNotEmpty) {
      message = 'No tasks match your search';
      icon = Icons.search_off;
    } else if (_selectedStatus != 'all') {
      message =
          'No ${TaskStatus.getLabel(_selectedStatus).toLowerCase()} tasks';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isNotEmpty || _selectedStatus != 'all')
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedStatus = 'all';
                  _selectedPriority = 'all';
                });
              },
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  List<TaskModel> _applyFilters(List<TaskModel> tasks) {
    // Filter by status
    if (_selectedStatus != 'all') {
      tasks = tasks.where((task) => task.status == _selectedStatus).toList();
    }

    // Filter by priority
    if (_selectedPriority != 'all') {
      tasks =
          tasks.where((task) => task.priority == _selectedPriority).toList();
    }

    return tasks;
  }

  List<TaskModel> _applySorting(List<TaskModel> tasks) {
    switch (_sortBy) {
      case 'priority':
        tasks.sort((a, b) {
          final priorityA = TaskPriority.getPriorityWeight(a.priority);
          final priorityB = TaskPriority.getPriorityWeight(b.priority);
          return priorityB.compareTo(priorityA); // Descending
        });
        break;
      case 'deadline':
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!); // Ascending
        });
        break;
      case 'date':
      default:
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Descending
        break;
    }
    return tasks;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status Section
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      'all',
                      'pending',
                      'in_progress',
                      'review',
                      'completed',
                      'rejected'
                    ].map((status) {
                      return ChoiceChip(
                        label: Text(
                          status == 'all' ? 'All' : TaskStatus.getLabel(status),
                        ),
                        selected: _selectedStatus == status,
                        onSelected: (selected) {
                          setModalState(() => _selectedStatus = status);
                          setState(() => _selectedStatus = status);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Priority Section
                  const Text(
                    'Priority',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['all', 'urgent', 'high', 'medium', 'low']
                        .map((priority) {
                      return ChoiceChip(
                        label: Text(
                          priority == 'all'
                              ? 'All'
                              : TaskPriority.getLabel(priority),
                        ),
                        selected: _selectedPriority == priority,
                        onSelected: (selected) {
                          setModalState(() => _selectedPriority = priority);
                          setState(() => _selectedPriority = priority);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedStatus = 'all';
                              _selectedPriority = 'all';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildSortOption('Date Created', 'date', Icons.calendar_today),
              _buildSortOption('Priority', 'priority', Icons.priority_high),
              _buildSortOption('Deadline', 'deadline', Icons.event),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading:
          Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check) : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
    );
  }

  void _navigateToTaskDetail(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DesignerTaskDetail(taskId: task.id),
      ),
    );
  }
}
