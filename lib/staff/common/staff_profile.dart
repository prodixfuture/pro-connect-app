import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffProfile extends StatelessWidget {
  const StaffProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildEmptyState();
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildProfileContent(context, data);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Profile not found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown User';
    final email = data['email'] ?? '';
    final role = data['role'] ?? '';
    final department = data['department'] ?? '';
    final status = data['status'] ?? '';
    final phone = data['phone'] ?? '';
    final employeeId = data['employeeId'] ?? '';

    // Badge and Achievement System
    final badges = data['badges'] as List<dynamic>? ?? _getTrialBadges();
    final achievements =
        data['achievements'] as List<dynamic>? ?? _getTrialAchievements();

    return CustomScrollView(
      slivers: [
        // Modern App Bar
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildProfileHeader(
              name,
              email,
              role,
              department,
              status,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _showLogoutDialog(context),
              tooltip: 'Logout',
            ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information
                _buildSectionTitle(
                    'Personal Information', Icons.person_rounded),
                const SizedBox(height: 12),
                _buildInfoCard([
                  _InfoItem(
                    icon: Icons.badge_rounded,
                    label: 'Employee ID',
                    value: employeeId.isNotEmpty ? employeeId : 'Not assigned',
                    color: const Color(0xFF6366F1),
                  ),
                  _InfoItem(
                    icon: Icons.phone_rounded,
                    label: 'Phone Number',
                    value: phone.isNotEmpty ? phone : 'Not provided',
                    color: const Color(0xFFEC4899),
                  ),
                ]),

                const SizedBox(height: 24),

                // Work Details
                _buildSectionTitle('Work Details', Icons.work_rounded),
                const SizedBox(height: 12),
                _buildInfoCard([
                  _InfoItem(
                    icon: Icons.work_outline_rounded,
                    label: 'Role',
                    value: role.isNotEmpty ? role : 'N/A',
                    color: const Color(0xFF8B5CF6),
                  ),
                  _InfoItem(
                    icon: Icons.business_rounded,
                    label: 'Department',
                    value: department.isNotEmpty ? department : 'N/A',
                    color: const Color(0xFF06B6D4),
                  ),
                  _InfoItem(
                    icon: Icons.verified_user_rounded,
                    label: 'Status',
                    value: status.isNotEmpty
                        ? status[0].toUpperCase() + status.substring(1)
                        : 'N/A',
                    color: status == 'active'
                        ? const Color(0xFF10B981)
                        : const Color(0xFF6B7280),
                  ),
                ]),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    String name,
    String email,
    String role,
    String department,
    String status,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
            const Color(0xFFA855F7),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Avatar with Glow Effect
            Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFF3F4F6)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ).createShader(
                              const Rect.fromLTWH(0, 0, 200, 70),
                            ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (status.isNotEmpty)
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: status == 'active'
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6B7280),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: (status == 'active'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF6B7280))
                                .withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Email
            Text(
              email,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Tags
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (role.isNotEmpty)
                  _buildModernTag(role, Icons.work_outline_rounded),
                if (role.isNotEmpty && department.isNotEmpty)
                  const SizedBox(width: 10),
                if (department.isNotEmpty)
                  _buildModernTag(department, Icons.business_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            item.color.withOpacity(0.15),
                            item.color.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey[100],
                  indent: 82,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
                color: Colors.grey[600],
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
                Navigator.of(context).popUntil((r) => r.isFirst);
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

  // Trial Data - Sample badges and achievements
  static List<Map<String, dynamic>> _getTrialBadges() {
    return [
      {
        'title': 'Top Performer',
        'description': 'Excellence in Q1',
        'icon': 'star',
        'color': 'amber',
      },
      {
        'title': 'Team Player',
        'description': 'Great collaboration',
        'icon': 'crown',
        'color': 'purple',
      },
      {
        'title': 'On Time',
        'description': '100% Attendance',
        'icon': 'fire',
        'color': 'red',
      },
      {
        'title': 'Innovator',
        'description': 'Creative solutions',
        'icon': 'rocket',
        'color': 'blue',
      },
    ];
  }

  static List<Map<String, dynamic>> _getTrialAchievements() {
    return [
      {
        'title': 'Project Champion',
        'description': 'Successfully led 5 major projects',
        'date': 'Jan 15, 2024',
        'icon': 'trophy',
        'color': 'amber',
      },
      {
        'title': 'Perfect Attendance',
        'description': 'No absences for 6 months straight',
        'date': 'Dec 20, 2023',
        'icon': 'medal',
        'color': 'green',
      },
      {
        'title': 'Customer Delight',
        'description': 'Received 5-star rating from 10+ clients',
        'date': 'Nov 08, 2023',
        'icon': 'diamond',
        'color': 'pink',
      },
      {
        'title': 'Goal Crusher',
        'description': 'Exceeded quarterly targets by 150%',
        'date': 'Oct 30, 2023',
        'icon': 'target',
        'color': 'teal',
      },
    ];
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
