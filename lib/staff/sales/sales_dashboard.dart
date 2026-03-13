import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SalesDashboard extends StatefulWidget {
  const SalesDashboard({super.key});

  @override
  State<SalesDashboard> createState() => _SalesDashboardState();
}

class _SalesDashboardState extends State<SalesDashboard> {
  String _selectedPeriod = 'month';
  String _todayStatusFilter = 'today';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  T _getFieldValue<T>(QueryDocumentSnapshot doc, String field, T defaultValue) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey(field)) return defaultValue;
      return data[field] as T;
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leads')
            .where('assignedTo', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final analytics = _calculateAnalytics(docs, today);

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                // Enhanced Header with Productivity Score
                SliverToBoxAdapter(
                  child: _buildProductivityHeader(uid, analytics),
                ),

                // Period Filter
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: _buildPeriodFilter(),
                  ),
                ),

                // Stats Cards
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildStatCard(
                        'Total Leads',
                        '${analytics['total']}',
                        Icons.people_outline_rounded,
                        const Color(0xff6366f1),
                        '+${analytics['newLeads']} new',
                      ),
                      _buildStatCard(
                        'Converted',
                        '${analytics['converted']}',
                        Icons.check_circle_outline_rounded,
                        const Color(0xff10b981),
                        '${analytics['conversionRate'].toStringAsFixed(1)}%',
                      ),
                      _buildStatCard(
                        'In Progress',
                        '${analytics['inProgress']}',
                        Icons.pending_outlined,
                        const Color(0xfff59e0b),
                        'Active',
                      ),
                      _buildStatCard(
                        'Commission',
                        '₹${_formatRevenue(analytics['commission'])}',
                        Icons.currency_rupee,
                        const Color(0xff8b5cf6),
                        '10% of revenue',
                      ),
                    ]),
                  ),
                ),

                // Today's Status
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today\'s Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1a1a1a),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_list_rounded),
                          color: const Color(0xff6366f1),
                          onPressed: _showTodayStatusFilter,
                          tooltip: 'Filter Status',
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _buildTodayStatus(analytics),
                  ),
                ),

                // Recent Activity
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1a1a1a),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/leads'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildRecentActivity(docs, today),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1a1a1a),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                'Add Lead',
                                Icons.add_rounded,
                                const Color(0xff6366f1),
                                () => Navigator.pushNamed(
                                    context, '/sales/add-lead'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                'All Leads',
                                Icons.list_alt_rounded,
                                const Color(0xff10b981),
                                () => Navigator.pushNamed(context, '/leads'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductivityHeader(String uid, Map<String, dynamic> analytics) {
    final conversionRate = analytics['conversionRate'] ?? 0.0;
    final totalLeads = analytics['total'] ?? 0;
    final converted = analytics['converted'] ?? 0;

    final conversionScore = (conversionRate / 100) * 40;
    final volumeScore = (totalLeads / 50).clamp(0.0, 1.0) * 30;
    final activityScore = (converted / 10).clamp(0.0, 1.0) * 30;

    final productivityScore =
        (conversionScore + volumeScore + activityScore).clamp(0.0, 100.0);

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'STAFF NAME';
        final hasBadge = userData?['hasPremiumBadge'] ?? false;
        final badgeTitle = userData?['badgeTitle'] ?? 'Game Changer';
        final badgeType = userData?['badgeType'] ?? 'sales_rep';

        Color badgeColor;
        IconData badgeIcon;
        switch (badgeType) {
          case 'sales_rep':
          case 'sales':
            badgeColor = const Color(0xffFFD700);
            badgeIcon = Icons.trending_up_rounded;
            break;
          case 'designer':
          case 'design':
            badgeColor = const Color(0xff9C27B0);
            badgeIcon = Icons.palette_rounded;
            break;
          case 'staff':
            badgeColor = const Color(0xff4CAF50);
            badgeIcon = Icons.stars_rounded;
            break;
          case 'manager':
          case 'admin':
            badgeColor = const Color(0xff2196F3);
            badgeIcon = Icons.lightbulb_rounded;
            break;
          case 'client':
          case 'customer':
            badgeColor = const Color(0xffFF5722);
            badgeIcon = Icons.workspace_premium_rounded;
            break;
          default:
            badgeColor = const Color(0xffFFD700);
            badgeIcon = Icons.star_rounded;
        }

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff6366f1), Color(0xff8b5cf6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff6366f1).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd - MM - yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'GOOD MORNING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Notification icon with badge
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('userId', isEqualTo: uid)
                            .snapshots(),
                        builder: (context, notifSnapshot) {
                          // Count unread notifications
                          int unreadCount = 0;
                          if (notifSnapshot.hasData) {
                            unreadCount = notifSnapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return !(data['isRead'] ?? false);
                            }).length;
                          }

                          return InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/notifications');
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffef4444),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Badge
                      if (hasBadge && badgeTitle.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                badgeIcon,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                badgeTitle.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Productivity Score',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${productivityScore.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: productivityScore / 100,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterButton('Month', 'month'),
          _buildFilterButton('Year', 'year'),
          _buildFilterButton('Custom', 'custom'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (value == 'custom') {
            _showCustomDatePicker();
          } else {
            setState(() => _selectedPeriod = value);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xff6366f1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xff6b7280),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  Future<void> _showTodayStatusFilter() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Status By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Today', 'today'),
            _buildFilterOption('Yesterday', 'yesterday'),
            _buildFilterOption('This Week', 'week'),
            _buildFilterOption('This Month', 'month'),
            _buildFilterOption('This Year', 'year'),
            _buildFilterOption('Custom Range', 'custom'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String label, String value) {
    final isSelected = _todayStatusFilter == value;
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _todayStatusFilter,
      activeColor: const Color(0xff6366f1),
      selected: isSelected,
      onChanged: (val) async {
        if (val == 'custom') {
          Navigator.pop(context);
          await _showCustomStatusDatePicker();
        } else {
          setState(() => _todayStatusFilter = val!);
          Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _showCustomStatusDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _todayStatusFilter = 'custom';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff6b7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatus(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatusRow(
              'New', analytics['todayNew'], const Color(0xff3b82f6)),
          const Divider(height: 24),
          _buildStatusRow('Contacted', analytics['todayContacted'],
              const Color(0xff8b5cf6)),
          const Divider(height: 24),
          _buildStatusRow('In Progress', analytics['todayInProgress'],
              const Color(0xfff59e0b)),
          const Divider(height: 24),
          _buildStatusRow('Converted', analytics['todayConverted'],
              const Color(0xff10b981)),
          const Divider(height: 24),
          _buildStatusRow(
              'Lost', analytics['todayLost'], const Color(0xffef4444)),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff374151),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(
      List<QueryDocumentSnapshot> docs, DateTime today) {
    final recentLeads = docs.take(3).toList();

    if (recentLeads.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Color(0xff9ca3af)),
                SizedBox(height: 12),
                Text(
                  'No recent activity',
                  style: TextStyle(color: Color(0xff6b7280)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: recentLeads.map((doc) {
          final name = _getFieldValue(doc, 'name', 'Unknown');
          final status = _getFieldValue(doc, 'status', 'new');
          final priority = _getFieldValue(doc, 'priority', 'medium');

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        color: _getPriorityColor(priority),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xff1a1a1a),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusLabel(status),
                        style: TextStyle(
                          fontSize: 13,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateAnalytics(
      List<QueryDocumentSnapshot> docs, DateTime today) {
    DateTime startDate;
    DateTime endDate = today;

    switch (_selectedPeriod) {
      case 'month':
        startDate = DateTime(today.year, today.month, 1);
        break;
      case 'year':
        startDate = DateTime(today.year, 1, 1);
        break;
      case 'custom':
        startDate = _customStartDate ?? DateTime(today.year, today.month, 1);
        endDate = _customEndDate ?? today;
        break;
      default:
        startDate = DateTime(today.year, today.month, 1);
    }

    final periodDocs = docs.where((doc) {
      try {
        final ts = _getFieldValue<Timestamp?>(doc, 'createdAt', null);
        if (ts == null) return false;
        final date = ts.toDate();
        return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();

    final total = periodDocs.length;
    final converted = periodDocs
        .where((e) => _getFieldValue(e, 'status', 'new') == 'converted')
        .length;
    final newLeads = periodDocs
        .where((e) => _getFieldValue(e, 'status', 'new') == 'new')
        .length;
    final inProgress = periodDocs
        .where((e) => _getFieldValue(e, 'status', 'new') == 'in_progress')
        .length;

    DateTime statusStartDate;
    DateTime statusEndDate = today;

    switch (_todayStatusFilter) {
      case 'today':
        statusStartDate = DateTime(today.year, today.month, today.day);
        statusEndDate = statusStartDate.add(const Duration(days: 1));
        break;
      case 'yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        statusStartDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day);
        statusEndDate = statusStartDate.add(const Duration(days: 1));
        break;
      case 'week':
        statusStartDate = today.subtract(const Duration(days: 7));
        break;
      case 'month':
        statusStartDate = DateTime(today.year, today.month, 1);
        break;
      case 'year':
        statusStartDate = DateTime(today.year, 1, 1);
        break;
      case 'custom':
        statusStartDate =
            _customStartDate ?? DateTime(today.year, today.month, today.day);
        statusEndDate = _customEndDate ?? today;
        break;
      default:
        statusStartDate = DateTime(today.year, today.month, today.day);
        statusEndDate = statusStartDate.add(const Duration(days: 1));
    }

    final todayDocs = docs.where((doc) {
      try {
        final ts = _getFieldValue<Timestamp?>(doc, 'createdAt', null);
        if (ts == null) return false;
        final date = ts.toDate();
        return date.isAfter(
                statusStartDate.subtract(const Duration(microseconds: 1))) &&
            date.isBefore(statusEndDate.add(const Duration(microseconds: 1)));
      } catch (e) {
        return false;
      }
    }).toList();

    final todayNew = todayDocs
        .where((e) => _getFieldValue(e, 'status', 'new') == 'new')
        .length;
    final todayContacted = todayDocs
        .where((e) => _getFieldValue(e, 'status', 'new') == 'contacted')
        .length;
    final todayInProgress = todayDocs
        .where((e) => _getFieldValue(e, 'status', 'new') == 'in_progress')
        .length;
    final todayConverted = todayDocs
        .where((e) => _getFieldValue(e, 'status', 'new') == 'converted')
        .length;
    final todayLost = todayDocs
        .where((e) => _getFieldValue(e, 'status', 'new') == 'lost')
        .length;

    double totalRevenue = 0;
    for (var doc in periodDocs) {
      try {
        if (_getFieldValue(doc, 'status', 'new') == 'converted') {
          final dealValue = _getFieldValue<num?>(doc, 'dealValue', null);
          if (dealValue != null) totalRevenue += dealValue.toDouble();
        }
      } catch (e) {}
    }

    final commission = totalRevenue * 0.1;
    final conversionRate = total == 0 ? 0.0 : (converted / total * 100);

    return {
      'total': total,
      'converted': converted,
      'newLeads': newLeads,
      'inProgress': inProgress,
      'conversionRate': conversionRate,
      'totalRevenue': totalRevenue,
      'commission': commission,
      'todayNew': todayNew,
      'todayContacted': todayContacted,
      'todayInProgress': todayInProgress,
      'todayConverted': todayConverted,
      'todayLost': todayLost,
    };
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xffef4444);
      case 'medium':
        return const Color(0xfff59e0b);
      case 'low':
        return const Color(0xff10b981);
      default:
        return const Color(0xff6b7280);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return const Color(0xff3b82f6);
      case 'contacted':
        return const Color(0xff8b5cf6);
      case 'in_progress':
        return const Color(0xfff59e0b);
      case 'converted':
        return const Color(0xff10b981);
      case 'lost':
        return const Color(0xffef4444);
      default:
        return const Color(0xff6b7280);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'new':
        return 'New Lead';
      case 'contacted':
        return 'Contacted';
      case 'in_progress':
        return 'In Progress';
      case 'converted':
        return 'Won';
      case 'lost':
        return 'Lost';
      default:
        return status;
    }
  }

  String _formatRevenue(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
