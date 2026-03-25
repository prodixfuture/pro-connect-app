import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String uid;
  final String date; // yyyy-MM-dd format
  final DateTime? punchIn;
  final DateTime? punchOut;
  final int duration; // in minutes
  final String status; // working, on_time, late, overtime

  AttendanceModel({
    required this.uid,
    required this.date,
    this.punchIn,
    this.punchOut,
    required this.duration,
    required this.status,
  });

  // Document ID format: uid_date (e.g., "user123_2026-02-03")
  String get documentId => '${uid}_$date';

  // Calculate status based on punch times with custom late cutoff
  static String calculateStatus({
    required DateTime punchIn,
    DateTime? punchOut,
    TimeOfDay? lateCutoff, // Custom late time from admin settings
  }) {
    final punchInTime = TimeOfDay.fromDateTime(punchIn);
    final cutoffTime =
        lateCutoff ?? const TimeOfDay(hour: 9, minute: 30); // Default 9:30 AM

    // Check if still working (no punch out yet)
    if (punchOut == null) {
      // Check if punched in late
      if (_isAfter(punchInTime, cutoffTime)) {
        return 'late';
      }
      return 'working';
    }

    // Already punched out - determine final status based on punch IN time only
    // Check late (punch in after cutoff time)
    if (_isAfter(punchInTime, cutoffTime)) {
      return 'late';
    }

    // On time (punched in before or at cutoff time)
    return 'on_time';
  }

  // Helper to compare TimeOfDay
  static bool _isAfter(TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour > time2.hour) return true;
    if (time1.hour < time2.hour) return false;
    return time1.minute > time2.minute;
  }

  // Calculate duration in minutes
  static int calculateDuration(DateTime punchIn, DateTime? punchOut) {
    if (punchOut == null) return 0;
    return punchOut.difference(punchIn).inMinutes;
  }

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'date': date,
      'punchIn': punchIn != null ? Timestamp.fromDate(punchIn!) : null,
      'punchOut': punchOut != null ? Timestamp.fromDate(punchOut!) : null,
      'duration': duration,
      'status': status,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore document
  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AttendanceModel(
      uid: data['uid'] ?? '',
      date: data['date'] ?? '',
      punchIn: data['punchIn'] != null
          ? (data['punchIn'] as Timestamp).toDate()
          : null,
      punchOut: data['punchOut'] != null
          ? (data['punchOut'] as Timestamp).toDate()
          : null,
      duration: data['duration'] ?? 0,
      status: data['status'] ?? 'working',
    );
  }

  // Copy with method for updates
  AttendanceModel copyWith({
    String? uid,
    String? date,
    DateTime? punchIn,
    DateTime? punchOut,
    int? duration,
    String? status,
  }) {
    return AttendanceModel(
      uid: uid ?? this.uid,
      date: date ?? this.date,
      punchIn: punchIn ?? this.punchIn,
      punchOut: punchOut ?? this.punchOut,
      duration: duration ?? this.duration,
      status: status ?? this.status,
    );
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dt) {
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }
}
