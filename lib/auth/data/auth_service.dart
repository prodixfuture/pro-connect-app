import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // LOGIN
  Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // REGISTER (Admin will mostly use this later)
  Future<User?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String department,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('users').doc(result.user!.uid).set({
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return result.user;
  }

  // GET USER PROFILE
  Future<DocumentSnapshot> getUserProfile(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
