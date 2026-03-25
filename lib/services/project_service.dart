// COMPLETE PROJECT SERVICE
// File: lib/modules/task_management/services/project_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_model.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _projectsCollection =>
      _firestore.collection('projects');

  // ==================== CREATE PROJECT ====================
  Future<String> createProject({
    required String name,
    required String clientName,
    required DateTime deadline,
    required String managerId,
    String? description,
    double? budget,
    List<String>? tags,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final project = ProjectModel(
        id: '',
        name: name,
        clientName: clientName,
        deadline: deadline,
        createdBy: userId,
        managerId: managerId,
        createdAt: DateTime.now(),
        status: 'active',
        description: description,
        budget: budget,
        tags: tags,
      );

      final docRef = await _projectsCollection.add(project.toFirestore());

      // Send notification to manager
      await _sendProjectNotification(
        userId: managerId,
        title: 'New Project Assigned',
        message: 'You have been assigned to manage: $name',
        projectId: docRef.id,
      );

      return docRef.id;
    } catch (e) {
      throw 'Failed to create project: $e';
    }
  }

  // ==================== UPDATE PROJECT ====================
  Future<void> updateProject({
    required String projectId,
    String? name,
    String? clientName,
    DateTime? deadline,
    String? managerId,
    String? status,
    String? description,
    double? budget,
    List<String>? tags,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (clientName != null) updates['clientName'] = clientName;
      if (deadline != null) updates['deadline'] = Timestamp.fromDate(deadline);
      if (managerId != null) updates['managerId'] = managerId;
      if (status != null) updates['status'] = status;
      if (description != null) updates['description'] = description;
      if (budget != null) updates['budget'] = budget;
      if (tags != null) updates['tags'] = tags;

      await _projectsCollection.doc(projectId).update(updates);
    } catch (e) {
      throw 'Failed to update project: $e';
    }
  }

  // ==================== DELETE PROJECT ====================
  Future<void> deleteProject(String projectId) async {
    try {
      // Delete all tasks in this project first
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .get();

      final batch = _firestore.batch();
      for (var doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete project
      batch.delete(_projectsCollection.doc(projectId));
      await batch.commit();
    } catch (e) {
      throw 'Failed to delete project: $e';
    }
  }

  // ==================== GET PROJECT ====================
  Future<ProjectModel> getProject(String projectId) async {
    try {
      final doc = await _projectsCollection.doc(projectId).get();
      if (!doc.exists) throw 'Project not found';
      return ProjectModel.fromFirestore(doc);
    } catch (e) {
      throw 'Failed to get project: $e';
    }
  }

  // ==================== STREAM ALL PROJECTS ====================
  Stream<List<ProjectModel>> streamAllProjects() {
    return _projectsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  // ==================== STREAM ACTIVE PROJECTS ====================
  Stream<List<ProjectModel>> streamActiveProjects() {
    return _projectsCollection
        .where('status', isEqualTo: 'active')
        .orderBy('deadline')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  // ==================== STREAM PROJECTS BY MANAGER ====================
  Stream<List<ProjectModel>> streamProjectsByManager(String managerId) {
    return _projectsCollection
        .where('managerId', isEqualTo: managerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  // ==================== GET PROJECT STATISTICS ====================
  Future<Map<String, dynamic>> getProjectStats(String projectId) async {
    try {
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .get();

      final tasks = tasksSnapshot.docs;
      final totalTasks = tasks.length;
      final completedTasks =
          tasks.where((doc) => doc['status'] == 'completed').length;
      final inProgressTasks =
          tasks.where((doc) => doc['status'] == 'in_progress').length;
      final pendingTasks =
          tasks.where((doc) => doc['status'] == 'pending').length;
      final reviewTasks =
          tasks.where((doc) => doc['status'] == 'review').length;

      double totalEstimatedHours = 0;
      double totalActualHours = 0;

      for (var doc in tasks) {
        final data = doc.data() as Map<String, dynamic>;
        totalEstimatedHours += (data['estimatedHours'] ?? 0.0);
        totalActualHours += (data['actualHours'] ?? 0.0);
      }

      final completionRate =
          totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'inProgressTasks': inProgressTasks,
        'pendingTasks': pendingTasks,
        'reviewTasks': reviewTasks,
        'completionRate': completionRate,
        'totalEstimatedHours': totalEstimatedHours,
        'totalActualHours': totalActualHours,
      };
    } catch (e) {
      throw 'Failed to get project stats: $e';
    }
  }

  // ==================== SEARCH PROJECTS ====================
  Stream<List<ProjectModel>> searchProjects(String query) {
    return _projectsCollection.snapshots().map((snapshot) {
      final allProjects =
          snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();

      return allProjects
          .where((project) =>
              project.name.toLowerCase().contains(query.toLowerCase()) ||
              project.clientName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // ==================== GET OVERDUE PROJECTS ====================
  Stream<List<ProjectModel>> streamOverdueProjects() {
    return _projectsCollection
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final projects =
          snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
      return projects.where((p) => p.isOverdue).toList();
    });
  }

  // ==================== PRIVATE HELPERS ====================

  Future<void> _sendProjectNotification({
    required String userId,
    required String title,
    required String message,
    required String projectId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': 'project',
        'referenceId': projectId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }
}
