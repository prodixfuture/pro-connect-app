import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StaffMoreScreen extends StatelessWidget {
  const StaffMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.black12,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'More',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: const Color(0xFFE8EDF5)),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActionCard(
                  context,
                  title: 'Raise A Ticket',
                  subtitle: 'Report issues & bugs',
                  icon: Icons.confirmation_number_rounded,
                  accent: const Color(0xFF7C3AED),
                  accentSoft: const Color(0xFFEDE9FE),
                  onTap: () =>
                      Navigator.pushNamed(context, '/more/raise-ticket'),
                ),
                const SizedBox(height: 14),
                _buildActionCard(
                  context,
                  title: 'Raise An Expense',
                  subtitle: 'Submit for approval',
                  icon: Icons.receipt_long_rounded,
                  accent: const Color(0xFFDC2626),
                  accentSoft: const Color(0xFFFEE2E2),
                  onTap: () =>
                      Navigator.pushNamed(context, '/more/raise-expense'),
                ),
                const SizedBox(height: 14),
                _buildActionCard(
                  context,
                  title: 'Add Lead',
                  subtitle: 'Submit trial leads',
                  icon: Icons.person_add_rounded,
                  accent: const Color(0xFF059669),
                  accentSoft: const Color(0xFFD1FAE5),
                  onTap: () => Navigator.pushNamed(context, '/more/add-lead'),
                ),
                const SizedBox(height: 14),
                _buildActionCard(
                  context,
                  title: 'Leave Request',
                  subtitle: 'Apply for leave',
                  icon: Icons.event_available_rounded,
                  accent: const Color(0xFF2563EB),
                  accentSoft: const Color(0xFFDBEAFE),
                  onTap: () =>
                      Navigator.pushNamed(context, '/leave/leave-request'),
                ),
                const SizedBox(height: 14),
                _buildActionCard(
                  context,
                  title: 'My Requests',
                  subtitle: 'Track all your submissions',
                  icon: Icons.inbox_rounded,
                  accent: const Color(0xFFD97706),
                  accentSoft: const Color(0xFFFEF3C7),
                  onTap: () =>
                      Navigator.pushNamed(context, '/more/staff-request'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Color accentSoft,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: accent.withOpacity(0.06),
        highlightColor: accent.withOpacity(0.04),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEEF2F8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    color: accent, size: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
