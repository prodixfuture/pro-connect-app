import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManagementHub extends StatelessWidget {
  const AdminManagementHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Management Hub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff6366f1),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Manage Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff1a1a1a),
            ),
          ),
          const SizedBox(height: 16),

          // Tickets Card with count
          _buildManagementCard(
            context,
            title: 'Tickets',
            subtitle: 'Manage technical issues',
            icon: Icons.confirmation_number_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFFF9800)],
            ),
            route: '/admin/manage/tickets',
            countStream: _getTicketCount(),
          ),
          const SizedBox(height: 12),

          // Expense Requests Card with count
          _buildManagementCard(
            context,
            title: 'Expense Requests',
            subtitle: 'Approve or reject expenses',
            icon: Icons.receipt_long_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFEF5350), Color(0xFFE53935)],
            ),
            route: '/admin/manage/expense-requests',
            countStream: _getExpenseCount(),
          ),
          const SizedBox(height: 12),

          // Trial Leads Card with count
          _buildManagementCard(
            context,
            title: 'Trial Leads',
            subtitle: 'Review staff submissions',
            icon: Icons.person_add_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
            ),
            route: '/admin/manage/trial-leads',
            countStream: _getTrialLeadsCount(),
          ),

          const SizedBox(height: 32),
          const Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff1a1a1a),
            ),
          ),
          const SizedBox(height: 25),

          _buildStatsGrid(),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required String route,
    required Stream<int> countStream,
  }) {
    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, route),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff1a1a1a),
                                ),
                              ),
                              if (count > 0) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    count.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Open Tickets',
          _getTicketCount(),
          Icons.confirmation_number,
          const Color(0xFFFFA726),
        ),
        _buildStatCard(
          'Pending Expenses',
          _getExpenseCount(),
          Icons.receipt_long,
          const Color(0xFFEF5350),
        ),
        _buildStatCard(
          'Trial Leads',
          _getTrialLeadsCount(),
          Icons.person_add,
          const Color(0xFF66BB6A),
        ),
        _buildStatCard(
          'Total Pending',
          _getTotalPendingCount(),
          Icons.pending_actions,
          const Color(0xFF5C6BC0),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    Stream<int> countStream,
    IconData icon,
    Color color,
  ) {
    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<int> _getTicketCount() {
    return FirebaseFirestore.instance
        .collection('tickets')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getExpenseCount() {
    return FirebaseFirestore.instance
        .collection('expense_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getTrialLeadsCount() {
    return FirebaseFirestore.instance
        .collection('trial_leads')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getTotalPendingCount() {
    return FirebaseFirestore.instance
        .collection('tickets')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .asyncMap((ticketsSnapshot) async {
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('expense_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      final leadsSnapshot = await FirebaseFirestore.instance
          .collection('trial_leads')
          .where('status', isEqualTo: 'pending')
          .get();

      return ticketsSnapshot.docs.length +
          expensesSnapshot.docs.length +
          leadsSnapshot.docs.length;
    });
  }
}
