// TASK CARD WIDGET
// File: lib/modules/task_management/widgets/task_card.dart

import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../utils/task_constants.dart';
import '../utils/task_helpers.dart';
import 'priority_chip.dart';
import 'status_chip.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final bool showProject;

  const TaskCard({
    Key? key,
    required this.task,
    this.onTap,
    this.showProject = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: task.isOverdue ? Colors.red.shade200 : Colors.transparent,
          width: task.isOverdue ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: task.isOverdue
                ? LinearGradient(
                    colors: [Colors.red.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Priority Indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TaskPriority.getColor(task.priority),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            PriorityChip(
                              priority: task.priority,
                              size: ChipSize.small,
                            ),
                            const SizedBox(width: 8),
                            StatusChip(
                              status: task.status,
                              size: ChipSize.small,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Design Type Icon
                  if (task.designType != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TaskPriority.getColor(task.priority)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        DesignType.getIcon(task.designType!),
                        size: 24,
                        color: TaskPriority.getColor(task.priority),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              if (task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const SizedBox(height: 12),

              // Footer Row
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    // Due Date
                    if (task.dueDate != null) ...[
                      Icon(
                        task.isOverdue
                            ? Icons.error_outline
                            : Icons.calendar_today,
                        size: 16,
                        color: task.isOverdue ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        TaskHelpers.formatDeadline(task.dueDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: task.isOverdue ? Colors.red : Colors.grey[600],
                          fontWeight: task.isOverdue
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],

                    // Estimated Hours
                    if (task.estimatedHours != null) ...[
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        TaskHelpers.formatHours(task.estimatedHours!),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                    ],

                    // Attachments
                    if (task.attachments.isNotEmpty) ...[
                      Icon(Icons.attach_file,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${task.attachments.length}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],

                    const Spacer(),

                    // Progress Indicator
                    if (task.isInProgress &&
                        task.estimatedHours != null &&
                        task.actualHours != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${task.progressPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Tags
              if (task.tags != null && task.tags!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: task.tags!.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
