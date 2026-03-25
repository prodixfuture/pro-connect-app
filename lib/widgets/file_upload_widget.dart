// FILE UPLOAD WIDGET
// File: lib/modules/task_management/widgets/file_upload_widget.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/task_model.dart';
import '../services/file_upload_service.dart';
import '../utils/task_constants.dart';

class FileUploadWidget extends StatefulWidget {
  final String taskId;
  final String userId;
  final Function(List<TaskAttachment>) onFilesUploaded;
  final List<TaskAttachment> existingFiles;

  const FileUploadWidget({
    Key? key,
    required this.taskId,
    required this.userId,
    required this.onFilesUploaded,
    this.existingFiles = const [],
  }) : super(key: key);

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final FileUploadService _fileService = FileUploadService();

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadingFileName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload Buttons
        _buildUploadButtons(),

        // Upload Progress
        if (_isUploading) ...[
          const SizedBox(height: 16),
          _buildUploadProgress(),
        ],

        // Existing Files
        if (widget.existingFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildFilesList(),
        ],
      ],
    );
  }

  Widget _buildUploadButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Files',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Image Upload
            _buildUploadOption(
              icon: Icons.image,
              label: 'Upload Images',
              subtitle: 'JPG, PNG, GIF (Max 10MB)',
              color: Colors.blue,
              onTap: _isUploading ? null : _pickImages,
            ),

            const SizedBox(height: 8),

            // Camera Upload
            _buildUploadOption(
              icon: Icons.camera_alt,
              label: 'Take Photo',
              subtitle: 'Use camera',
              color: Colors.green,
              onTap: _isUploading ? null : _takePhoto,
            ),

            const SizedBox(height: 8),

            // PDF Upload
            _buildUploadOption(
              icon: Icons.picture_as_pdf,
              label: 'Upload PDF',
              subtitle: 'PDF documents',
              color: Colors.red,
              onTap: _isUploading ? null : _pickPdf,
            ),

            const SizedBox(height: 8),

            // ZIP Upload
            _buildUploadOption(
              icon: Icons.folder_zip,
              label: 'Upload ZIP',
              subtitle: 'Compressed files',
              color: Colors.orange,
              onTap: _isUploading ? null : _pickZip,
            ),

            const SizedBox(height: 8),

            // Any File
            _buildUploadOption(
              icon: Icons.attach_file,
              label: 'Upload Any File',
              subtitle: 'All file types (Max 10MB)',
              color: Colors.grey,
              onTap: _isUploading ? null : _pickAnyFile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Uploading...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_uploadingFileName != null)
                        Text(
                          _uploadingFileName!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                minHeight: 6,
                backgroundColor: Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uploaded Files',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.existingFiles.map((file) => _buildFileItem(file)),
      ],
    );
  }

  Widget _buildFileItem(TaskAttachment file) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: FileType.getColor(file.fileType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            FileType.getIcon(file.fileType),
            color: FileType.getColor(file.fileType),
            size: 24,
          ),
        ),
        title: Text(
          file.fileName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          file.fileSizeFormatted,
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () {
                // Open file in browser
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteFile(file),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UPLOAD METHODS ====================

  Future<void> _pickImages() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final attachments = await _fileService.pickAndUploadMultipleImages(
        taskId: widget.taskId,
        userId: widget.userId,
        onProgress: (current, total) {
          setState(() {
            _uploadProgress = current / total;
            _uploadingFileName = 'Uploading $current of $total images';
          });
        },
      );

      if (attachments.isNotEmpty) {
        widget.onFilesUploaded(attachments);
        _showSuccess('${attachments.length} image(s) uploaded');
      }
    } catch (e) {
      _showError('Failed to upload images: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadingFileName = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadingFileName = 'Taking photo...';
      });

      final attachment = await _fileService.pickAndUploadImage(
        taskId: widget.taskId,
        userId: widget.userId,
        source: ImageSource.camera,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (attachment != null) {
        widget.onFilesUploaded([attachment]);
        _showSuccess('Photo uploaded');
      }
    } catch (e) {
      _showError('Failed to upload photo: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadingFileName = null;
      });
    }
  }

  Future<void> _pickPdf() async {
    // Note: PDF picking requires file_picker package
    // For now, show message to user
    _showError('PDF upload requires file_picker package. '
        'Please use image upload for now or ask developer to add file_picker package.');

    /* ENABLE THIS AFTER ADDING file_picker package:
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadingFileName = 'Uploading PDF...';
      });

      final attachment = await _fileService.pickAndUploadFile(
        taskId: widget.taskId,
        userId: widget.userId,
        allowedExtensions: ['pdf'],
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (attachment != null) {
        widget.onFilesUploaded([attachment]);
        _showSuccess('PDF uploaded');
      }
    } catch (e) {
      _showError('Failed to upload PDF: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadingFileName = null;
      });
    }
    */
  }

  Future<void> _pickZip() async {
    // Note: ZIP picking requires file_picker package
    _showError('ZIP upload requires file_picker package. '
        'Please use image upload for now or ask developer to add file_picker package.');
  }

  Future<void> _pickAnyFile() async {
    // Note: File picking requires file_picker package
    _showError('File upload requires file_picker package. '
        'Please use image upload for now or ask developer to add file_picker package.');
  }

  Future<void> _deleteFile(TaskAttachment file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Delete "${file.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _fileService.deleteFile(file.fileUrl);
        _showSuccess('File deleted');
        // Note: You'll need to update the parent widget to remove the file from the list
      } catch (e) {
        _showError('Failed to delete file: $e');
      }
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
