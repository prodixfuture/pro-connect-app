import 'package:cloud_firestore/cloud_firestore.dart';
import 'push_service.dart';

/// Helper class to trigger Firestore notifications for business events.
/// Call these methods from the relevant screens (Leave, Tasks, Invoices, etc.)
class AutoNotifications {
  AutoNotifications._();

  /// Notify staff that their leave has been approved
  static Future<void> leaveApproved({
    required String staffUid,
    required String leaveType,
    required String dateRange,
  }) async {
    await PushService.createNotification(
      uid: staffUid,
      title: 'Leave Approved ✅',
      body: 'Your $leaveType leave for $dateRange has been approved.',
      type: 'leave',
    );
  }

  /// Notify staff that their leave has been rejected
  static Future<void> leaveRejected({
    required String staffUid,
    required String leaveType,
    String? reason,
  }) async {
    await PushService.createNotification(
      uid: staffUid,
      title: 'Leave Rejected ❌',
      body: reason != null
          ? 'Your $leaveType leave was rejected. Reason: $reason'
          : 'Your $leaveType leave request was rejected.',
      type: 'leave',
    );
  }

  /// Notify staff/user that a task has been assigned to them
  static Future<void> taskAssigned({
    required String assigneeUid,
    required String taskTitle,
    String? dueDate,
  }) async {
    await PushService.createNotification(
      uid: assigneeUid,
      title: 'New Task Assigned 📋',
      body: dueDate != null
          ? 'You have been assigned: "$taskTitle". Due: $dueDate'
          : 'You have been assigned a new task: "$taskTitle".',
      type: 'task',
    );
  }

  /// Notify user that an invoice has been created for them
  static Future<void> invoiceCreated({
    required String clientUid,
    required String invoiceNumber,
    required String amount,
  }) async {
    await PushService.createNotification(
      uid: clientUid,
      title: 'New Invoice Created 🧾',
      body: 'Invoice #$invoiceNumber for $amount has been created.',
      type: 'invoice',
    );
  }

  /// Notify admin/manager that a payment has been received
  static Future<void> paymentReceived({
    required String adminUid,
    required String clientName,
    required String amount,
    String? invoiceNumber,
  }) async {
    await PushService.createNotification(
      uid: adminUid,
      title: 'Payment Received 💰',
      body: invoiceNumber != null
          ? 'Payment of $amount from $clientName for Invoice #$invoiceNumber received.'
          : 'Payment of $amount from $clientName has been received.',
      type: 'payment',
    );
  }

  /// Notify staff that a manager has sent them a message
  static Future<void> managerMessage({
    required String staffUid,
    required String managerName,
    required String preview,
  }) async {
    await PushService.createNotification(
      uid: staffUid,
      title: 'Message from $managerName 💬',
      body: preview,
      type: 'message',
    );
  }

  /// Send a system-wide announcement to a list of uids
  static Future<void> systemAnnouncement({
    required List<String> uids,
    required String title,
    required String body,
  }) async {
    final futures = uids.map(
      (uid) => PushService.createNotification(
        uid: uid,
        title: title,
        body: body,
        type: 'announcement',
      ),
    );
    await Future.wait(futures);
  }

  /// Check user's notification preferences before sending
  static Future<bool> _isEnabled(String uid, String settingKey) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('notification_settings')
          .doc(uid)
          .get();
      if (!doc.exists) return true; // Default: all enabled
      return doc.data()?[settingKey] ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Respects user notification settings
  static Future<void> taskAssignedRespectingSettings({
    required String assigneeUid,
    required String taskTitle,
    String? dueDate,
  }) async {
    final enabled = await _isEnabled(assigneeUid, 'taskUpdates');
    if (!enabled) return;
    await taskAssigned(
        assigneeUid: assigneeUid, taskTitle: taskTitle, dueDate: dueDate);
  }

  static Future<void> leaveApprovedRespectingSettings({
    required String staffUid,
    required String leaveType,
    required String dateRange,
  }) async {
    final enabled = await _isEnabled(staffUid, 'leaveUpdates');
    if (!enabled) return;
    await leaveApproved(
        staffUid: staffUid, leaveType: leaveType, dateRange: dateRange);
  }

  static Future<void> paymentReceivedRespectingSettings({
    required String adminUid,
    required String clientName,
    required String amount,
    String? invoiceNumber,
  }) async {
    final enabled = await _isEnabled(adminUid, 'payments');
    if (!enabled) return;
    await paymentReceived(
      adminUid: adminUid,
      clientName: clientName,
      amount: amount,
      invoiceNumber: invoiceNumber,
    );
  }

  static Future<void> managerMessageRespectingSettings({
    required String staffUid,
    required String managerName,
    required String preview,
  }) async {
    final enabled = await _isEnabled(staffUid, 'messages');
    if (!enabled) return;
    await managerMessage(
        staffUid: staffUid, managerName: managerName, preview: preview);
  }
}
