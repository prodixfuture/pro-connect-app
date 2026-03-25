// DESIGNER TASK DETAIL SCREEN
// File: lib/modules/task_management/screens/designer/designer_task_detail.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/task_model.dart';
import '../../models/task_comment_model.dart';
import '../../models/task_activity_model.dart';
import '../../services/task_service.dart';
import '../../services/file_upload_service.dart';
import '../../utils/task_constants.dart';
import '../../utils/task_helpers.dart';
import '../../widgets/priority_chip.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/timer_widget.dart';
import '../../widgets/comment_widget.dart';

class DesignerTaskDetail extends StatefulWidget {
  final String taskId;

  const DesignerTaskDetail({Key? key, required this.taskId}) : super(key: key);

  @override
  State<DesignerTaskDetail> createState() => _DesignerTaskDetailState();
}

class _DesignerTaskDetailState extends State<DesignerTaskDetail> {
  final TaskService _taskService = TaskService();
  final FileUploadService _fileService = FileUploadService();
  final TextEditingController _commentController = TextEditingController();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TaskModel>(
      stream: _taskService.streamTask(widget.taskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading task: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final task = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
            actions: [
              if (task.status == 'in_progress' || task.status == 'rejected')
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _submitForReview(task),
                  tooltip: 'Submit for Review',
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'refresh') {
                    setState(() {});
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(task),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timer Widget
                      TimerWidget(
                        startTime: task.startTime,
                        isRunning: task.isInProgress && task.startTime != null,
                        onStart: () => _startWork(task),
                        onStop: () => _stopWork(task),
                      ),

                      const SizedBox(height: 24),

                      // Description
                      _buildSection('Description', task.description),

                      const SizedBox(height: 24),

                      // Task Info
                      _buildTaskInfo(task),

                      const SizedBox(height: 24),

                      // Rejection Reason
                      if (task.status == 'rejected' &&
                          task.rejectionReason != null) ...[
                        _buildRejectionReason(task.rejectionReason!),
                        const SizedBox(height: 24),
                      ],

                      // Attachments
                      _buildAttachmentsSection(task),

                      const SizedBox(height: 24),

                      // Comments Section
                      _buildCommentsSection(),

                      const SizedBox(height: 24),

                      // Activity Log
                      _buildActivitySection(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(TaskModel task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: task.isOverdue
            ? TaskColors.dangerGradient
            : TaskColors.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Title
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Priority & Status
            Row(
              children: [
                PriorityChip(priority: task.priority, size: ChipSize.large),
                const SizedBox(width: 8),
                StatusChip(status: task.status, size: ChipSize.large),
              ],
            ),

            const SizedBox(height: 12),

            // Design Type & Revision Count
            Row(
              children: [
                if (task.designType != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          DesignType.getIcon(task.designType!),
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DesignType.getLabel(task.designType!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (task.revisionCount! > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.refresh,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Revision ${task.revisionCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildTaskInfo(TaskModel task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (task.dueDate != null)
            _buildInfoRow(
              Icons.calendar_today,
              'Due Date',
              TaskHelpers.formatDate(task.dueDate!),
              isOverdue: task.isOverdue,
            ),
          if (task.estimatedHours != null) ...[
            const Divider(),
            _buildInfoRow(
              Icons.access_time,
              'Estimated',
              TaskHelpers.formatHours(task.estimatedHours!),
            ),
          ],
          if (task.actualHours != null) ...[
            const Divider(),
            _buildInfoRow(
              Icons.timer,
              'Actual',
              TaskHelpers.formatHours(task.actualHours!),
            ),
          ],
          if (task.estimatedHours != null && task.actualHours != null) ...[
            const Divider(),
            _buildInfoRow(
              Icons.trending_up,
              'Progress',
              '${task.progressPercentage.toStringAsFixed(0)}%',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isOverdue = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isOverdue ? Colors.red : Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isOverdue ? Colors.red : Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isOverdue ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildRejectionReason(String reason) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Rejection Reason',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: TextStyle(fontSize: 14, color: Colors.red.shade900),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(TaskModel task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attachments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : () => _uploadFiles(task),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Upload'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isUploading) ...[
          LinearProgressIndicator(value: _uploadProgress),
          const SizedBox(height: 8),
          Text(
            'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
        ],
        if (task.attachments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.attach_file, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No attachments yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ...task.attachments.map((att) => _buildAttachmentItem(att)),
      ],
    );
  }

  Widget _buildAttachmentItem(TaskAttachment attachment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: FileType.getColor(attachment.fileType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            FileType.getIcon(attachment.fileType),
            color: FileType.getColor(attachment.fileType),
          ),
        ),
        title: Text(
          attachment.fileName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${attachment.fileSizeFormatted} • ${TaskHelpers.getTimeAgo(attachment.uploadedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () {
            // Open file in browser or download
            // You can use url_launcher package here
          },
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comments',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<TaskCommentModel>>(
          stream: _taskService.streamComments(widget.taskId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final comments = snapshot.data ?? [];

            if (comments.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.comment, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No comments yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                ...comments.map((comment) => CommentWidget(
                      comment: comment,
                      isCurrentUser: comment.userId == _userId,
                    )),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 3,
            minLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            gradient: TaskColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _addComment,
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Log',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<TaskActivityModel>>(
          stream: _taskService.streamActivity(widget.taskId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final activities = snapshot.data ?? [];

            if (activities.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No activity yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }

            return Column(
              children: activities.map((activity) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.description,
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              activity.timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _startWork(TaskModel task) async {
    try {
      await _taskService.startTask(widget.taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work timer started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _stopWork(TaskModel task) async {
    try {
      await _taskService.stopTask(widget.taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work timer stopped'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadFiles(TaskModel task) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final attachments = await _fileService.pickAndUploadMultipleFiles(
        taskId: widget.taskId,
        userId: _userId,
        onProgress: (current, total) {
          setState(() {
            _uploadProgress = current / total;
          });
        },
      );

      if (attachments.isNotEmpty) {
        final updatedAttachments = [...task.attachments, ...attachments];

        await _taskService.updateTask(
          taskId: widget.taskId,
          attachments: updatedAttachments,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${attachments.length} file(s) uploaded'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await _taskService.addComment(
        taskId: widget.taskId,
        message: _commentController.text.trim(),
      );

      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForReview(TaskModel task) async {
    if (task.attachments.isEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Attachments'),
          content: const Text(
            'You haven\'t uploaded any design files yet. Are you sure you want to submit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit for Review'),
        content: const Text(
          'Are you sure you want to submit this task for review?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _taskService.submitTask(widget.taskId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task submitted for review'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
