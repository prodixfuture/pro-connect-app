// COMPLETE FILE UPLOAD SERVICE
// File: lib/modules/task_management/services/file_upload_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/task_model.dart';
import '../utils/task_helpers.dart';

// Note: For file picking (PDF, ZIP), you need to add file_picker package
// Or use platform-specific file pickers
// For now, this service focuses on image uploads which work with image_picker

class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // ==================== UPLOAD FILE ====================
  Future<TaskAttachment> uploadFile({
    required String taskId,
    required File file,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final fileExtension = TaskHelpers.getFileExtension(fileName);
      final fileSize = await file.length();

      // Validate file size (max 10MB)
      if (!TaskHelpers.isFileSizeValid(fileSize)) {
        throw 'File size exceeds 10MB limit';
      }

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';

      // Create storage reference
      final ref = _storage.ref().child('tasks/$taskId/files/$uniqueFileName');

      // Upload with progress tracking
      final uploadTask = ref.putFile(file);

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Determine file type
      String fileType = 'other';
      if (TaskHelpers.isImageFile(fileName)) {
        fileType = 'image';
      } else if (TaskHelpers.isPdfFile(fileName)) {
        fileType = 'pdf';
      } else if (TaskHelpers.isZipFile(fileName)) {
        fileType = 'zip';
      }

      return TaskAttachment(
        fileName: fileName,
        fileUrl: downloadUrl,
        fileType: fileType,
        fileSize: fileSize,
        uploadedAt: DateTime.now(),
        uploadedBy: userId,
      );
    } catch (e) {
      throw 'Failed to upload file: $e';
    }
  }

  // ==================== PICK AND UPLOAD IMAGE ====================
  Future<TaskAttachment?> pickAndUploadImage({
    required String taskId,
    required String userId,
    ImageSource source = ImageSource.gallery,
    Function(double)? onProgress,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      final file = File(image.path);
      return await uploadFile(
        taskId: taskId,
        file: file,
        userId: userId,
        onProgress: onProgress,
      );
    } catch (e) {
      throw 'Failed to pick and upload image: $e';
    }
  }

  // ==================== PICK AND UPLOAD MULTIPLE IMAGES ====================
  Future<List<TaskAttachment>> pickAndUploadMultipleImages({
    required String taskId,
    required String userId,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) return [];

      final List<TaskAttachment> attachments = [];
      for (int i = 0; i < images.length; i++) {
        onProgress?.call(i + 1, images.length);

        final file = File(images[i].path);
        final attachment = await uploadFile(
          taskId: taskId,
          file: file,
          userId: userId,
        );
        attachments.add(attachment);
      }

      return attachments;
    } catch (e) {
      throw 'Failed to pick and upload images: $e';
    }
  }

  // ==================== PICK AND UPLOAD FILE ====================
  // Note: This method requires file_picker package
  // For images only, use pickAndUploadImage or pickAndUploadMultipleImages
  // To enable this, add file_picker: ^6.1.1 to pubspec.yaml

  Future<TaskAttachment?> pickAndUploadFile({
    required String taskId,
    required String userId,
    List<String>? allowedExtensions,
    Function(double)? onProgress,
  }) async {
    throw UnimplementedError('This method requires file_picker package. '
        'Add file_picker: ^6.1.1 to pubspec.yaml or use image upload methods.');

    /* IMPLEMENTATION WITH FILE_PICKER:
    
    import 'package:file_picker/file_picker.dart';
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.first.path!);
      return await uploadFile(
        taskId: taskId,
        file: file,
        userId: userId,
        onProgress: onProgress,
      );
    } catch (e) {
      throw 'Failed to pick and upload file: $e';
    }
    */
  }

  // ==================== PICK AND UPLOAD MULTIPLE FILES ====================
  // Note: This method requires file_picker package
  // For images only, use pickAndUploadMultipleImages
  // To enable this, add file_picker: ^6.1.1 to pubspec.yaml

  Future<List<TaskAttachment>> pickAndUploadMultipleFiles({
    required String taskId,
    required String userId,
    List<String>? allowedExtensions,
    Function(int current, int total)? onProgress,
  }) async {
    throw UnimplementedError('This method requires file_picker package. '
        'Add file_picker: ^6.1.1 to pubspec.yaml or use image upload methods.');

    /* IMPLEMENTATION WITH FILE_PICKER:
    
    import 'package:file_picker/file_picker.dart';
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return [];

      final List<TaskAttachment> attachments = [];
      for (int i = 0; i < result.files.length; i++) {
        onProgress?.call(i + 1, result.files.length);

        final file = File(result.files[i].path!);
        final attachment = await uploadFile(
          taskId: taskId,
          file: file,
          userId: userId,
        );
        attachments.add(attachment);
      }

      return attachments;
    } catch (e) {
      throw 'Failed to pick and upload files: $e';
    }
    */
  }

  // ==================== DELETE FILE ====================
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw 'Failed to delete file: $e';
    }
  }

  // ==================== DELETE ALL TASK FILES ====================
  Future<void> deleteTaskFiles(String taskId) async {
    try {
      final ref = _storage.ref().child('tasks/$taskId/files');
      final listResult = await ref.listAll();

      for (var item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      throw 'Failed to delete task files: $e';
    }
  }

  // ==================== GET FILE METADATA ====================
  Future<FullMetadata> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw 'Failed to get file metadata: $e';
    }
  }

  // ==================== DOWNLOAD FILE ====================
  Future<File> downloadFile(String fileUrl, String savePath) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final file = File(savePath);
      await ref.writeToFile(file);
      return file;
    } catch (e) {
      throw 'Failed to download file: $e';
    }
  }
}
