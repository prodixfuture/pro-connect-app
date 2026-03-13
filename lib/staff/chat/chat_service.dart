import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

/// Centralized chat service — role-based, group + individual, real-time
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // ═══════════════════════════════════════════════════════
  // USER & ROLE MANAGEMENT
  // ═══════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      return doc.data();
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  /// Available users to chat with — role-based.
  /// Client: only managers assigned to their projects (from 'projects' collection).
  Stream<List<Map<String, dynamic>>> getAvailableUsers() async* {
    final userData = await getCurrentUserData();
    if (userData == null) {
      yield [];
      return;
    }

    final role = userData['role'] as String? ?? '';
    final department = userData['department'] as String?;

    switch (role) {
      case 'client':
        yield* _getClientAssignedManagers();
        return;

      case 'staff':
        Query q = _firestore
            .collection('users')
            .where('role', whereIn: ['staff', 'manager']);
        if (department != null && department.isNotEmpty) {
          q = q.where('department', isEqualTo: department);
        }
        yield* q.snapshots().map((s) => s.docs
            .where((d) => d.id != currentUserId)
            .map((d) => {'uid': d.id, ...d.data() as Map<String, dynamic>})
            .toList());
        return;

      case 'manager':
      case 'admin':
      default:
        yield* _firestore.collection('users').snapshots().map((s) => s.docs
            .where((d) => d.id != currentUserId)
            .map((d) => {'uid': d.id, ...d.data() as Map<String, dynamic>})
            .toList());
        return;
    }
  }

  /// Managers from projects where clientId == currentUserId
  Stream<List<Map<String, dynamic>>> _getClientAssignedManagers() async* {
    final projectsSnap = await _firestore
        .collection('projects')
        .where('clientId', isEqualTo: currentUserId)
        .get();

    final managerIds = <String>{};
    for (final doc in projectsSnap.docs) {
      final mid = doc.data()['managerId'] as String?;
      if (mid != null && mid.isNotEmpty) managerIds.add(mid);
    }

    if (managerIds.isEmpty) {
      yield [];
      return;
    }

    final docs = await Future.wait(
      managerIds.map((id) => _firestore.collection('users').doc(id).get()),
    );
    yield docs
        .where((d) => d.exists)
        .map((d) => {'uid': d.id, ...d.data()!})
        .toList();
  }

  /// Get assigned manager IDs for a client (for canChatWith check)
  Future<Set<String>> getClientAssignedManagerIds() async {
    final snap = await _firestore
        .collection('projects')
        .where('clientId', isEqualTo: currentUserId)
        .get();
    final ids = <String>{};
    for (final doc in snap.docs) {
      final mid = doc.data()['managerId'] as String?;
      if (mid != null) ids.add(mid);
    }
    return ids;
  }

  Stream<List<Map<String, dynamic>>> getUsersByDepartment(
      String? department) async* {
    final userData = await getCurrentUserData();
    if (userData == null) {
      yield [];
      return;
    }
    Query q = _firestore.collection('users');
    if (department != null && department.isNotEmpty) {
      q = q.where('department', isEqualTo: department);
    }
    yield* q.snapshots().map((s) => s.docs
        .where((d) => d.id != currentUserId)
        .map((d) => {'uid': d.id, ...d.data() as Map<String, dynamic>})
        .toList());
  }

  Stream<List<Map<String, dynamic>>> getUsersByRole(String? role) async* {
    Query q = _firestore.collection('users');
    if (role != null && role.isNotEmpty) q = q.where('role', isEqualTo: role);
    yield* q.snapshots().map((s) => s.docs
        .where((d) => d.id != currentUserId)
        .map((d) => {'uid': d.id, ...d.data() as Map<String, dynamic>})
        .toList());
  }

  // ═══════════════════════════════════════════════════════
  // INDIVIDUAL CHATS
  // ═══════════════════════════════════════════════════════

  /// Individual chats — works with legacy docs (no isGroup field).
  Stream<List<Map<String, dynamic>>> getUserChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'chatId': d.id, ...d.data()})
            .where((c) => c['isGroup'] != true)
            .toList());
  }

  Future<String> getOrCreateChat(String otherUserId) async {
    final uid = currentUserId;
    final existing = await _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .get();

    for (final doc in existing.docs) {
      final data = doc.data();
      if (data['isGroup'] == true) continue;
      final parts = List<String>.from(data['participants'] ?? []);
      if (parts.contains(otherUserId) && parts.length == 2) return doc.id;
    }

    final me =
        (await _firestore.collection('users').doc(uid).get()).data() ?? {};
    final other =
        (await _firestore.collection('users').doc(otherUserId).get()).data() ??
            {};

    final ref = await _firestore.collection('chats').add({
      'isGroup': false,
      'participants': [uid, otherUserId],
      'participantNames': [me['name'] ?? '', other['name'] ?? ''],
      'participantRoles': [me['role'] ?? '', other['role'] ?? ''],
      'participantAvatars': [me['avatar'] ?? '', other['avatar'] ?? ''],
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': {uid: 0, otherUserId: 0},
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Map<String, dynamic> getOtherParticipant(Map<String, dynamic> chat) {
    final parts = List<String>.from(chat['participants'] ?? []);
    final names = List<String>.from(chat['participantNames'] ?? []);
    final avatars = List<String>.from(chat['participantAvatars'] ?? []);
    final idx = parts.isNotEmpty && parts[0] == currentUserId ? 1 : 0;
    return {
      'uid': idx < parts.length ? parts[idx] : '',
      'name': idx < names.length ? names[idx] : 'Unknown',
      'avatar': idx < avatars.length ? avatars[idx] : '',
    };
  }

  /// Delete individual chat — removes all messages + chat doc
  Future<void> deleteChat(String chatId) async {
    final msgs = await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .get();
    final batch = _firestore.batch();
    for (final m in msgs.docs) batch.delete(m.reference);
    batch.delete(_firestore.collection('chats').doc(chatId));
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════
  // GROUP CHATS
  // ═══════════════════════════════════════════════════════

  /// Group chats — client-side isGroup filter avoids composite index issues.
  Stream<List<Map<String, dynamic>>> getGroupChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'chatId': d.id, ...d.data()})
            .where((c) => c['isGroup'] == true)
            .toList());
  }

  Future<String> createGroupChat({
    required String groupName,
    required List<String> memberIds,
    String? description,
  }) async {
    final userData = await getCurrentUserData();
    if (userData == null) throw Exception('User data not found');
    final role = userData['role'] as String? ?? '';
    if (role != 'manager' && role != 'admin') {
      throw Exception('Only managers or admins can create group chats');
    }

    final allMembers = [currentUserId, ...memberIds];
    final memberDocs = await Future.wait(
      allMembers.map((id) => _firestore.collection('users').doc(id).get()),
    );

    final memberNames =
        memberDocs.map((d) => (d.data()?['name'] ?? '') as String).toList();
    final memberRoles =
        memberDocs.map((d) => (d.data()?['role'] ?? '') as String).toList();
    final memberAvatars =
        memberDocs.map((d) => (d.data()?['avatar'] ?? '') as String).toList();
    final unreadCount = {for (final id in allMembers) id: 0};

    final ref = await _firestore.collection('chats').add({
      'isGroup': true,
      'groupName': groupName,
      'description': description ?? '',
      'createdBy': currentUserId,
      'createdByName': userData['name'] ?? '',
      'adminIds': [currentUserId],
      'participants': allMembers,
      'participantNames': memberNames,
      'participantRoles': memberRoles,
      'participantAvatars': memberAvatars,
      'lastMessage': '${userData['name']} created the group',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('messages')
        .doc(ref.id)
        .collection('messages')
        .add({
      'type': 'system',
      'text': '${userData['name']} created "$groupName"',
      'senderId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': allMembers,
    });

    return ref.id;
  }

  Future<void> addMembersToGroup(
      String chatId, List<String> newMemberIds) async {
    final userData = await getCurrentUserData();
    if (userData == null) throw Exception('User data not found');
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data()!;
    if (!List<String>.from(chatData['adminIds'] ?? [])
        .contains(currentUserId)) {
      throw Exception('Only admins can add members');
    }
    final newDocs = await Future.wait(
        newMemberIds.map((id) => _firestore.collection('users').doc(id).get()));
    final batch = _firestore.batch();
    final chatRef = _firestore.collection('chats').doc(chatId);
    for (int i = 0; i < newMemberIds.length; i++) {
      final mid = newMemberIds[i];
      final md = newDocs[i].data()!;
      batch.update(chatRef, {
        'participants': FieldValue.arrayUnion([mid]),
        'participantNames': FieldValue.arrayUnion([md['name'] ?? '']),
        'participantRoles': FieldValue.arrayUnion([md['role'] ?? '']),
        'participantAvatars': FieldValue.arrayUnion([md['avatar'] ?? '']),
        'unreadCount.$mid': 0,
      });
    }
    await batch.commit();
    final names = newDocs.map((d) => d.data()?['name'] ?? '').join(', ');
    await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .add({
      'type': 'system',
      'text': '${userData['name']} added $names',
      'senderId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [currentUserId],
    });
  }

  Future<void> removeMemberFromGroup(String chatId, String memberId) async {
    final userData = await getCurrentUserData();
    if (userData == null) throw Exception('User data not found');
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data()!;
    if (!List<String>.from(chatData['adminIds'] ?? [])
        .contains(currentUserId)) {
      throw Exception('Only admins can remove members');
    }
    final parts = List<String>.from(chatData['participants']);
    final names = List<String>.from(chatData['participantNames']);
    final roles = List<String>.from(chatData['participantRoles']);
    final avatars = List<String>.from(chatData['participantAvatars']);
    final idx = parts.indexOf(memberId);
    if (idx == -1) return;
    final removedName = names[idx];
    parts.removeAt(idx);
    names.removeAt(idx);
    roles.removeAt(idx);
    avatars.removeAt(idx);
    await _firestore.collection('chats').doc(chatId).update({
      'participants': parts,
      'participantNames': names,
      'participantRoles': roles,
      'participantAvatars': avatars,
    });
    await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .add({
      'type': 'system',
      'text': '${userData['name']} removed $removedName',
      'senderId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [currentUserId],
    });
  }

  Future<void> deleteGroupChat(String chatId) async {
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data()!;
    final adminIds = List<String>.from(chatData['adminIds'] ?? []);
    if (chatData['createdBy'] != currentUserId &&
        !adminIds.contains(currentUserId)) {
      throw Exception('Only creator or admins can delete');
    }
    final msgs = await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .get();
    final batch = _firestore.batch();
    for (final m in msgs.docs) batch.delete(m.reference);
    batch.delete(_firestore.collection('chats').doc(chatId));
    await batch.commit();
  }

  Future<void> leaveGroup(String chatId) async {
    final userData = await getCurrentUserData();
    if (userData == null) return;
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data()!;
    final parts = List<String>.from(chatData['participants']);
    final names = List<String>.from(chatData['participantNames']);
    final roles = List<String>.from(chatData['participantRoles']);
    final avatars = List<String>.from(chatData['participantAvatars']);
    final idx = parts.indexOf(currentUserId);
    if (idx == -1) return;
    parts.removeAt(idx);
    names.removeAt(idx);
    roles.removeAt(idx);
    avatars.removeAt(idx);
    await _firestore.collection('chats').doc(chatId).update({
      'participants': parts,
      'participantNames': names,
      'participantRoles': roles,
      'participantAvatars': avatars,
    });
    await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .add({
      'type': 'system',
      'text': '${userData['name']} left the group',
      'senderId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': parts,
    });
  }

  bool isGroupAdmin(Map<String, dynamic> chatData) =>
      List<String>.from(chatData['adminIds'] ?? []).contains(currentUserId);

  // ═══════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════

  Stream<List<Map<String, dynamic>>> getChatMessages(String chatId) {
    return _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => {'messageId': d.id, ...d.data()}).toList());
  }

  Future<void> sendTextMessage(String chatId, String text) =>
      _sendMessage(chatId, {'type': 'text', 'text': text});

  Future<void> sendEmojiMessage(String chatId, String emoji) =>
      _sendMessage(chatId, {'type': 'emoji', 'text': emoji});

  Future<void> sendVoiceMessage(
      String chatId, File audioFile, String duration) async {
    if (currentUserId.isEmpty) throw Exception('Not authenticated');
    final fileName = 'vm_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = _storage.ref('voice_messages/$chatId/$fileName');
    final task = await ref.putFile(
        audioFile, SettableMetadata(contentType: 'audio/m4a'));
    final url = await task.ref.getDownloadURL();
    try {
      await audioFile.delete();
    } catch (_) {}
    await _sendMessage(chatId, {
      'type': 'audio',
      'audioUrl': url,
      'audioDuration': duration,
      'text': '🎙️ Voice message',
    });
  }

  /// Web-only: upload a dart:html Blob (audio/webm) to Firebase Storage
  Future<void> sendVoiceMessageWeb(
      String chatId, dynamic blob, String duration) async {
    if (currentUserId.isEmpty) throw Exception('Not authenticated');
    final fileName = 'vm_${DateTime.now().millisecondsSinceEpoch}.webm';
    final ref = _storage.ref('voice_messages/$chatId/$fileName');
    // blob is html.Blob — putBlob is available in firebase_storage web
    final task =
        await ref.putBlob(blob, SettableMetadata(contentType: 'audio/webm'));
    final url = await task.ref.getDownloadURL();
    await _sendMessage(chatId, {
      'type': 'audio',
      'audioUrl': url,
      'audioDuration': duration,
      'text': '🎙️ Voice message',
    });
  }

  Future<void> _sendMessage(String chatId, Map<String, dynamic> data) async {
    final userData = await getCurrentUserData();
    final senderName = userData?['name'] as String? ?? '';
    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .doc();
    batch.set(msgRef, {
      ...data,
      'senderId': currentUserId,
      'senderName': senderName,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [currentUserId],
    });

    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();
    final chatData = chatDoc.data();
    if (chatData != null) {
      final isGroup = chatData['isGroup'] as bool? ?? false;
      final parts = List<String>.from(chatData['participants'] ?? []);
      final unread = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});
      for (final p in parts) {
        if (p != currentUserId) unread[p] = (unread[p] ?? 0) + 1;
      }
      batch.update(chatRef, {
        'lastMessage':
            isGroup ? '$senderName: ${data['text'] ?? ''}' : data['text'] ?? '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': unread,
      });
    }
    await batch.commit();
  }

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      final chatData = chatDoc.data();
      if (chatData == null) return;
      final unread = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});
      unread[currentUserId] = 0;
      await chatRef.update({'unreadCount': unread});

      final msgs = await _firestore
          .collection('messages')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .get();
      final batch = _firestore.batch();
      for (final doc in msgs.docs) {
        final readBy = List<String>.from(doc.data()['readBy'] ?? []);
        if (!readBy.contains(currentUserId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([currentUserId])
          });
        }
      }
      await batch.commit();
    } catch (e) {
      print('markMessagesAsRead error: $e');
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) => _firestore
      .collection('messages')
      .doc(chatId)
      .collection('messages')
      .doc(messageId)
      .delete();

  Future<void> clearChat(String chatId) async {
    final msgs = await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .get();
    final batch = _firestore.batch();
    for (final m in msgs.docs) batch.delete(m.reference);
    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════
  // UNREAD
  // ═══════════════════════════════════════════════════════

  Stream<int> getTotalUnreadCount() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final unread = doc.data()['unreadCount'] as Map<String, dynamic>?;
        total += (unread?[currentUserId] as int?) ?? 0;
      }
      return total;
    });
  }

  int getUnreadCountForChat(Map<String, dynamic> chatData) {
    final unread = chatData['unreadCount'] as Map<String, dynamic>?;
    return (unread?[currentUserId] as int?) ?? 0;
  }

  // ═══════════════════════════════════════════════════════
  // UTILITY
  // ═══════════════════════════════════════════════════════

  String formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun'
      ][date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<bool> canChatWith(String otherUserId) async {
    final userData = await getCurrentUserData();
    final otherDoc =
        await _firestore.collection('users').doc(otherUserId).get();
    if (userData == null || !otherDoc.exists) return false;
    final role = userData['role'] as String? ?? '';
    final otherRole = otherDoc.data()!['role'] as String? ?? '';
    switch (role) {
      case 'staff':
        return otherRole == 'staff' || otherRole == 'manager';
      case 'manager':
        return true;
      case 'admin':
        return true;
      case 'client':
        final ids = await getClientAssignedManagerIds();
        return ids.contains(otherUserId);
      default:
        return false;
    }
  }
}
