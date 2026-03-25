import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String VALID_QR_CODE = 'PRODIX_QR_ATTENDANCE';
  static const double LOCATION_RADIUS_METERS = 5.0; // Changed to 5 meters

  String? get currentUserId => _auth.currentUser?.uid;

  bool isValidQRCode(String scannedValue) {
    return scannedValue.trim() == VALID_QR_CODE;
  }

  String getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  DocumentReference _getTodayAttendanceDoc() {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final date = getTodayDate();
    final docId = '${uid}_$date';

    return _firestore.collection('attendance').doc(docId);
  }

  // Get staff's individual work timing
  Future<Map<String, TimeOfDay>> getStaffWorkTiming(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        return _getDefaultTiming();
      }

      final userData = userDoc.data()!;

      // Check if staff has individual timing
      if (userData['startTime'] != null && userData['endTime'] != null) {
        return {
          'startTime': _parseTimeOfDay(userData['startTime']),
          'lateTime':
              _calculateLateTime(_parseTimeOfDay(userData['startTime'])),
          'endTime': _parseTimeOfDay(userData['endTime']),
        };
      }

      // Fall back to office timing
      return await getOfficeTiming();
    } catch (e) {
      print('Error getting staff timing: $e');
      return _getDefaultTiming();
    }
  }

  // Get office-wide timing (fallback)
  Future<Map<String, TimeOfDay>> getOfficeTiming() async {
    try {
      final doc =
          await _firestore.collection('settings').doc('office_timing').get();

      if (!doc.exists || doc.data() == null) {
        return _getDefaultTiming();
      }

      final data = doc.data()!;

      return {
        'startTime': _parseTimeOfDay(data['startTime'] ?? '09:00'),
        'lateTime': _parseTimeOfDay(data['lateTime'] ?? '09:30'),
        'endTime': _parseTimeOfDay(data['endTime'] ?? '18:00'),
      };
    } catch (e) {
      print('Error getting office timing: $e');
      return _getDefaultTiming();
    }
  }

  Map<String, TimeOfDay> _getDefaultTiming() {
    return {
      'startTime': const TimeOfDay(hour: 9, minute: 0),
      'lateTime': const TimeOfDay(hour: 9, minute: 30),
      'endTime': const TimeOfDay(hour: 18, minute: 0),
    };
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // Calculate late time as 15 minutes after start time
  TimeOfDay _calculateLateTime(TimeOfDay startTime) {
    int totalMinutes = startTime.hour * 60 + startTime.minute + 15;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Location services are disabled. Please enable location.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return true;
  }

  Future<Position> getCurrentLocation() async {
    await checkLocationPermission();
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<Map<String, double>?> getOfficeLocation() async {
    try {
      final doc =
          await _firestore.collection('settings').doc('office_location').get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null ||
          !data.containsKey('latitude') ||
          !data.containsKey('longitude')) {
        return null;
      }

      return {
        'latitude': data['latitude'] as double,
        'longitude': data['longitude'] as double,
      };
    } catch (e) {
      print('Error getting office location: $e');
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<bool> verifyLocationWithinOffice() async {
    try {
      final currentPosition = await getCurrentLocation();
      final officeLocation = await getOfficeLocation();

      if (officeLocation == null) {
        throw Exception(
            'Office location not configured. Please contact admin.');
      }

      final distance = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        officeLocation['latitude']!,
        officeLocation['longitude']!,
      );

      print(
          '📍 Distance: ${distance.toStringAsFixed(1)} meters (limit: ${LOCATION_RADIUS_METERS}m)');

      if (distance <= LOCATION_RADIUS_METERS) {
        print('✅ Within office radius');
        return true;
      } else {
        print('❌ Outside office radius');
        return false;
      }
    } catch (e) {
      print('❌ Location verification failed: $e');
      rethrow;
    }
  }

  Future<bool> punchIn() async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final date = getTodayDate();

      final existing = await getTodayAttendance();
      if (existing != null && existing.punchIn != null) {
        throw Exception('Already punched in today');
      }

      // Get staff's individual timing
      final timing = await getStaffWorkTiming(uid);
      final lateTime = timing['lateTime']!;

      final status = AttendanceModel.calculateStatus(
        punchIn: now,
        punchOut: null,
        lateCutoff: lateTime,
      );

      final attendance = AttendanceModel(
        uid: uid,
        date: date,
        punchIn: now,
        punchOut: null,
        duration: 0,
        status: status,
      );

      await _getTodayAttendanceDoc().set(
        attendance.toFirestore(),
        SetOptions(merge: true),
      );

      print('✅ Punch In successful');
      return true;
    } catch (e) {
      print('❌ Punch In failed: $e');
      rethrow;
    }
  }

  Future<bool> punchOut() async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      final existing = await getTodayAttendance();
      if (existing == null || existing.punchIn == null) {
        throw Exception('Must punch in first');
      }

      if (existing.punchOut != null) {
        throw Exception('Already punched out today');
      }

      final now = DateTime.now();

      // Get staff's individual timing
      final timing = await getStaffWorkTiming(uid);
      final lateTime = timing['lateTime']!;

      final duration =
          AttendanceModel.calculateDuration(existing.punchIn!, now);
      final status = AttendanceModel.calculateStatus(
        punchIn: existing.punchIn!,
        punchOut: now,
        lateCutoff: lateTime,
      );

      await _getTodayAttendanceDoc().update({
        'punchOut': Timestamp.fromDate(now),
        'duration': duration,
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ Punch Out successful');
      return true;
    } catch (e) {
      print('❌ Punch Out failed: $e');
      rethrow;
    }
  }

  Future<AttendanceModel?> getTodayAttendance() async {
    try {
      final doc = await _getTodayAttendanceDoc().get();
      if (!doc.exists) return null;
      return AttendanceModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting today attendance: $e');
      return null;
    }
  }

  Stream<AttendanceModel?> watchTodayAttendance() {
    return _getTodayAttendanceDoc().snapshots().map((doc) {
      if (!doc.exists) return null;
      return AttendanceModel.fromFirestore(doc);
    });
  }

  Stream<List<AttendanceModel>> getAttendanceHistory({int days = 90}) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    final startDate = DateTime.now().subtract(Duration(days: days));
    final startDateStr =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

    return _firestore
        .collection('attendance')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: startDateStr)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromFirestore(doc))
            .toList());
  }

  String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }
}
