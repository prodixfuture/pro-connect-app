import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pro_connect/client/client_home.dart';

// Screens
import 'presentation/login_screen.dart';
import '../staff/staff_home.dart';
import '../manager/manager_home.dart';
import '../admin/admin_home.dart';
import '/client/dashboard/client_dashboard.dart';

// ✅ Client Portal

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // 🔄 Auth loading
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }

        // ❌ Not logged in
        if (!authSnap.hasData) {
          return const LoginScreen();
        }

        // ✅ Logged in
        final user = authSnap.data!;
        return _UserResolver(user: user);
      },
    );
  }
}

/// ------------------------------------------------------------
/// USER RESOLVER
/// ------------------------------------------------------------
class _UserResolver extends StatelessWidget {
  final User user;
  const _UserResolver({required this.user});

  Future<Map<String, dynamic>> _getOrCreateUser() async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();

    // 🔥 First login → create profile
    if (!doc.exists) {
      final data = {
        'name': user.email?.split('@').first ?? 'User',
        'email': user.email,

        // SAFE DEFAULT
        'role': 'staff',
        'department': 'sales',

        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);
      return data;
    }

    return doc.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getOrCreateUser(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }

        if (!snap.hasData) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Failed to load user profile',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final data = snap.data!;

        final String role = data['role'] ?? 'staff';
        final String department = data['department'] ?? 'sales';

        // 🔀 ROLE + DEPARTMENT BASED ROUTING
        switch (role) {
          case 'admin':
            return const AdminHome();

          case 'manager':
            return const ManagerHome();

          case 'staff':

            // SALES STAFF → Sales Dashboard
            if (department == 'sales') {
              return const StaffHome(department: 'sales');
            }

            // DESIGN STAFF → Designer Dashboard
            if (department == 'design') {
              return const StaffHome(department: 'design');
            }

            // ACCOUNTS STAFF → Accounts Dashboard
            if (department == 'accounts') {
              return const StaffHome(department: 'accounts');
            }

            // OTHER STAFF → Normal Staff Dashboard
            return StaffHome(department: department);

          // ✅ CLIENT → Full Client Portal with bottom navigation
          case 'client':
            return const ClientHome();

          default:
            return const Scaffold(
              body: Center(
                child: Text(
                  'Invalid role',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
        }
      },
    );
  }
}

/// ------------------------------------------------------------
/// COMMON LOADING SCREEN
/// ------------------------------------------------------------
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
