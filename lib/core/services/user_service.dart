import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final _cache = <String, Map<String, dynamic>>{};

  static Future<Map<String, dynamic>> getUser(String uid) async {
    if (_cache.containsKey(uid)) {
      return _cache[uid]!;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data() ?? {};
    _cache[uid] = data;
    return data;
  }
}
