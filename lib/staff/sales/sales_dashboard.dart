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
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive aspect ratio based on screen width
    final cardAspectRatio = screenWidth < 360 ? 1.1 : 1.25;

    return Scaffold(
      backgroundColor: const Color(0xfff1f5f9),
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
                SliverToBoxAdapter(
                  child: _buildProductivityHeader(uid, analytics),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _buildPeriodFilter(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: cardAspectRatio,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
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
                        '${(analytics['conversionRate'] as double).toStringAsFixed(1)}%',
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
                        '₹${_formatRevenue(analytics['commission'] as double)}',
                        Icons.currency_rupee,
                        const Color(0xff8b5cf6),
                        '10% of revenue',
                      ),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Status",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1a1a1a),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showTodayStatusFilter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xff6366f1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.filter_list_rounded,
                                    color: Color(0xff6366f1), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _getTodayFilterLabel(),
                                  style: const TextStyle(
                                    color: Color(0xff6366f1),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _buildTodayStatus(analytics),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1a1a1a),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/leads'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xff6366f1),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('View All →'),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildRecentActivity(docs, today),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1a1a1a),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getTodayFilterLabel() {
    switch (_todayStatusFilter) {
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'year':
        return 'This Year';
      case 'custom':
        return 'Custom';
      default:
        return 'Today';
    }
  }

  Widget _buildProductivityHeader(String uid, Map<String, dynamic> analytics) {
    final conversionRate = (analytics['conversionRate'] as double?) ?? 0.0;
    final totalLeads = (analytics['total'] as int?) ?? 0;
    final converted = (analytics['converted'] as int?) ?? 0;

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
        final userName = userData?['name'] ?? 'Staff Name';
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
          default:
            badgeColor = const Color(0xffFFD700);
            badgeIcon = Icons.star_rounded;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff6366f1), Color(0xff8b5cf6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff6366f1).withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd - MM - yyyy').format(DateTime.now()),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'GOOD MORNING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Right side: Bell + Badge stacked vertically
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('userId', isEqualTo: uid)
                            .snapshots(),
                        builder: (context, notifSnapshot) {
                          int unreadCount = 0;
                          if (notifSnapshot.hasData) {
                            unreadCount = notifSnapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return !(data['isRead'] ?? false);
                            }).length;
                          }
                          return InkWell(
                            onTap: () =>
                                Navigator.pushNamed(context, '/notifications'),
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
                                    size: 22,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffef4444),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 1.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (hasBadge && badgeTitle.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 120),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  badgeTitle.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    'Productivity Score',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    '${productivityScore.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: productivityScore / 100,
                  minHeight: 7,
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Filter Status By',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      groupValue: _todayStatusFilter,
      activeColor: const Color(0xff6366f1),
      dense: true,
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

  // ✅ KEY FIX: Using Spacer() between icon and text to distribute space
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Color(0xff6b7280)),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatus(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          _buildStatusRow(
              'New', analytics['todayNew'] as int, const Color(0xff3b82f6)),
          const Divider(height: 1),
          _buildStatusRow('Contacted', analytics['todayContacted'] as int,
              const Color(0xff8b5cf6)),
          const Divider(height: 1),
          _buildStatusRow('In Progress', analytics['todayInProgress'] as int,
              const Color(0xfff59e0b)),
          const Divider(height: 1),
          _buildStatusRow('Converted', analytics['todayConverted'] as int,
              const Color(0xff10b981)),
          const Divider(height: 1),
          _buildStatusRow(
              'Lost', analytics['todayLost'] as int, const Color(0xffef4444)),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xff374151),
                      fontWeight: FontWeight.w500)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(count.toString(),
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(
      List<QueryDocumentSnapshot> docs, DateTime today) {
    final recentLeads = docs.take(3).toList();

    if (recentLeads.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 44, color: Color(0xff9ca3af)),
                SizedBox(height: 10),
                Text('No recent activity',
                    style: TextStyle(color: Color(0xff6b7280), fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: recentLeads.map((doc) {
          final name = _getFieldValue(doc, 'name', 'Unknown');
          final status = _getFieldValue(doc, 'status', 'new');
          final priority = _getFieldValue(doc, 'priority', 'medium');

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                          color: _getPriorityColor(priority),
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xff1a1a1a)),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(_getStatusLabel(status),
                          style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 20),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
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
      } catch (e) {
        // skip
      }
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
