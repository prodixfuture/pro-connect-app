import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pro_connect/admin/dashboard_image_manager.dart';
import 'package:pro_connect/admin/manage/admin_management_hub.dart';
import 'create_user_screen.dart';
import 'user_list_screen.dart';
import 'office_location_settings_screen.dart';
import 'office_timing_settings_screen.dart';
import 'admin_badge_management.dart';
import '/screens/admin/admin_projects_screen.dart';
import 'attendance/admin_dashboard_screen.dart';
import 'attendance/admin_own_attendance_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _tile(
              context,
              icon: Icons.dashboard_rounded,
              title: 'Staff Dashboard',
              subtitle: 'Manage all staff attendance',
              color: const Color(0xFFFF9800),
              screen: const AdminDashboard(),
            ),
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.person_rounded,
              title: 'My Attendance',
              subtitle: 'View and mark your own attendance',
              color: const Color(0xFF9C27B0),
              screen: const AdminOwnAttendanceScreen(),
            ),
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.person_add,
              title: 'Create User',
              subtitle: 'Add new staff members',
              color: const Color(0xFF66BB6A),
              screen: const CreateUserScreen(),
            ),
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.people,
              title: 'View Users',
              subtitle: 'Manage all staff members',
              color: const Color(0xFF42A5F5),
              screen: const UserListScreen(),
            ),
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.star_rounded,
              title: 'Best Performer Badge',
              subtitle: 'Award badges to top sales performers',
              color: const Color(0xFFFFD700),
              screen: const AdminBadgeManagement(),
            ),
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.business_center_rounded,
              title: 'Projects',
              subtitle: 'Manage company projects and assignments',
              color: const Color(0xFF9C27B0),
              screen: const AdminProjectsScreen(),
            ),
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.photo_library,
              title: 'Image Slider',
              subtitle: 'Ads Image Slider',
              color: const Color(0xFF9C27B0),
              screen: const DashboardImageManager(),
            ),
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.hub,
              title: 'More Hub',
              subtitle: 'Staff More Request',
              color: const Color(0xFF9C27B0),
              screen: const AdminManagementHub(),
            ),
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.access_time,
              title: 'Office Timing Settings',
              subtitle: 'Set start, late, and end times',
              color: const Color(0xFFFFA726),
              screen: const OfficeTimingSettingsScreen(),
            ),
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.location_on,
              title: 'Office Location Settings',
              subtitle: 'Configure attendance geo-fencing (20m radius)',
              color: const Color(0xFFEF5350),
              screen: const OfficeLocationSettingsScreen(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF5350),
                  side: const BorderSide(color: Color(0xFFEF5350), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget screen,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
      ),
    );
  }
}
